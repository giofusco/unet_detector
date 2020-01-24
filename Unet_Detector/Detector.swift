//
//  Detector.swift
//  Unet_Detector
//
//  Created by Giovanni Fusco on 10/8/19.
//  Copyright © 2019 Smith-Kettlewell Eye Research Institute. All rights reserved.
//

import CoreML
import Vision

public class Detector {
    
    private var mlModel: MLModel
    private var cropScaleOption: VNImageCropAndScaleOption
    
    private let visionQueue = DispatchQueue(label: "org.ski.Unet_Detector.visionQueue")
    
    private lazy var predictionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: mlModel)
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = self.cropScaleOption
            return request
        } catch {
            fatalError("Error loading Vision ML Model: \(error)")
        }
    }()
    
    init(model: MLModel, cropScaleOption: VNImageCropAndScaleOption) {
        self.mlModel = model
        self.cropScaleOption = cropScaleOption
    }
    
    
    public func detect(inputBuffer: CVPixelBuffer, completion: @escaping (_ outputBuffer: CVPixelBuffer?, _ error: Error?) -> Void) {
        // Right orientation because the pixel data for image captured by an iOS device is encoded in the camera sensor's native landscape orientation
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: inputBuffer, orientation: .up)

        // We perform our CoreML Requests asynchronously.
        visionQueue.async {
            // Run our CoreML Request
            do {
                try requestHandler.perform([self.predictionRequest])

                guard let observation = self.predictionRequest.results?.first as? VNPixelBufferObservation else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
                }
                // The resulting image (mask) is available as observation.pixelBuffer
                completion(observation.pixelBuffer, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
