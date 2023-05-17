import Foundation
import SwiftUI
import WebRTC


struct WebSocketMessage: Decodable {
    let type: String
    let sender: String?
    let receiver: String?
    let roomId: String
    let data: String?

}

class AudioCallViewModel: ObservableObject {

    var _roomClient: RoomClient?

    // MARK: Room
//    var _roomInfo: JoinResponseParam?
    var _roomId: String = ""

    var _webSocket: WebSocketClient?
    var _messageQueue = [String]()

    //MARK: WebRTC
    var _webRTCClient: WebRTCClient?

    func connectRoom(roomID: String) -> Void {
        dLog("connectToRoom");
        prepare(roomId: roomID);
        join(roomID: roomID)
    }

    private func prepare(roomId: String) {
        _roomClient = RoomClient();
        _webSocket = WebSocketClient();
        _webRTCClient = WebRTCClient();
        _roomId = roomId
    }

    func clear() {
        _roomClient = nil
        _webRTCClient = nil
        _webSocket = nil
    }
}

extension AudioCallViewModel {
    func join(roomID: String) -> Void {
        guard let _roomClient = _roomClient else {
            return
        }
//        _roomClient.join(roomID: roomID)
        connectToWebSocket(roomId: roomID)
    }
    
    func startVoiceChat() {
        _webRTCClient?.createOffer()
    }

    func disconnect() -> Void {
        let roomID = _roomId
        guard let roomClient = _roomClient,
            let webSocket = _webSocket,
            let webRTCClient = _webRTCClient else { return }

        roomClient.disconnect(roomID: roomID) { [weak self] in
            self?._roomId = ""
        }

        let message = ["type": "bye"]

        if let data = message.JSONData {
            webSocket.send(data: data)
        }
        webSocket.delegate = nil

        webRTCClient.disconnect()

        clear()
    }

    func drainMessageQueue() {
        guard let webSocket = _webSocket,
            webSocket.isConnected,
            let webRTCClient = _webRTCClient else {
            return
        }

        for message in _messageQueue {
            processSignalingMessage(message)
        }
        _messageQueue.removeAll()
        webRTCClient.drainMessageQueue()
    }

    func processSignalingMessage(_ message: String) -> Void {
        guard let webRTCClient = _webRTCClient else { return }
        let signalMessage = SignalMessage.from(message: message)
        switch signalMessage {
        case .ice(let candidate):
            webRTCClient.handleCandidateMessage(candidate)
            dLog("Receive candidate")
        case .answer(let answer):
            webRTCClient.handleRemoteDescription(answer)
            dLog("Recevie Answer")
        case .offer(let offer):
            webRTCClient.handleRemoteDescription(offer)
            dLog("Recevie Offer")
        case .bye:
            disconnect()
        default:
            break
        }
    }

    func sendSignalingMessage(_ message: Data, type: String) {
        guard let roomClient = _roomClient,
        let webSocket = _webSocket
        else { return }
        roomClient.sendMessage(message, roomId: _roomId, type: type, websocket: webSocket) {

        }
    }
}

//MARK: webSocketClientDelegate
extension AudioCallViewModel: WebSocketClientDelegate {
    func connectToWebSocket(roomId: String) -> Void {
        guard let webSocketURL = URL(string: APIContants.signalingServerURL + "?roomId=" + roomId) else {
            return
        }
//        let url = URL(string: webSocketURL)
        guard let webSocket = _webSocket else {
            return
        }
        webSocket.delegate = self
        debugPrint(webSocketURL)
        webSocket.connect(url: webSocketURL)
    }

//    func registerWithCollider(roomId: String) {
//        guard let webSocket = _webSocket else {
//            return
//        }
//
//        let message = ["type": "offer",
//            "roomId": roomId
//        ]
//
//        guard let data = message.JSONData else {
//            debugPrint("Error in Register room.")
//            return
//        }
//                do {
//            let jsonData = try JSONEncoder().encode(message)
//            webSocket.send(data: jsonData)
//        }
//        catch {
//            print("exception")
//            return
//        }
//
//
//        dLog("Register Room")
//    }

    func webSocketDidConnect(_ webSocket: WebSocketClient) {
        guard let webRTCClient = _webRTCClient else { return }

//        registerWithCollider(roomId: "1")

        webRTCClient.delegate = self
//        webRTCClient.createOffer()
        drainMessageQueue()

    }

    func webSocketDidDisconnect(_ webSocket: WebSocketClient) {
        webSocket.delegate = nil
    }

    func webSocket(_ webSocket: WebSocketClient, didReceive data: String) {
        processSignalingMessage(data)
        _webRTCClient?.drainMessageQueue()
    }
}

//MARK: WebRTCClientDelegate
extension AudioCallViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, sendData data: Data, type: String) {
        sendSignalingMessage(data, type: type)
    }
}

extension AudioCallViewModel {
    func audioEnable(_ enable: Bool) -> Void {
        self._webRTCClient?.AudioIsEnable = enable
    }

}