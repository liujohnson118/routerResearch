//
//  ViewController.swift
//  PacketRecieverTest
//
//  Created by James Park on 2017-09-08.
//  Copyright © 2017 James Park. All rights reserved.
//

import Cocoa
import CocoaAsyncSocket


class ViewController: NSViewController, GCDAsyncSocketDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let socketManager = SocketManager.sharedManager
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }



}

