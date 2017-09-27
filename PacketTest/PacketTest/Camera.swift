//
//  Camera.swift
//  c4Test
//
//  Created by James Park on 2017-08-28.
//  Copyright © 2017 James Park. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CocoaAsyncSocket

class CameraView: UIView {
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer!
    func setUpPreviewLayer(with session: AVCaptureSession) {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.layer.addSublayer(cameraPreviewLayer)
    }

    func getPreviewLayer() -> CALayer {
        return cameraPreviewLayer// swiftlint:disable:this force_cast
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}


class Camera: View, AVCapturePhotoCaptureDelegate, GCDAsyncSocketDelegate {

    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        get {
            return self.cameraView.cameraPreviewLayer
        }
    }

    var cameraView: CameraView {
        return self.view as! CameraView // swiftlint:disable:this force_cast
    }

    var packetsSent=0
    var bytesSent=0
    public var constrainsProportions: Bool = true

    public override var width: Double {
        get {
            return Double(view.frame.size.width)
        } set(val) {
            var newSize = Size(val, height)
            if constrainsProportions {
                newSize.height = val * height / width
            }
            var rect = self.frame
            rect.size = newSize
            self.frame = rect
        }
    }

    public override var height: Double {
        get {
            return Double(view.frame.size.height)
        } set(val) {
            var newSize = Size(Double(view.frame.size.width), val)
            if constrainsProportions {
                let ratio = Double(self.size.width / self.size.height)
                newSize.width = val * ratio
            }
            var rect = self.frame
            rect.size = newSize
            self.frame = rect
        }
    }
    var captureSesssion : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!

    public override init(frame: Rect) {
        super.init()
        self.view = CameraView(frame: CGRect(frame))
        captureSesssion = AVCaptureSession()
        captureSesssion.sessionPreset = AVCaptureSessionPresetPhoto
        cameraOutput = AVCapturePhotoOutput()
        let device = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            .map { $0 as! AVCaptureDevice }
            .filter { $0.position == .front}
            .first!

        if let input = try? AVCaptureDeviceInput(device: device) {
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
                if (captureSesssion.canAddOutput(cameraOutput)) {
                    captureSesssion.addOutput(cameraOutput)
                    self.cameraView.setUpPreviewLayer(with: captureSesssion)
                    self.cameraView.getPreviewLayer().frame = self.cameraView.bounds
                    captureSesssion.startRunning()
                }
            } else {
                print("issue here : captureSesssion.canAddInput")
            }
        } else {
            print("some problem here")
        }


        self.addTapGestureRecognizer { (_, _, _) in
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: 160,
                kCVPixelBufferHeightKey as String: 160
            ]
            settings.previewPhotoFormat = previewFormat
            self.cameraOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func createChunks(forData: Data) {
        let socketManager=SocketManager.sharedManager
        let uploadChunkSize = 3
        let totalSize = forData.count
        let initialData="\(totalSize),\(Int(ceil(Double(totalSize/uploadChunkSize))))"
        let initialPacket=Packet(type:PacketType(rawValue: 100000),id:-1, payload:initialData.data(using: .utf8))
        print("Initial data count is \(initialData.data(using:.utf8)?.count)")
        socketManager.broadcastPacket(initialPacket);
        
        forData.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            let mutRawPointer = UnsafeMutableRawPointer(mutating: u8Ptr)
            var offset = 0
            while offset < totalSize {
                let chunkSize = offset + uploadChunkSize > totalSize ? totalSize - offset : uploadChunkSize
                let chunk = Data(bytesNoCopy: mutRawPointer+offset, count: chunkSize, deallocator: Data.Deallocator.none)
                let packet = Packet(type: PacketType(rawValue: 100000),id:3, payload: chunk as! Data)
                socketManager.broadcastPacket(packet)
                print(chunk.count)
                offset += chunkSize
            }
        }
    }
    
    /*Function to log sent data*/
    /*You may need to create dataSent.txt in your Mac documents directory*/
    func logData(_ data: Int, speed: Double, time: Double){
        let text=String(data)+" "+String(time)+" "+String(speed)+","
        print(text)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        let socketManager=SocketManager.sharedManager
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)

            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
           //let data=UIImageJPEGRepresentation(image, 0) as Data?
            
            //createChunks(forData: data!)
            let thumbnail = resizeImage(image: image, targetSize: CGSize.init(width: 25, height: 25)) // snapshot image from camera resized
            
            let data = UIImageJPEGRepresentation(thumbnail,0.5) //the snapshot image converted into byte data
            
            let base64String = data!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            print("image size is \(data!.count) and string size is \(base64String.utf8.count)")
            //print(base64String)
            //createChunks(forData: data!)
            /*Simulate sending packets from multiple iPads*/
            //Assume videos are 30fps so with n iPads we're sending 30*n packets persecond
            var n=5 //number of iPads
            var delay=1000/(Double(n)*30) //delay between packets in miliseconds
            var i = 0
            let i_max = 10
            let startTime=Date().timeIntervalSince1970
            let endTime=startTime+60 //simulate sending packets for 600 seconds
            var currentTime=startTime
            var prevTime=startTime
            var bytesPerSec=0.0
            while currentTime<endTime{
                socketManager.broadcastPacket(Packet(type: PacketType(rawValue:100000), id:5,payload:data))
                self.packetsSent=self.packetsSent+1
                self.bytesSent=self.bytesSent+data!.count
                currentTime=Date().timeIntervalSince1970
                bytesPerSec=Double(data!.count)/(currentTime-prevTime)
                prevTime=currentTime
                logData(data!.count,speed: bytesPerSec, time: Double(currentTime))
                usleep(useconds_t(Int(round(delay)*1000)))
            }
            //UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        } else {
            print("Error capture image")
        }
     }
}
