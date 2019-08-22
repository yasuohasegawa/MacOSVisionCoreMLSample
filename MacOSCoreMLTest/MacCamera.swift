//
//  MacCamera.swift
//  MacOSCoreMLTest
//
//  Created by Yasuo Hasegawa on 2019/08/22.
//  Copyright © 2019 Yasuo Hasegawa. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import Vision

class MacCamera: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var videoOutput = AVCaptureVideoDataOutput()
    var view:NSView
    var txt:NSText
    
    let imgCaptureQueue = DispatchQueue(label: "com.coremltest")
    var captureImg:NSImage!
    var videoLayer:AVCaptureVideoPreviewLayer!
    
    let currentMLModel = Inceptionv3().model
    private let serialQueue = DispatchQueue(label: "com.dispatchqueueml")
    private var visionRequests = [VNRequest]()
    
    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    
    required init(view:NSView, txt:NSText)
    {
        self.view = view
        self.txt = txt
        super.init()
        
        let devices = AVCaptureDevice.devices()
        
        for device in devices {
            print(device)
            
            if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                print(device)
                videoDevice = device
            }
        }
        
        self.initialize()
    }
    
    func initialize()
    {
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
        
        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        self.captureSession.beginConfiguration()
        if let connection = self.videoOutput.connection(with: AVMediaType.video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        self.captureSession.commitConfiguration()
        
        videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        
        self.view.wantsLayer = true
        self.view.layer?.addSublayer(videoLayer)
        
        self.captureSession.startRunning()
        
        setupCoreML();
    }
    
    private func setupCoreML() {
        guard let selectedModel = try? VNCoreMLModel(for: currentMLModel) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel,
                                                    completionHandler: classificationCompleteHandler)
        
        // Crop from centre of images and scale to appropriate size.
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        
        // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
        classificationRequest.usesCPUOnly = true
        visionRequests = [classificationRequest]
    }
    
    private func updateCoreML(pixbuff:CVPixelBuffer) {
        let deviceOrientation = CGImagePropertyOrientation.up
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff, orientation: deviceOrientation,options: [:])
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    private func classificationCompleteHandler(request: VNRequest, error: Error?) {
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            return
        }
        
        let classifications = observations as! [VNClassificationObservation]
        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            let label = bestResult.identifier.split(separator: ",").first {
            identifierString = String(label)
            confidence = bestResult.confidence
        } else {
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async {
            //print("identifierString: \(self.identifierString) - confidence: \(String(describing: self.confidence))")
            self.txt.string = self.identifierString
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        updateCoreML(pixbuff: imageBuffer)
        
        DispatchQueue.main.sync(execute: {
            
        })
    }
    
    public func resizeWindow(rect:NSRect) {
        videoLayer!.frame = rect
    }
    
}
