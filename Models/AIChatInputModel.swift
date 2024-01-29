//
//  AIChatInputModel.swift
//  iChatGPT
//
//  Created by HTC on 2023/4/1.
//  Copyright © 2023 37 Mobile Games. All rights reserved.
//

import Foundation

// 定义了输入视图可能弹出的警告类型
enum InputViewAlert {
    case createNewChatRoom // 创建新聊天室
    case reloadLastQuestion // 重新加载上一个问题
    case clearAllQuestion // 清除所有问题
    case shareContents // 分享内容
}


// 用于管理聊天输入视图的状态的可观察对象类
class AIChatInputModel: ObservableObject {
    
    @Published var showingAlert = false // 控制是否显示警告弹窗的状态
    @Published var activeAlert: InputViewAlert = .createNewChatRoom // 当前激活的警告类型，默认为创建新聊天室

    @Published var isShowAllChatRoom: Bool = false // 控制是否显示所有聊天室列表的状态
    @Published var isConfigChatRoom: Bool = false // 控制是否显示聊天室配置视图的状态
    @Published var isScrollToChatRoomTop: Bool = false // 控制聊天视图是否滚动到顶部的状态
    @Published var searchText: String = "" // 聊天输入框中的文本
}

