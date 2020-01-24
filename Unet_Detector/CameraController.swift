//
//  CameraController.swift
//  Unet_Detector
//
//  Created by Giovanni Fusco on 10/8/19.
//  Copyright © 2019 Smith-Kettlewell Eye Research Institute. All rights reserved.
//

import UIKit
import AVFoundation

protocol Observer {
    func update(image: UIImage!, cvbuffer: CVPixelBuffer!)
}

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    enum CameraPosition {
        case Front
        case Back
    }
    
    var captureSession = AVCaptureSession()
    
    /// class on which to call the update method when a new frame is available
    var delegate: Observer? = nil
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    
    /// reference to the currently used camera
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    weak var cameraImageBuffer : CVPixelBuffer?
    
    var cameraISO : Float = 0.0
    var cameraShutterSpeed : CMTime = CMTime(seconds: 1, preferredTimescale: 30)
    var cameraExposureBias : Float = 0.0
    var currentFrame : UIImage?

    
    let context = CIContext()
    
    override init(){
        super.init()

        setupDevice()
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized{
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{
                (authorized) in
                    DispatchQueue.main.async{
                            if authorized{
                                self.setupInputOutput()
                            }
                    }
            })
        }
        else{
            setupInputOutput()
        }

    }
    
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    
    func selectCamera(position: CameraPosition){
        switch position {
        case .Front:
            currentCamera = frontCamera
        default:
            currentCamera = backCamera
        }
    }
    
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.startRunning()
            
        } catch {
            print(error)
        }
    }
    
    // TODO: understand what this function does
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            
            let ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 30 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    
    func printCameraInfo(){
        print("")
        print("-------- Camera Parameters ----------")
        print("ISO: ", currentCamera!.iso)
        print(String(format: "Shutter Speed: %.3f", currentCamera!.exposureDuration.seconds))
        print("Exposure Bias: ", currentCamera!.exposureTargetBias)
        //        print("Min Exposure duration: ", currentCamera.ex)
        print("-------------------------------------")
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        cameraISO = currentCamera!.iso
        cameraShutterSpeed = currentCamera!.exposureDuration
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        cameraImageBuffer = cameraImage.pixelBuffer
        let cgImage = self.context.createCGImage(cameraImage, from: cameraImage.extent)!
       
        DispatchQueue.main.sync {
            let image = UIImage(cgImage: cgImage)
            self.currentFrame = image
            delegate?.update(image: image, cvbuffer: cameraImageBuffer)
        }
    }
    
    func getFrame() -> UIImage?{
        return self.currentFrame
    }
    
    func toggleTorch(on: Bool) {
        if currentCamera!.hasTorch {
            do{
                try currentCamera!.lockForConfiguration()
                if on{
                    currentCamera!.torchMode = .on
                    try currentCamera!.setTorchModeOn(level: 1)
                }
                else{
                    currentCamera!.torchMode = .off
                }
                
                currentCamera!.unlockForConfiguration()
            }
            catch{
                print("Torch could not be used")
            }
        }
        else {
            print("Torch is not available")
        }
    }
    
}
