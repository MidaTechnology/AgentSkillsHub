//
//  TerminalView.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import SwiftUI
import MarkdownUI

struct TerminalView: View {
    @Environment(AppStore.self) private var appStore
    
    @State private var messages: [ConsoleMesage] = []
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    
    @State private var prompts: [String] = Constants.prompts
    @State private var isShowPrompts: Bool = false
    
    @State private var installedSkills: [AgentSkill] = []
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollViewReader { proxy in
                List {
                    Color.clear
                        .frame(minHeight: 16)
                        .id("TopmAnchor")
                        .listRowSeparator(.hidden)
                    ForEach(messages, id: \.self) { cm in
                        Markdown(cm.message)
                            .markdownTextStyle {
                                FontSize(12)
                                ForegroundColor(Color.primary)
                            }
                            .markdownTextStyle(\.link) {
                                FontSize(12)
                                ForegroundColor(Color.accent)
                            }
                            .markdownSoftBreakMode(.lineBreak)
                            .tint(Color.accent)
                            .listRowSeparator(.hidden)
                            .allowsHitTesting(false)
                    }
                    Color.clear
                        .frame(height: 0)
                        .id("bottomAnchor")
                        .listRowSeparator(.hidden)
                }
                .scrollContentBackground(.hidden)
                .contentMargins(.horizontal, 48, for: .scrollContent)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: Binding(get: { appStore.prompt }, set: { appStore.prompt = $0 }))
                    .textEditorStyle(.plain)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .padding(12)
                    .frame(height: 120)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.background)
                            .strokeBorder(Color.secondary.opacity(0.2))
                            .shadow(color: Color.secondary.opacity(0.2), radius: 1, x: 0.6, y: 0.6)
                    }
                    .scrollIndicators(.never)
                    .focused($isFocused)
                    .overlay(alignment: .topLeading) {
                        if appStore.prompt.isEmpty {
                            Text("Let's do something with Agent Skills")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .foregroundStyle(.primary)
                                .padding()
                        } else {
                            Button {
                                isShowPrompts.toggle()
                            } label: {
                                Text("Prompts")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(12)
                                    .foregroundStyle(Color.accent)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.secondary)
                            .popover(isPresented: $isShowPrompts) {
                                List {
                                    ForEach(prompts, id: \.self) { prompt in
                                        HStack(alignment: .top, spacing: 2) {
                                            Text(prompt)
                                                .font(.caption)
                                                .foregroundStyle(Color.primary)
                                            Spacer()
                                            Button {
                                                isShowPrompts.toggle()
                                                selectPrompt(prompt)
                                            } label: {
                                                Image(systemName: "document.on.clipboard.fill")
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(Color.secondary)
                                        }
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 12)
                                    }
                                }
                                .frame(minWidth: 320)
                            }
                        }
                    }
                Button {
                    if isProcessing {
                        callSkillInput()
                    } else {
                        callSkill()
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Color.white)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(appStore.prompt.isEmpty ? Color.accent.opacity(0.3) : Color.accent)
                .clipShape(Circle())
                .offset(x: -12, y: -12)
                .disabled(appStore.prompt.isEmpty)
                
            }
        }
        .padding(24)
        .background(Color.secondaryBackground)
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Menu {
                    ForEach(installedSkills) { skill in
                        Button {
                            selectPrompt("/\(skill.name) ")
                        } label: {
                            Text(skill.name)
                                .foregroundStyle(.primary)
                                .font(.caption)
                        }
                    }

                } label: {
                    Label("Installed", systemImage: "arrow.down")
                        .labelStyle(.iconOnly)
                        .labelIconToTitleSpacing(2)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            getInstalledSkills()
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo("bottomAnchor", anchor: .bottom)
        }
    }
    
    private func selectPrompt(_ prompt: String) {
        self.appStore.prompt = prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isFocused = true
        }
    }
    
    private func getInstalledSkills() {
        self.installedSkills = self.appStore.getInstalledSkills()
    }
    
    private func callSkill() {
        self.messages.removeAll()
        self.isProcessing = true
        Task {
            do {
                try await self.appStore.executeWithPrompt(self.appStore.prompt) { message in
                    self.messages.append(message)
                }
                await MainActor.run {
                    self.isProcessing = false
                    self.appStore.prompt = ""
                }

            } catch let error {
                debugPrint(error)
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func callSkillInput() {
        Task {
            do {
                try await self.appStore.executeWithInput(self.appStore.prompt)
                await MainActor.run {
                    self.messages.append(ConsoleMesage(type: "Input", message: self.appStore.prompt))
                    self.appStore.prompt = ""
                }

            } catch let error {
                debugPrint(error)
            }
        }
    }
}

#Preview {
    TerminalView()
        .environment(AppStore())
        .frame(width: 720, height: 480)
}
