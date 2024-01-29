//
//  ChatHistoryListView.swift
//  iChatGPT
//
//  Created by HTC on 2023/4/1.
//  Copyright © 2023 37 Mobile Games. All rights reserved.
//

import SwiftUI


// 定义聊天历史列表视图
struct ChatHistoryListView: View {
    
    @Binding var isKeyPresented: Bool // 控制视图是否显示的绑定属性
    @StateObject var chatModel: AIChatModel // 聊天模型对象，管理聊天数据和行为
    var onComplete: (String) -> Void // 完成选中聊天室后的回调
    
    @State private var chatItems: [ChatRoom] = ChatRoomStore.shared.chatRooms().reversed() // 聊天室列表，初始时从聊天室存储中获取并反转顺序
    
    @State private var showingDeleteAlert = false // 控制删除确认弹窗是否显示的状态
    @State private var itemToDelete: ChatRoom? // 待删除的聊天室对象
    
    // 主体视图
    var body: some View {
        NavigationView {
            List {
                chatList // 聊天列表
            }
            .alert(isPresented: $showingDeleteAlert) { // 删除确认弹窗
                Alert(
                    title: Text("Delete Chat".localized()),
                    message: Text("Are you sure you want to delete this chat?".localized()),
                    primaryButton: .destructive(Text("Delete".localized())) {
                        if let item = itemToDelete {
                            deleteChat(item: item) // 执行删除操作
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Chat History".localized()) // 导航栏标题
            .toolbar {
                Button(action: onCloseButtonTapped) { // 关闭按钮
                    Image(systemName: "xmark.circle").imageScale(.large)
                }
            }
        }
    }
    
    // 聊天列表构建
    @ViewBuilder
    var chatList: some View {
        if #available(iOS 15, *) {
            ForEach(chatItems, id: \.roomID) { item in
                chatRow(for: item) // 为每个聊天室构建行视图
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) { // 添加滑动操作
                        Button {
                            itemToDelete = item
                            showingDeleteAlert = true // 显示删除确认弹窗
                        } label: {
                            Label("Delete".localized(), systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }
            .onDelete(perform: deleteChat) // 支持列表删除操作
        } else {
            // iOS 15以下版本的处理，不支持滑动操作
            ForEach(chatItems, id: \.roomID) { item in
                chatRow(for: item)
            }
            .onDelete(perform: deleteChat)
        }
    }
    
    // 构建单个聊天室的行视图
    private func chatRow(for item: ChatRoom) -> some View {
        // 聊天室行布局，包括图标、聊天室名称、当前聊天标识、消息数量和最后一条消息等信息
        HStack {
            // 聊天室图标
            Image(item.model?.hasPrefix("gpt-4") ?? false ? "chatgpt-icon-4" : "chatgpt-icon")
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(5)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading) {
                // 聊天室名称和消息数量展示
                HStack() {
                    // 显示最后一条消息和时间
                    Text(item.roomName ?? item.roomID.formatTimestamp())
                        .font(.headline)
                    
                    Spacer()
                    
                    if item.roomID == chatModel.roomID {
                        Text(" \("Current Chat".localized()) ")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding([.top, .bottom], 3)
                            .padding([.leading, .trailing], 4)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    
                    Text(" \(ChatMessageStore.shared.messages(forRoom: item.roomID).count) ")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 3)
                        .padding([.leading, .trailing], 4)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 5)
                
                HStack() {
                    Text(ChatMessageStore.shared.lastMessage(item.roomID)?.issue ?? "No conversations".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(ChatMessageStore.shared.lastMessage(item.roomID)?.datetime ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onComplete(item.roomID) // 点击后执行回调，传递选中的聊天室ID
            onCloseButtonTapped() // 并关闭视图
        }
    }
    // 删除聊天室操作
    private func deleteChat(item: ChatRoom) {
        if let index = chatItems.firstIndex(where: { $0.roomID == item.roomID }) {
            chatItems.remove(at: index)
            ChatRoomStore.shared.removeChatRoom(roomID: item.roomID)
            // check current room
            if item.roomID == chatModel.roomID {
                chatModel.resetRoom(ChatRoomStore.shared.lastRoomId())
            }
            
        }
    }
    // 根据滑动或选择的索引集合删除聊天室
    private func deleteChat(at offsets: IndexSet) {
        for index in offsets {
            itemToDelete = chatItems[index]
            showingDeleteAlert = true
        }
    }
    // 关闭按钮点击操作
    private func onCloseButtonTapped() {
        isKeyPresented = false// 关闭当前视图
    }
}

struct ChatHistoryListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryListView(isKeyPresented: .constant(true), chatModel: AIChatModel(roomID: nil), onComplete: {_ in })
    }
}
