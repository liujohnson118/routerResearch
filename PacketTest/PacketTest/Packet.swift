//
//  Packet.swift
//  PacketRecieverTest
//
//  Created by James Park on 2017-09-08.
//  Copyright © 2017 James Park. All rights reserved.
//

import Foundation

/// Determines the type of a packet.
public struct PacketType: RawRepresentable, Equatable {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /// First packet sent when a connection is made.
    public static let handshake = PacketType(rawValue: 0)
    
    /// Packet sent periodically to measure lag and detect disconnected peripherals
    public static let ping = PacketType(rawValue: 1)
    
    /// Packet sent for switching between universe controllers
    public static let switchUniverse = PacketType(rawValue: -1)
    
    public static func == (lhs: PacketType, rhs: PacketType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

/// Possible errors encountered when serializing/deserializing a `Packet`.
public enum PacketSerializationError: Error {
    case notEnoughData
}

/// Communication packet.
public struct Packet: Equatable {
    /// The size of a packet with no payload.
    public static let basePacketSize = MemoryLayout<UInt32>.size + MemoryLayout<PacketType>.size + MemoryLayout<Int32>.size
    
    /// The packet type.
    public var packetType: PacketType
    
    /// The packet identifier.
    public var id = -1
    
    //public var ipadID = -1
    
    
    //public var frameID = UUID()
    
    /// Payload data.
    public var payload: Data?
    
    /// Creates a `Packet` with a specifc packet type, identifier and optional payload data.
    public init(type: PacketType, id: Int, payload: Data? = nil) {
        self.packetType = type
        self.id = id
        self.payload = payload
        //self.ipadID = ipadID
    }
    
    /// Serializes the packet.
    public func serialize() -> Data {
        let payloadSize = payload?.count ?? 0
        let packetSize = UInt32(Packet.basePacketSize + payloadSize)
        var packetData = Data(capacity: Int(packetSize))
        
        // The first element in the packet data needs to be the packet size to know if we have enought data to build the packet.
        packetData.append(packetSize)
        packetData.append(packetType.rawValue)
        packetData.append(Int32(id))
        //packetData.append(Int32(ipadID))
        //packetData.append(Int32(frameID.uuidString))
        
        if let d = payload, d.count > 0 {
            packetData.append(d)
        }
        return packetData
    }
    
    /// Deserializes a packet.
    public init(_ packetData: Data) throws {
        var index = 0
        
        let packetSize = packetData.extract(UInt32.self, at: index)
        if packetData.count < Int(packetSize) {
            throw PacketSerializationError.notEnoughData
        }
        index += MemoryLayout.size(ofValue: packetSize)
        
        packetType = PacketType(rawValue: packetData.extract(PacketType.RawValue.self, at: index))
        index += MemoryLayout.size(ofValue: packetType)
        
        id = Int(packetData.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        
        let payloadSize = Int(packetSize) - Packet.basePacketSize
        if payloadSize > 0 {
            payload = packetData.subdata(in: packetData.startIndex.advanced(by: index) ..< packetData.startIndex.advanced(by: index + payloadSize))
        }
    }
    
    public var description: String {
        return "Packet: \(packetType), \(id), \(payload == nil ? "No Data" : "\(payload!.count) bytes of payload")"
    }
}

public func == (lhs: Packet, rhs: Packet) -> Bool {
    return lhs.packetType == rhs.packetType && lhs.id == rhs.id
}
