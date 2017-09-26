//
//  WorkSpace.swift
//  PacketTest
//
//  Created by Geyi Liu on 2017-09-08.
//  Copyright © 2017 Geyi Liu. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class WorkSpace: CanvasController,GCDAsyncUdpSocketDelegate {

    override func setup() {
        let camera=Camera(frame:Rect(200,200,150,150))
        camera.backgroundColor=C4Blue
        canvas.add(camera)
    }
}


