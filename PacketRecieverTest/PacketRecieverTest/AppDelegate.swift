//
//  AppDelegate.swift
//  PacketRecieverTest
//
//  Created by James Park on 2017-09-08.
//  Copyright © 2017 James Park. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        SocketManager.sharedManager

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application

        SocketManager.sharedManager.close()

    }


}

