// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.


import Foundation
import CocoaAsyncSocket

open class SocketManager: NSObject, GCDAsyncUdpSocketDelegate {
    static let masterPort = UInt16(10101)
    static let peripheralPort = UInt16(11111)
    static let masterHost = "10.0.0.1"
    static let broadcastHost = "10.0.255.255"

    //255.255.0.0 (DHCP subnet mask)
    //10.0.0.2 (router network)
    static let sharedManager = SocketManager()


    let maxDeviceID = 28
    var totalBytes=0
    var bound = false
    var prevTime=0.0

    //the socket that will be used to connect to the core app
    var socket: GCDAsyncUdpSocket!

    open lazy var deviceID: Int = 20
  
    public override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        socket.setIPv4Enabled(true)
        socket.setIPv6Enabled(false)
        open()
        let packet = Packet(type: .handshake, id: deviceID)
        socket.send(packet.serialize() as Data, toHost: SocketManager.masterHost, port: SocketManager.masterPort, withTimeout: -1, tag: 0)
    }

    open func close() {
        socket.close()
        bound = false
    }

    open func open() {
        if !bound {
            do {
                try socket.enableBroadcast(true)
                try socket.bind(toPort: SocketManager.peripheralPort)
                try socket.beginReceiving()
            } catch {
                print("could not open socket")
                return
            }
            bound = true

        }
    }
    
    /*Function to log received data to dataRecieved.txt*/
    /*You may need to do touch "dataReceived.txt" in your Mac Documents directory*/
    func logData(_ data: Int){
        let file="dataReceived.txt"
        let currentTime=Date().timeIntervalSince1970
        let currentBytes=self.totalBytes
        var bytesPerSec=0.0
        if currentBytes > 0{
            bytesPerSec=Double(data)/(currentTime-self.prevTime)
            print("Instantaenous reception speed is \(bytesPerSec) bytes per second")
            self.prevTime=currentTime
        }else{
            self.prevTime=currentTime
        }
        self.totalBytes=self.totalBytes+data
        let text=String(data)+" "+String(currentTime)+","
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            let path=dir.appendingPathComponent(file)
            if let fileHandle=try?FileHandle(forUpdating: path){
                fileHandle.seekToEndOfFile()
                fileHandle.write(text.data(using: .utf8)!)
                fileHandle.closeFile()
            }else{
                print("Error logging to dataReceived.txt")
            }
        }
    }

    open func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var packet: Packet!
        do {
            packet = try Packet((data as NSData) as Data)
        } catch {
            return
        }
        if let data = packet.payload {
            logData(data.count)
        }
    }

    open func broadcastPacket(_ packet: Packet) {
        socket.send(packet.serialize() as Data, toHost: SocketManager.broadcastHost, port: SocketManager.peripheralPort, withTimeout: -1, tag: 0)
    }
}
