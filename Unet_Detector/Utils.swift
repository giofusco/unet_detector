//
//  Utils.swift
//  Unet_Detector
//
//  Created by Giovanni Fusco on 10/8/19.
//  Copyright © 2019 Smith-Kettlewell Eye Research Institute. All rights reserved.
//

import Foundation
import UIKit

class Utils{

static func getCVPixelBuffer(_ image: CGImage) -> CVPixelBuffer? {
    let imageWidth = Int(image.width)
    let imageHeight = Int(image.height)

    let attributes : [NSObject:AnyObject] = [
        kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
        kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
    ]

    var pxbuffer: CVPixelBuffer? = nil
    CVPixelBufferCreate(kCFAllocatorDefault,
                        imageWidth,
                        imageHeight,
                        kCVPixelFormatType_32ARGB,
                        attributes as CFDictionary?,
                        &pxbuffer)

    if let _pxbuffer = pxbuffer {
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(_pxbuffer, flags)
        let pxdata = CVPixelBufferGetBaseAddress(_pxbuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGContext(data: pxdata,
                                width: imageWidth,
                                height: imageHeight,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(_pxbuffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        if let _context = context {
            _context.draw(image, in: CGRect.init(x: 0, y: 0, width: imageWidth, height: imageHeight))
        }
        else {
            CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
            return nil
        }

        CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
        return _pxbuffer;
    }

    return nil
}
}
