//
//  TokenSettingView.swift
//  iChatGPT
//
//  Created by HTC on 2022/12/8.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import SwiftUI
import OpenAI

// 聊天API设置视图
struct ChatAPISettingView: View {
    
    @Binding var isKeyPresented: Bool // 控制视图是否显示的绑定属性
    @StateObject var chatModel: AIChatModel // 聊天模型对象，管理聊天数据和操作
    
    // 定义设置相关的状态变量
    @State private var selectedModel: Int = 0 // 选择的API模型索引
    @State private var apiHost = kDeafultAPIHost // API主机地址
    @State private var apiKey = "NKt5fonF0F563xye73D7D329E72749F49473FeA3C33b0e13" // API密钥
    @State private var maskedAPIKey = "" // 脱敏后显示的API密钥
    @State private var apiTimeout = "\(Int(kDeafultAPITimeout))" // API超时设置
    @State private var isStreamOutput = true // 是否使用流输出
    
    // 定义错误信息状态变量
    @State private var apiHostError = ""
    @State private var apiKeyError = ""
    @State private var apiTimeoutError = ""
    @State private var isDirty: Bool = false // 标记设置是否已更改
    
    // 获取App版本信息
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    private let appSubVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    // 视图初始化
    init(isKeyPresented: Binding<Bool>, chatModel: AIChatModel) {
        // 初始化状态变量和加载用户默认设置
        _isKeyPresented = isKeyPresented
        _chatModel = StateObject(wrappedValue: chatModel)
        
        if let savedModelName = UserDefaults.standard.string(forKey: ChatGPTModelName),
           let index = kAPIModels.firstIndex(of: savedModelName) {
            _selectedModel = State(initialValue: index)
        } else {
            _selectedModel = State(initialValue: 0)
        }
        
        if let lastHost = UserDefaults.standard.string(forKey: ChatGPTAPIHost) {
            _apiHost = State(initialValue: lastHost)
        }
        
        if let lastTime = UserDefaults.standard.string(forKey: ChatGPTAPITimeout) {
            _apiTimeout = State(initialValue: lastTime)
        }
        
        if let obj = UserDefaults.standard.object(forKey: ChatGPTStreamOutput), let isStream = obj as? Bool {
            _isStreamOutput = State(initialValue: isStream)
        }
        
        if let lastKey = lastOpenAIKey() {
            _maskedAPIKey = State(initialValue: lastKey)
        }
    }
    // 主体视图
    var body: some View {
        NavigationView {
            List {
                // API模型、主机、密钥、超时和流输出设置的列表
                Section(header: Text("API Model".localized())) {
                    Picker(selection: $selectedModel, label: Text("Deafult API Model".localized())) {
                        ForEach(0..<kAPIModels.count, id: \.self) {
                            Text(kAPIModels[$0])
                        }
                    }
                }
                
                Section(header: Text("API Host".localized())) {
                    TextField("For example: ".localized() + kDeafultAPIHost, text: $apiHost)
                    if !apiHostError.isEmpty {
                        HStack {
                            Text(apiHostError)
                                .foregroundColor(.red)
                                
                            Spacer()
                            
                            Button(action: {
                                apiHost = kDeafultAPIHost
                            }) {
                                Text("Use Default".localized())
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                Section(header: Text("API Key".localized())) {
                    TextField("Please enter OpenAI Key".localized(), text: $apiKey)
                    if !apiKeyError.isEmpty {
                        Text(apiKeyError)
                            .foregroundColor(.red)
                    }
                    if !maskedAPIKey.isEmpty {
                        HStack {
                            Text("Current use Key: ".localized() + maskedAPIKey)
                                .foregroundColor(.gray)
                                .font(.footnote)
                                
                            Spacer()
                            
                            Button(action: {
                                UserDefaults.standard.set(nil, forKey: ChatGPTOpenAIKey)
                                maskedAPIKey = ""
                            }) {
                                Text("Delete".localized())
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                Section(header: Text("API Timeout".localized())) {
                    TextField("API Request timeout (seconds)".localized(), text: $apiTimeout)
                        .keyboardType(.numberPad)
                    if !apiTimeoutError.isEmpty {
                        Text(apiTimeoutError)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Chats Streaming")) {
                    Toggle(isOn: $isStreamOutput) {
                        Text("Use streaming conversations")
                    }
                }
                
                aboutAppSection// App关于信息的部分
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings".localized())// 导航栏标题
            .navigationBarItems(
                trailing:
                    HStack {
                        // 保存和关闭按钮
                        Button(action: saveSettings, label: {
                            Text("Save".localized()).bold()
                        }).disabled(!isDirty)

                        Button(action: onCloseButtonTapped) {
                            Image(systemName: "xmark.circle").imageScale(.large)
                        }
                    }
            )
            .onChange(of: selectedModel) { _ in
                self.isDirty = validateSettings()// 当选择的模型改变时，验证设置
            }
            .onChange(of: [apiHost, apiKey, apiTimeout, String(isStreamOutput)]) { _ in
                self.isDirty = validateSettings()// 当任何设置改变时，验证设置
            }
            .gesture(
                TapGesture(count: 2).onEnded {
                    hideKeyboard()// 双击隐藏键盘
                }
            )
        }
    }
    // 保存设置按钮的动作
    private func saveSettings() {
        // 验证设置并保存到UserDefaults
        if !validateSettings() {
            return
        }
        
        // Save settings to UserDefaults
        UserDefaults.standard.set(kAPIModels[selectedModel], forKey: ChatGPTModelName)
        UserDefaults.standard.set(apiHost, forKey: ChatGPTAPIHost)
        if !apiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: ChatGPTOpenAIKey)
        }
        UserDefaults.standard.set(apiTimeout, forKey: ChatGPTAPITimeout)
        UserDefaults.standard.set(isStreamOutput, forKey: ChatGPTStreamOutput)
        isKeyPresented = false
        chatModel.isRefreshSession = true
    }
    // 验证设置值的合法性
    @discardableResult
    private func validateSettings() -> Bool {
        // 清空错误信息并验证每项设置
        apiHostError = ""
        apiKeyError = ""
        apiTimeoutError = ""
        
        guard !apiHost.isEmpty, (URL(string: "https://" + apiHost) != nil) else {
            apiHostError = "API host format is incorrect!".localized()
            return false
        }
        
        let apiKeyString = UserDefaults.standard.string(forKey: ChatGPTOpenAIKey) ?? ""
        guard !apiKey.isEmpty || !apiKeyString.isEmpty else {
            apiKeyError = "OpenAI Key cannot be empty".localized()
            return false
        }
        guard !apiTimeout.isEmpty, let timeoutValue = Double(apiTimeout), timeoutValue > 0 else {
            apiTimeoutError = "API timeout must be a number".localized()
            return false
        }
        
        return true
    }
    // 关闭按钮的动作，隐藏设置视图
    private func onCloseButtonTapped() {
        isKeyPresented = false
    }
    // 生成脱敏后的API密钥显示
    private func lastOpenAIKey() -> String? {
        guard let inputString = UserDefaults.standard.string(forKey: ChatGPTOpenAIKey) else { return nil }
        guard inputString.count > 6 else { return inputString }
        let firstThree = inputString.prefix(3)
        let lastThree = inputString.suffix(3)
        let masked = String(repeating: "*", count: min(inputString.count - 6, 10))
        return "\(firstThree)\(masked)\(lastThree)"
    }
    // App关于信息部分的视图
    private var aboutAppSection: some View {
        Section(header: Text("About App")) {
            VStack {
                ScrollView {
                    VStack {
                        // 显示App版本和子版本号
                        Text("v \(appVersion ?? "") (\(appSubVersion ?? ""))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)

//                        Text(.init("Developer: 37 Mobile iOS Tech Team\nGitHub: https://github.com/37iOS/iChatGPT".localized()))
//                            .font(.footnote)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.bottom, 10)
//                        显示开发者信息、GitHub链接和贡献者信息
//                        Text("Contributors：[@iHTCboy](https://github.com/iHTCboy) | [@AlphaGogoo](https://github.com/AlphaGogoo) | [@RbBtSn0w](https://github.com/RbBtSn0w) | [@0xfeedface1993](https://github.com/0xfeedface1993)")
//                            .font(.footnote)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.bottom, 25)
                    }
                }
                .frame(maxHeight: 120)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
