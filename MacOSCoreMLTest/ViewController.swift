//
//  ViewController.swift
//  MacOSCoreMLTest
//
//  Created by Yasuo Hasegawa on 2019/08/22.
//  Copyright © 2019 Yasuo Hasegawa. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,NSWindowDelegate {
    var cameraView :NSView!
    var debugLb:NSText!
    var macCamera:MacCamera? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraView = NSView()
        self.cameraView.frame = self.view.bounds;
        self.view.addSubview(self.cameraView)
        
        self.debugLb = NSText()
        self.debugLb.frame = NSRect(x: 50.0, y: 50.0, width: 500.0, height: 200.0)
        self.debugLb.textColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.debugLb.backgroundColor = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        self.debugLb.minSize = NSSize(width: 500.0, height: 50.0)
        self.debugLb.font = NSFont.systemFont(ofSize: 30.0)
        self.debugLb.isEditable = false
        self.debugLb.isSelectable = false
        self.debugLb.string = "test"
        self.debugLb.sizeToFit()
        self.view.addSubview(self.debugLb)
        
        macCamera = MacCamera(view: self.cameraView, txt: self.debugLb)
    }

    override func viewWillDisappear() {
        macCamera!.captureSession.stopRunning()
    }
    
    override func viewWillAppear() {
        self.view.window?.delegate = self
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func windowDidResize(_ notification: Notification) {
        macCamera!.resizeWindow(rect: self.view.bounds)
    }
}

