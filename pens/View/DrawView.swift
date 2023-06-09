//
//  DrawView.swift
//  pens
//
//  Created by 박상준 on 2023/05/16.
//

import SwiftUI
import PencilKit

class DrawingModel: ObservableObject {
    @Published var canvas = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    let drawingClient = DrawingClient()
    let webSocketDrawingClient = WebSocketDrawingClient()
    var webSocketDelegate: DrawViewWebSocketDelegate? = nil
    var fileId: Int
    var fileName: String
    var url: URL
    var groupId: Int
    var canvasPressing = false
    var bufferedDrawingData: Data?
    var userId: Int
    
    init(fileId: Int, fileName: String, url: URL, groupId: Int, userId: Int) {
        self.fileId = fileId
        self.fileName = fileName
        self.url = url
        self.groupId = groupId
        self.userId = userId
    }
}

class UserListModel: ObservableObject {
    @Published var userList: [String] = []
}

struct UserListView: View {
    @ObservedObject var userListModel: UserListModel
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    ForEach(userListModel.userList, id: \.self ) { userName in
                        HStack {
                            Image("menu").resizable().scaledToFit().frame(width:30, height:30).cornerRadius(10)
                            Text("\(userName)")
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .shadow(radius: 10)
            }
            Spacer()
        }
        .padding()
    }
}

struct DrawView: View {
    @ObservedObject var drawingModel: DrawingModel
    @ObservedObject var userListModel = UserListModel()
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(drawingModel.fileName)")
                CanvasView(drawingModel: drawingModel)
                    .overlay(
                        UserListView(userListModel: userListModel),
                        alignment: .topTrailing
                    )
            }
            .onAppear {
                self.drawingModel.toolPicker.setVisible(true, forFirstResponder: self.drawingModel.canvas)
                self.drawingModel.toolPicker.addObserver(self.drawingModel.canvas)
                self.drawingModel.canvas.becomeFirstResponder()
                DrawFileManager.shared.loadDrawing(into: self.drawingModel.canvas, fileName: self.drawingModel.fileName)
                
                if let url = URL(string: self.drawingModel.drawingClient.roomURL(roomID: String(self.drawingModel.fileId), userId: String(self.drawingModel.userId))) {
                    self.drawingModel.webSocketDrawingClient.connect(url: url)
                }
                
                self.drawingModel.webSocketDelegate = DrawViewWebSocketDelegate(drawingModel: self.drawingModel, userListModel: self.userListModel)
                self.drawingModel.webSocketDrawingClient.delegate = self.drawingModel.webSocketDelegate
            }
            .onDisappear{
                DrawFileManager.shared.saveDrawing(self.drawingModel.canvas, fileName: self.drawingModel.fileName, groupId: self.drawingModel.groupId)
                self.drawingModel.webSocketDrawingClient.disconnect()
            }
            .edgesIgnoringSafeArea(.all)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back")
                }
            })
        }
    }
}

class DrawViewWebSocketDelegate: WebSocketDrawingClientDelegate {
    var drawingModel: DrawingModel
    var userListModel: UserListModel
    
    init(drawingModel: DrawingModel, userListModel: UserListModel) {
        self.drawingModel = drawingModel
        self.userListModel = userListModel
    }
    
    func webSocket(_ webSocket: WebSocketDrawingClient, didReceive data: Data) {
        print("DrawView: websocket byte data handling")
        
        //self.receivingDrawing = true
        if self.drawingModel.canvasPressing {
            self.drawingModel.bufferedDrawingData = data
        } else {
            self.applyDrawingData(data: data)
        }
        //self.receivingDrawing = false
    }
    
    func applyDrawingData(data: Data) {
        DispatchQueue.main.async {
            if let drawing = try? PKDrawing(data: data) {
                self.drawingModel.canvas.drawing = drawing
                print("networking drawing success")
            } else {
                // handle error
                print("networking drawing error")
            }
        }
    }
    
    func webSocket(_ webSocket: WebSocketDrawingClient, didReceive data: String) {
        print("DrawView: websocket string data handling")
        
        if let data = data.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if dict.keys.contains("data"),
               let dataStr = dict["data"] as? String {
                print(dataStr)
                getUsersByUidListString(uidListString: dataStr)
            }
        }
               
        DispatchQueue.main.async {
            let drawData = self.drawingModel.canvas.drawing.dataRepresentation()
            self.drawingModel.drawingClient.sendDrawingData(drawData, websocket: self.drawingModel.webSocketDrawingClient) {
                print("send drawData[\(drawData)] for init user")
            }
        }
    }
    
    // Implementation for WebSocketClientDelegate
    func webSocketDidConnect(_ webSocket: WebSocketDrawingClient) {
        // Handle WebSocket connection event
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketDrawingClient) {
        // Handle WebSocket disconnection event
    }
    
    func getUsersByUidListString(uidListString: String) {
        self.userListModel.userList.removeAll()
        uidListString.split(separator: " ").forEach{ userId in
            getUserNameByUserId(userId: Int(userId), completion: { name in
                if let name { self.userListModel.userList.append(name) }
            })
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @ObservedObject var drawingModel: DrawingModel
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        drawingModel.canvas.delegate = coordinator
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let canvas = drawingModel.canvas
        
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1
        scrollView.delegate = context.coordinator
        scrollView.addSubview(canvas)
        
        canvas.drawingPolicy = .anyInput
        canvas.frame = CGRect(x: 0, y: 0, width: 10000, height: 10000)
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        
        DispatchQueue.main.async {
            let canvasCenter = CGPoint(x: canvas.frame.midX - scrollView.bounds.midX, y: canvas.frame.midY - scrollView.bounds.midY)
            scrollView.setContentOffset(canvasCenter, animated: false)
        }
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        scrollView.frame = drawingModel.canvas.frame
    }
}
    
    class Coordinator: NSObject, UIScrollViewDelegate, PKCanvasViewDelegate{
        var parent: CanvasView
        
        var localDrawing = false
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return parent.drawingModel.canvas
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            print("canvasViewDidBeginUsingTool")
            parent.drawingModel.canvasPressing = true
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            print("canvasViewDidEndUsingTool")
            parent.drawingModel.canvasPressing = false
            if let data = parent.drawingModel.bufferedDrawingData {
                parent.drawingModel.webSocketDelegate?.applyDrawingData(data: data)
                parent.drawingModel.bufferedDrawingData = nil
            }
//            let drawData = canvasView.drawing.dataRepresentation()
//            parent.drawingClient.sendDrawingData(drawData, roomId: parent.roomId, type: "drawing", websocket: parent.webSocketDrawingClient) {
//                print("send drawData[\(drawData)]")
//            }
            localDrawing = true
            
        }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            print("canvasViewDrawingDidChange")
//            guard let delegate = parent.webSocketDrawingClient.delegate as? DrawViewWebSocketDelegate,
//                  !delegate.receivingDrawing else {
//                return
//            }
            
            if(localDrawing) {
                let drawData = canvasView.drawing.dataRepresentation()
                parent.drawingModel.drawingClient.sendDrawingData(drawData, websocket: parent.drawingModel.webSocketDrawingClient) {
                    print("send drawData[\(drawData)]")
                }
                localDrawing = false
            }
        }
    }

struct DrawView_Previews: PreviewProvider {
    static var previews: some View {
        DrawView(drawingModel: DrawingModel(fileId: 1, fileName: "", url: URL(string:"")!, groupId: 1, userId: 1), userListModel: UserListModel())
    }
}
