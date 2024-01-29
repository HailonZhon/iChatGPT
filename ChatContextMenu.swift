//
//  ChatContextMenu.swift
//  iChatGPT
//
//  Created by HTC on 2022/12/8.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import SwiftUI

// 定义一个上下文菜单视图，为聊天项提供多种操作
struct ChatContextMenu: View {
    
    @Binding var searchText: String // 与父视图中的搜索文本绑定
    @StateObject var chatModel: AIChatModel // 聊天模型对象，用于管理聊天内容和操作
    let item: AIChat // 当前聊天项的数据，包括问题和答案
    
    // 主体视图
    var body: some View {
        VStack {
            // 创建菜单项：重新提问
            CreateMenuItem(text: "Re-question".localized(), imgName: "arrow.up.message") {
                chatModel.getChatResponse(prompt: item.issue) // 使用问题文本重新获取聊天回应
            }
            // 创建菜单项：复制问题到剪贴板
            CreateMenuItem(text: "Copy Question".localized(), imgName: "doc.on.doc") {
                item.issue.copyToClipboard() // 将问题文本复制到剪贴板
            }

            // 创建菜单项：复制答案到剪贴板
            CreateMenuItem(text: "Copy Answer".localized(), imgName: "doc.on.doc") {
                item.answer!.copyToClipboard() // 将答案文本复制到剪贴板
            }
            .disabled(item.answer == nil) // 如果答案为空，则禁用此菜单项

            // 创建菜单项：复制问题和答案到剪贴板
            CreateMenuItem(text: "Copy Question and Answer".localized(), imgName: "doc.on.doc.fill") {
                "\(item.issue)\n-----------\n\(item.answer ?? "")".copyToClipboard() // 将问题和答案一起复制到剪贴板
            }
            .disabled(item.answer == nil) // 如果答案为空，则禁用此菜单项

            // 创建菜单项：将问题复制到输入框
            CreateMenuItem(text: "Copy Question to Inputbox".localized(), imgName: "keyboard.badge.ellipsis") {
                searchText = searchText + item.issue // 将问题文本添加到搜索/输入框文本中
            }

            // 检查是否有正在等待回答的问题
            let isWait = chatModel.contents.filter({ $0.isResponse == false })
            
            // 创建菜单项：删除当前问题
            CreateMenuItem(text: "Delete Question".localized(), imgName: "trash", isDestructive: true) {
                if let index = chatModel.contents.firstIndex(where: { $0.datetime == item.datetime }) {
                    chatModel.contents.remove(at: index) // 从聊天内容中删除当前项
                }
            }

            // 创建菜单项：删除所有聊天内容
            CreateMenuItem(text: "Delete All".localized(), imgName: "trash", isDestructive: true) {
                chatModel.contents.removeAll() // 清空所有聊天内容
            }.disabled(isWait.count > 0) // 如果有正在等待回答的问题，则禁用此菜单项
        }
    }

    // 创建菜单项的函数，支持在iOS 15及以上版本中使用destructive角色
    func CreateMenuItem(text: String, imgName: String, isDestructive: Bool = false, onAction: (() -> Void)?) -> some View {
        if #available(iOS 15.0, *) {
            return Button(role: isDestructive ? .destructive : nil) { // 如果isDestructive为true，则设置按钮角色为destructive
                onAction?() // 执行传入的操作闭包
            } label: {
                Label(text, systemImage: imgName) // 使用文本和系统图像创建标签
            }
        } else {
            // 对于iOS 15以下版本，没有destructive角色，使用普通按钮
            return Button {
                onAction?() // 执行传入的操作闭包
            } label: {
                Label(text, systemImage: imgName) // 使用文本和系统图像创建标签
            }
        }
    }
}
