//
//  ChatGPT.swift
//  iChatGPT
//
//  Created by HTC on 2022/12/8.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation
import Combine
import OpenAI

let kDeafultAPIHost = "api.openai.com"
let kDeafultAPITimeout = 60.0
let kAPIModels = [Model.gpt3_5Turbo, Model.gpt4, Model.gpt4_32k, Model.gpt4_32k_0314, Model.gpt4_32k_0613, Model.gpt3_5Turbo_16k, Model.gpt3_5Turbo_16k_0613]

class Chatbot {
    var timeout: TimeInterval = 60 // API请求的超时时间，默认为60秒
	var userAvatarUrl = "" //"https://raw.githubusercontent.com/37iOS/iChatGPT/main/icon.png"
    var openAIKey = ""
    var openAI: OpenAI // OpenAI实例，用于执行API请求
    var answer = "" // 存储从OpenAI API获取的答案
    
    init(openAIKey:String, timeout: TimeInterval = kDeafultAPITimeout, host: String? = kDeafultAPIHost) {
        self.openAIKey = openAIKey
        // 使用提供的参数配置OpenAI实例
        let config = OpenAI.Configuration(token: self.openAIKey, host: host ?? kDeafultAPIHost, timeoutInterval: timeout)
        self.openAI = OpenAI(configuration: config)
	}
    // 获取用户头像URL的函数
    func getUserAvatar() -> String {
        userAvatarUrl
    }
    // 获取聊天GPT答案的函数
    func getChatGPTAnswer(prompts: [AIChat], sendContext: Bool, isStream: Bool, roomModel: ChatRoom?, completion: @escaping (String) -> Void) {
        // 构建对话记录
        print("prompts")
        print(prompts)
        var messages: [Chat] = []
        // 如果sendContext为true，使用历史聊天记录作为上下文
        if sendContext {
            // 每次只放此次提问之前三轮问答，且答案只放前面100字，已经足够AI推理了
            let historyCount = roomModel?.historyCount ?? 3
            let prompts = Array(prompts.suffix(historyCount + 1))
            for i in 0..<prompts.count {
                if i == prompts.count - 1 {
                    messages.append(.init(role: .user, content: prompts[i].issue))
                    break
                }
                messages.append(.init(role: .user, content: prompts[i].issue))
                messages.append(.init(role: .assistant, content: String((prompts[i].answer ?? "").prefix(100))))
            }
            
        } else {
            // 如果不发送上下文，则仅添加最后一条用户问题
            messages.append(.init(role: .user, content: prompts.last?.issue ?? ""))
        }
        // 如果聊天室模型中有预设的提示文本，将其作为系统角色的消息添加到对话记录中
        if let prompt = roomModel?.prompt, !prompt.isEmpty {
            messages.append(.init(role: .system, content: prompt))
        }
        
        print("message:")
        print(messages)
        // 获取使用的模型名称，默认为"gpt-3.5-turbo"
        let model = prompts.last?.model ?? "gpt-3.5-turbo"
        print("model:")
        print(model)
        // 构建查询对象
        let query = ChatQuery.init(model: model, messages: messages, temperature: roomModel?.temperature ?? 0.7)
        // Chats Streaming
        // 根据isStream决定是使用流式聊天API还是常规聊天API
        if isStream {
            // 使用流式API获取答案
            openAI.chatsStream(query: query) { partialResult in
                // 处理流式响应的每个部分
                switch partialResult {
                case .success(let chatResult):
                    //print(chatResult.choices)
                    if let res = chatResult.choices.first?.delta.content {
                        DispatchQueue.main.async {
                            completion(res)
                        }
                    }
                case .failure(let error):
                    //Handle chunk error here
                    print(error)
                    let errorMessage = error.localizedDescription
                    DispatchQueue.main.async {
                        completion(errorMessage)
                    }
                }
            } completion: { error in
                // 流式响应完成后的处理
                //Handle streaming error here
                print(error ?? "Unknown Error.")
                if let errorMessage = error?.localizedDescription {
                    DispatchQueue.main.async {
                        completion(errorMessage)
                    }
                }
            }
        } else {
            // 使用常规API获取答案
            openAI.chats(query: query) { result in
                print("data:")
                print(result)
                switch result {
                case .success(let chatResult):
                    // 成功获取答案，调用completion回调
                    let res = chatResult.choices.first?.message.content
                    DispatchQueue.main.async {
                        completion(res ?? "Unknown Error.")
                    }
                case .failure(let error):
                    // 获取答案失败，调用completion回调传递错误消息
                    print(error)
                    let errorMessage = error.localizedDescription
                    DispatchQueue.main.async {
                        completion(errorMessage)
                    }
                }
            }
        }
    }

}
