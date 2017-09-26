// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

import Foundation
import Cocoa
import CocoaAsyncSocket


public class SocketManagerMaster: NSObject, GCDAsyncUdpSocketDelegate {
    static let masterID = Int(INT_MAX)
    static let masterPort = UInt16(10101)
    static let peripheralPort = UInt16(11111)
    static let broadcastHost = "10.0.0.255"
    static let pingInterval = 0.5

    static let sharedManager = SocketManagerMaster()

    var queue: DispatchQueue
    var socket: GCDAsyncUdpSocket!

    /// A list of all the peripherals by IP address
    var peripherals = [String: Peripheral]()

    /// Action invoked when there is a change in status
    var changeAction: (() -> Void)?

    weak var pingTimer: Timer?

    public override init() {
        queue = DispatchQueue(label: "SocketManagerMaster", attributes: [])
        super.init()

        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)

        pingTimer = Timer.scheduledTimer(timeInterval: SocketManagerMaster.pingInterval, target: self, selector: #selector(SocketManagerMaster.ping), userInfo: nil, repeats: true)
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var hostString: NSString? = NSString()
        var port: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&hostString, port: &port, fromAddress: address)

        guard let host = hostString as? String else {
//            DDLogWarn("Received data from an invalid host")
            return
        }

        if let peripheral = peripherals[host] {
            peripheral.processData(data)
        } else {
            let peripheral = Peripheral(address: host, socket: socket)
            peripheral.didReceivePacketAction = processPacket
            peripherals[host] = peripheral
            peripheral.processData(data)
        }
    }

    func processPacket(_ packet: Packet, peripheral: Peripheral) {
        switch packet.packetType {
        case PacketType.handshake:
            DispatchQueue.main.async {
                self.changeAction?()
            }

        case PacketType.ping:
            DispatchQueue.main.async {
                self.changeAction?()
            }

        default:
            break
        }
    }

    // MARK: - Pinging

    func ping() {
        updateStatuses()
        let p = Packet(type: .ping, id: SocketManagerMaster.masterID)
        socket.send(p.serialize(), toHost: SocketManager.broadcastHost, port: SocketManager.peripheralPort, withTimeout: -1, tag: 0)
    }

    func updateStatuses() {
        for (_, p) in peripherals {
            if p.lag > Peripheral.pingTimeout {
                // Disconnect if we don't get a ping for a while
                p.status = .Disconnected
//                DDLogVerbose("Disconnected from: \(p.id)")
                queue.async {
                    self.peripherals.removeValue(forKey: p.address)
                }
            }
        }
    }
}
