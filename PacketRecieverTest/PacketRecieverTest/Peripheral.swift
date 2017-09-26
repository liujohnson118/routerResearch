// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

import CocoaAsyncSocket

class Peripheral: NSObject {
    enum Status: String {
        case Connecting
        case Connected
        case Disconnected
    }

    static let pingTimeout = 5.0

    var socket: GCDAsyncUdpSocket

    /// The peripheral's identifier
    var id = -1

    /// The peripheral's IP address
    var address: String

    /// Whether a hanshake was received
    var status = Status.Connecting

    var lastPingResponse: Date?

    var lag: TimeInterval {
        guard let date = lastPingResponse else {
            return -1
        }
        return NSDate().timeIntervalSince(date)
    }

    /// Buffer for reading data
    var readBuffer = NSMutableData()

    /// The action to invoke when a packet is received
    var didReceivePacketAction: ((Packet, Peripheral) -> Void)?

    init(address: String, socket: GCDAsyncUdpSocket) {
        self.socket = socket
        self.address = address
        super.init()
    }

    func sendHandshake() {
        let p = Packet(type: .handshake, id: SocketManagerMaster.masterID)
        socket.send(p.serialize(), toHost: SocketManagerMaster.broadcastHost, port: SocketManagerMaster.peripheralPort, withTimeout: -1, tag: 0)
    }

    func processData(_ data: Data) {
        readBuffer.append(data)

        var readOffset = 0
        while readBuffer.length >= MemoryLayout<UInt32>.size {
            let packetSize = Int(readBuffer.bytes.advanced(by: readOffset).assumingMemoryBound(to: UInt32.self).pointee)
            if packetSize > 0 && readBuffer.length - readOffset >= packetSize {
                // We have all the data necessary for the packet
                let packetData = Data(bytes: readBuffer.bytes.advanced(by: readOffset).assumingMemoryBound(to: UInt8.self), count: packetSize)
                processPacketWithData(packetData)
                readOffset += packetSize
            } else {
                break
            }
        }

        // Move remaining data to the beginning of the buffer
        let remainingSize = readBuffer.length - readOffset
        readBuffer.replaceBytes(in: NSRange(location: 0, length: remainingSize), withBytes: readBuffer.bytes + readOffset)
        readBuffer.length -= readOffset
    }

    func processPacketWithData(_ data: Data) {
        var packet: Packet
        do {
            packet = try Packet(data)
        } catch {
//            DDLogWarn("Invalid packet received from \(id): \(error)")
            return
        }

        switch packet.packetType {
        case PacketType.handshake:
            id = packet.id
            status = .Connected
//            DDLogVerbose("Got handshake from \(id)")

        case PacketType.ping:
            id = packet.id
            lastPingResponse = Date()

        default:
            break
        }
        
        didReceivePacketAction?(packet, self)
    }
}
