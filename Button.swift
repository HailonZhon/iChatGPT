//
//  Button.swift
//  iChatGPT
//
//  Created by Midnight Maverick on 2024/1/29.
//  Copyright © 2024 37 Mobile Games. All rights reserved.
//
import SwiftUI
import Foundation
// 顶部导航栏
struct TopBarView: View {
    let action1: () -> Void
    let action2: () -> Void
    let action3: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action1) {
                Image(systemName: "line.horizontal.3")
                    .imageScale(.large)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            Button(action: action2) {
                Text("ChatGPT-4")
                    .fontWeight(.bold)
                    .font(.system(size: 20))
            }
            
            Spacer()
            
            Button(action: action3) {
                Image(systemName: "pencil.tip.crop.circle.badge.plus")
                    .imageScale(.large)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.trailing, 20)
        }
    }
}

struct BottomBarView: View {
    @Binding var messageText: String
    let actionCamera: () -> Void
    let actionPhoto: () -> Void
    let actionFolder: () -> Void
    let actionAudio: () -> Void
    let actionSendMessage: () -> Void
    let actionHeadphones: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            IconButton(iconName: "camera.fill", action: actionCamera)
            IconButton(iconName: "photo.fill.on.rectangle.fill", action: actionPhoto)
            IconButton(iconName: "folder.fill", action: actionFolder)
            
            Spacer()
            
            // 消息输入框
            MessageTextField(messageText: $messageText, actionAudio: actionAudio)

            Spacer()
            
            // 根据输入框是否有文本显示不同的按钮
            if messageText.isEmpty {
                IconButton(iconName: "headphones", action: actionAudio)
            } else {
                Button(action: actionSendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

// 图标按钮
struct IconButton: View {
    let iconName: String
    var iconWeight: Font.Weight = .regular // 添加一个参数来设置图标的粗细，默认为.regular
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: iconWeight)) // 使用font修饰符来设置图标的大小和粗细
                .frame(width: 44, height: 44)
        }
    }
}
// 消息输入框
struct MessageTextField: View {
    @Binding var messageText: String
    let actionAudio: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            TextField("消息", text: $messageText)
                .padding(10)
                .background(Capsule().fill(colorScheme == .dark ? Color.black : Color.white))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            // 当输入框为空时，显示音频按钮
            if messageText.isEmpty {
                Button(action: actionAudio) {
                    Image(systemName: "waveform")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }.padding(.leading, -25) // 使用负边距将音频按钮向左移动
            }
        }
        .overlay(
            Capsule().stroke(Color.gray, lineWidth: 1)
        )
        .padding(.horizontal, 10)
    }
}
