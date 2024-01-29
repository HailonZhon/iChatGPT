//
//  AIChatView.swift
//  iChatGPT
//
//  Created by HTC on 2022/12/8.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import SwiftUI
import MarkdownText

// AIChatView定义了聊天界面的视图
struct AIChatView: View {
    
    // 定义一些状态变量来控制UI的动态行为
    @State private var isScrollListTop: Bool = false // 控制列表是否滚动到顶部
    @State private var isSettingsPresented: Bool = false // 控制设置视图是否显示
    @State private var isSharing = false // 控制分享功能是否激活
    @StateObject private var chatModel = AIChatModel(roomID: ChatRoomStore.shared.lastRoomId()) // 聊天模型，管理聊天数据
    @StateObject private var inputModel = AIChatInputModel() // 输入模型，管理用户输入
    @StateObject private var shareContent = ShareContent() // 分享内容模型，管理分享的内容
    
    // 主体视图
    var body: some View {
        NavigationView {
            VStack {
                chatList // 聊天列表视图
                Spacer() // 空白填充，用于调整布局
                ChatInputView(searchText: $inputModel.searchText, chatModel: chatModel) // 聊天输入视图
                    .padding([.leading, .trailing], 12) // 为输入视图添加左右内边距
            }
            .markdownHeadingStyle(.custom) // 自定义Markdown标题样式
            .markdownQuoteStyle(.custom) // 自定义Markdown引用样式
            .markdownCodeStyle(.custom) // 自定义Markdown代码样式
            .markdownInlineCodeStyle(.custom) // 自定义Markdown行内代码样式
            .markdownOrderedListBulletStyle(.custom) // 自定义Markdown有序列表样式
            .markdownUnorderedListBulletStyle(.custom) // 自定义Markdown无序列表样式
            .markdownImageStyle(.custom) // 自定义Markdown图片样式
            .navigationBarTitleDisplayMode(.inline) // 导航栏标题显示模式设为内联
            .navigationBarItems(trailing: addButton) // 导航栏添加按钮
            // 设置视图、聊天历史视图、聊天室配置视图、分享视图的展示逻辑
            .sheet(isPresented: $isSettingsPresented) {
                ChatAPISettingView(isKeyPresented: $isSettingsPresented, chatModel: chatModel)
            }
            .sheet(isPresented: $inputModel.isShowAllChatRoom) {
                ChatHistoryListView(isKeyPresented: $inputModel.isShowAllChatRoom, chatModel: chatModel, onComplete: { roomID in
                    if roomID != chatModel.roomID {
                        chatModel.resetRoom(roomID)
                        chatModel.isScrollListBottom.toggle()
                    }
                })
            }
            .sheet(isPresented: $inputModel.isConfigChatRoom) {
                ChatRoomConfigView(isKeyPresented: $inputModel.isConfigChatRoom, chatModel: chatModel)
            }
            .sheet(isPresented: $isSharing) {
                ActivityView(activityItems: $shareContent.activityItems)
            }
            // 警告弹窗的展示逻辑，包括新建聊天室、重新加载最后一个问题、清除所有问题、分享内容等
            .alert(isPresented: $inputModel.showingAlert) {
                switch inputModel.activeAlert {
                case .createNewChatRoom:
                    return CreateNewChatRoom()
                case .reloadLastQuestion:
                    return ReloadLastQuestion()
                case .clearAllQuestion:
                    return ClearAllQuestion()
                case .shareContents:
                    return ShareContents()
                }
            }
            // 监听滚动到聊天室顶部的状态变化
            .onChange(of: inputModel.isScrollToChatRoomTop) { _ in
                isScrollListTop.toggle()
            }
            // 工具栏配置，显示ChatGPT的图标和标题
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("chatgpt").resizable()
                            .frame(width: 25, height: 25)
                        Text("ChatGPT").font(.headline)
                    }
                }
            }
        }
        .navigationViewStyle(.stack) // 导航视图样式设为堆栈式
        .environmentObject(inputModel) // 将inputModel作为环境对象传递给子视图
    }
    
    // 聊天列表视图构建
    @ViewBuilder
    var chatList: some View {
        ScrollViewReader { proxy in
            List {
                // 遍历聊天内容，为每个聊天项创建一个Section
                ForEach(chatModel.contents, id: \.datetime) { item in
                    Section(header: Text(item.datetime)) {
                        VStack(alignment: .leading) {
                            // 用户的问题
                            HStack(alignment: .top) {
                                IconAvatarImageView(name: "chatgpt-icon-user", stroke: true)
                                MarkdownText(item.issue.replacingOccurrences(of: "\n", with: "\n\n"))
                                    .padding(.top, 2)
                            }
                            Divider()
                            // AI的回答
                            HStack(alignment: .top) {
                                IconAvatarImageView(name: item.model.hasPrefix("gpt-4") ? "chatgpt-icon-4" : "chatgpt-icon")
                                if item.isResponse {
                                    MarkdownText(item.answer ?? "")
                                        .padding(.top, 2)
                                } else {
                                    // 如果AI尚未回答，则显示加载中的提示
                                    HStack {
                                        ProgressView()
                                        Text("Loading..".localized())
                                            .padding(.leading, 10)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding([.top, .bottom], 3)
                        }.contextMenu {
                            // 为聊天项添加上下文菜单，用于执行不同的操作
                            ChatContextMenu(searchText: $inputModel.searchText, chatModel: chatModel, item: item)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // 列表样式设为内嵌分组列表样式
            // 监听是否需要滚动到列表底部
            .onChange(of: chatModel.isScrollListBottom) { _ in
                if let lastId = chatModel.contents.last?.datetime {
                    // 延迟一小段时间后滚动，以避免macOS上的崩溃
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .trailing)
                        }
                    }
                }
            }
            // 监听是否需要滚动到列表顶部
            .onChange(of: isScrollListTop) { _ in
                if let firstId = chatModel.contents.first?.datetime {
                    withAnimation {
                        proxy.scrollTo(firstId, anchor: .leading)
                    }
                }
            }
        }
    }
    
    // 设置按钮视图
    private var addButton: some View {
        Button(action: {
            isSettingsPresented.toggle()
        }) {
            HStack {
                if #available(iOS 15.4, *) {
                    Image(systemName: "key.viewfinder").imageScale(.large)
                } else {
                    Image(systemName: "key.icloud").imageScale(.large)
                }
            }
            .frame(height: 40)
            .padding(.trailing, 5)
        }
    }
}

// MARK: - 处理输入工具栏事件的扩展
extension AIChatView {
    
    // 创建新聊天室的警告弹窗配置
    func CreateNewChatRoom() -> Alert {
        Alert(
            title: Text("Open a new conversation".localized()), // 弹窗标题
            message: Text("The current chat log will be saved and closed, and a new chat session will be created.".localized()), // 弹窗消息
            primaryButton: .default(Text("Create".localized())) { // 创建按钮
                chatModel.resetRoom(nil) // 重置聊天室，开始新对话
            },
            secondaryButton: .cancel() // 取消按钮
        )
    }
    
    // 重新加载最后一个问题的警告弹窗配置
    func ReloadLastQuestion() -> Alert {
        Alert(
            title: Text("Re-ask".localized()), // 弹窗标题
            message: Text("Re-request the last question.".localized()), // 弹窗消息
            primaryButton: .default(Text("OK".localized())) { // 确定按钮
                if let issue = chatModel.contents.last?.issue {
                    chatModel.getChatResponse(prompt: issue) // 重新获取最后一个问题的回答
                }
            },
            secondaryButton: .cancel() // 取消按钮
        )
    }
    
    // 清除所有问题的警告弹窗配置
    func ClearAllQuestion() -> Alert {
        Alert(
            title: Text("Clear current conversation".localized()), // 弹窗标题
            message: Text("Clears the current conversation and deletes the saved conversation history.".localized()), // 弹窗消息
            primaryButton: .destructive(Text("Clear".localized())) { // 清除按钮
                chatModel.contents.removeAll() // 清除所有聊天内容
            },
            secondaryButton: .cancel() // 取消按钮
        )
    }
    
    // 分享内容的警告弹窗配置
    func ShareContents() -> Alert {
        Alert(
            title: Text("Share".localized()), // 弹窗标题
            message: Text("Choose a sharing format".localized()), // 弹窗消息
            primaryButton: .default(Text("Image".localized())) { // 分享图片按钮
                screenshotAndShare(isImage: true) // 截图并分享为图片
            },
            secondaryButton: .default(Text("PDF".localized())) { // 分享PDF按钮
                screenshotAndShare(isImage: false) // 截图并分享为PDF
            }
        )
    }
}

// MARK: - 处理分享图片/PDF
extension AIChatView {
    
    // 截图并根据选项分享为图片或PDF
    private func screenshotAndShare(isImage: Bool) {
        if let image = screenshot() { // 获取当前视图的截图
            if isImage {
                shareContent.activityItems = [image] // 将截图添加到分享内容
                isSharing = true // 激活分享
            } else {
                if let pdfData = imageToPDFData(image: image) { // 将图片转换为PDF数据
                    let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                    let fileName = "iChatGPT-Screenshot.pdf"
                    let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
                    
                    do {
                        try pdfData.write(to: fileURL, options: .atomic) // 将PDF数据写入文件
                        shareContent.activityItems = [fileURL] // 将文件URL添加到分享内容
                        isSharing = true // 激活分享
                    } catch {
                        print("Error writing PDF data to file: \(error)")
                    }
                }
            }
        }
    }
    
    // 获取当前视图的截图
    private func screenshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = UIScreen.main.bounds.size
        view?.frame = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    // 将UIImage转换为PDF数据
    private func imageToPDFData(image: UIImage) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))
        let pdfData = pdfRenderer.pdfData { (context) in
            context.beginPage() // 开始新页面
            image.draw(in: CGRect(origin: .zero, size: image.size)) // 将图片绘制到PDF页面上
        }
        return pdfData
    }
}

