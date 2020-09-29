//
//  WebSocketProxy.swift
//  Starscream
//
//  Created by 金小白 on 2020/9/28.
//

import UIKit

@objc(WebSocketProxyDelegate)
public protocol WebSocketProxyDelegate: NSObjectProtocol {
    func didOpen() -> Void
    func didClose() -> Void
    func didCancel() -> Void
    func didFail(_ error: Error) -> Void
    func didReceiveMessage(_ message: String) -> Void
    func didReceiveData(_ data: Data) -> Void
    func didReceivePing() -> Void
    func didReceivePong() -> Void
}

public class WebSocketProxy: NSObject, WebSocketDelegate {
    @objc public weak var delegate: WebSocketProxyDelegate?
    @objc public var isConnected = false
    
    var socket: WebSocket!
    
    @objc public init(request: URLRequest) {
        super.init()
        socket = WebSocket(request: request)
        socket.callbackQueue = DispatchQueue(label: "com.okmobile.websocket.callbackqueue")
        socket.delegate = self
    }
    
    @objc public func connect() {
        socket.connect()
    }
    
    @objc public func disconnect() {
        socket.forceDisconnect()
    }
    
    @objc public func send(_ message: String) {
        if message != nil {
            socket.write(string: message)
        }
    }
    
    @objc public func sendPing(_ ping: Data) {
        if ping != nil {
            socket.write(ping: ping)
        }
    }
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            self.delegate?.didOpen()
        case .disconnected(let reason, let code):
            isConnected = false
            self.delegate?.didClose()
        case .text(let string):
            self.delegate?.didReceiveMessage(string)
        case .binary(let data):
            self.delegate?.didReceiveData(data)
        case .ping(_):
            self.delegate?.didReceivePing()
            break
        case .pong(_):
            self.delegate?.didReceivePong()
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
            self.delegate?.didCancel()
        case .error(let error):
            isConnected = false
            handleError(error)
        }
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            self.delegate?.didFail(e)
        } else if let e = error {
            self.delegate?.didFail(e)
        } else {
            let anError = NSError(domain: "com.okmobile.websocket", code: -1, userInfo: nil)
            self.delegate?.didFail(anError)
        }
    }
}
