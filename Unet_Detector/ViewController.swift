//
//  ViewController.swift
//  Unet_Detector
//
//  Created by Giovanni Fusco on 10/8/19.
//  Copyright © 2019 Smith-Kettlewell Eye Research Institute. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, Observer {

    
    @IBOutlet weak var capturedImage: UIImageView!
    var currentBuffer: CVPixelBuffer?
    @IBOutlet weak var previewView : UIImageView!
    var detector = Detector(model: ExitSign_augmented().model, cropScaleOption: .centerCrop)
    var camera: CameraController = CameraController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.delegate = self
        // Do any additional setup after loading the view.
    }

    func update(image: UIImage!, cvbuffer: CVPixelBuffer!) {
        capturedImage.image = image
        currentBuffer = Utils.getCVPixelBuffer(image.cgImage!)
        runDetection()
    }
    
    private func runDetection(){
        // To avoid force unwrap in VNImageRequestHandler
        guard let buffer = currentBuffer else { return }
        detector.detect(inputBuffer: buffer) { outputBuffer, _ in
            // Here we are on a background thread
            var previewImage: UIImage?

            defer {
                DispatchQueue.main.async {
                    self.previewView.image = previewImage

                    // Release currentBuffer when finished to allow processing next frame
                    self.currentBuffer = nil


                }
            }

            guard let outBuffer = outputBuffer else {
                return
            }

            // Create UIImage from CVPixelBuffer
            previewImage = UIImage(ciImage: CIImage(cvPixelBuffer: outBuffer))
        }
    }
}