// 定义一个用于分享内容的类，遵循ObservableObject协议，允许其属性被SwiftUI视图观察
class ShareContent: ObservableObject {
    @Published var activityItems: [Any] = [] // 定义一个动态数组，用于存储分享的内容
}

// 定义一个符合UIViewControllerRepresentable协议的结构体，用于在SwiftUI中呈现UIActivityViewController
struct ActivityView: UIViewControllerRepresentable {
    @Binding var activityItems: [Any] // 绑定分享内容数组

    // 创建UIActivityViewController的实例
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    // 更新UIActivityViewController的实例，此处不需要额外操作
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
    }
}

// 定义一个展示头像图片的SwiftUI视图
struct AvatarImageView: View {
    let url: String // 头像图片的URL
    
    var body: some View {
        Group {
            ImageLoaderView(urlString: url) { // 使用ImageLoaderView加载图片
                Color(.tertiarySystemGroupedBackground) // 在图片加载过程中显示的占位颜色
            } image: { image in
                image.resizable() // 使图片可调整大小
                    .aspectRatio(contentMode: .fit) // 保持图片的宽高比
                    .frame(width: 25, height: 25) // 设置图片的尺寸
            }
        }
        .cornerRadius(5) // 设置圆角
        .frame(width: 25, height: 25) // 设置视图的尺寸
        .padding(.trailing, 10) // 设置右侧内边距
    }
}

// 定义一个展示图标头像的SwiftUI视图，支持描边效果
struct IconAvatarImageView: View {
    let name: String // 图标的名称
    var stroke: Bool = false // 是否显示描边

    var body: some View {
        HStack {
            if stroke {
                Image(name) // 加载图标图片
                    .resizable() // 使图片可调整大小
                    .frame(width: 25, height: 25) // 设置图片的尺寸
                    .clipShape(RoundedRectangle(cornerRadius: 5)) // 设置圆角矩形裁剪形状
                    .overlay(
                        RoundedRectangle(cornerRadius: 5) // 在图片上叠加一个圆角矩形边框
                            .stroke(Color.lightGray, lineWidth: 0.1) // 设置边框的颜色和线宽
                    )
            } else {
                Image(name) // 加载图标图片
                    .resizable() // 使图片可调整大小
                    .frame(width: 25, height: 25) // 设置图片的尺寸
                    .clipShape(RoundedRectangle(cornerRadius: 5)) // 设置圆角矩形裁剪形状
            }
        }
        .padding(.trailing, 10) // 设置右侧内边距
    }
}


struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
