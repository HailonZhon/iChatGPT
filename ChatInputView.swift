//
//  ChatInputView.swift
//  iChatGPT
//
//  Created by HTC on 2022/12/8.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import SwiftUI
import SwiftUIX

// 定义一个SwiftUI视图，用于聊天应用的输入界面
struct ChatInputView: View {
    
    // 使用@Binding来创建一个双向绑定的搜索文本，允许从父视图接收和更新值
    @Binding var searchText: String
    // 使用@StateObject来持有聊天模型的状态，这个对象在视图的整个生命周期内保持不变
    @StateObject var chatModel: AIChatModel
    // 使用@EnvironmentObject来接收从父视图或祖先视图注入的AI聊天输入模型
    @EnvironmentObject var model: AIChatInputModel
    // 使用@State来跟踪输入框是否处于编辑状态
    @State private var isEditing = false
    
    // 定义视图的主体部分
    var body: some View {
        VStack(alignment: .leading) {
//            inputToolBar() // 调用inputToolBar函数来渲染工具栏视图
            @Environment(\.colorScheme) var colorScheme
                
            // 使用水平堆叠来布局输入框和相关按钮
            HStack {
                ZStack(alignment: .leading) {
                    HStack {
                        IconButton(iconName: "camera.fill", action: { /* 相机动作 */ })
                        IconButton(iconName: "photo.fill.on.rectangle.fill", action: { /* 照片动作*/ })
                        // 修改文件夹图标的动作，以切换聊天模型中的isSendContext状态
                        IconButton(iconName: "folder.fill", action: {
                            chatModel.isSendContext.toggle() // 切换发送上下文状态
                        })
                        .foregroundColor(chatModel.isSendContext ? .black : .gray)
                        .onTapGesture {
                            chatModel.isSendContext.toggle() // 切换发送上下文状态
                        }
                        Spacer()
                        
                        MessageTextField(
                            messageText: $searchText,
                            actionAudio: {
                                /* 音频动作 */
                            }
                        )
                        // 当输入框为空时，显示耳机按钮
                        if searchText.isEmpty {
                            IconButton(
                                iconName: "headphones",
                                iconWeight: .light,
                                action: {
                                    /* 耳机动作 */
                                }
                            )
                        }

                        // 当searchText不为空时，显示清除和发送按钮
                        if searchText.count > 0 {
                            Button(action: fetchSearch) {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            .background(Capsule().fill(colorScheme == .dark ? Color.black : Color.white))
                            .padding(.trailing, 8)
                            .foregroundColor(.black)
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                    }
                }
            }
        }.gesture(
            TapGesture().onEnded { _ in
                hideKeyboard() // 收起键盘
            })
    }
    
    // 当搜索框的编辑状态发生变化时被调用
    func changedSearch(isEditing: Bool) {
        self.isEditing = isEditing
    }
    
    // 当用户提交搜索时被调用，用于获取聊天回应
    func fetchSearch() {
        guard !searchText.isEmpty else {
            return
        }
        chatModel.getChatResponse(prompt: searchText) // 使用搜索文本向聊天模型请求回应
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            clearSearch() // 提交后清空搜索框
        }
    }
    
    // 清空搜索框文本
    func clearSearch() {
        searchText = ""
    }
}
