//
//  SampleImage.swift
//  BackgroundEditor
//
//  Created by cmcmillan on 7/04/21.
//

import Foundation
import AVFoundation
import UIKit

struct SampleImage {
  let url: URL
  let original: UIImage
  let depthData: UIImage
  let filterImage: CIImage

  init?(url: URL) {
    guard
      let original = UIImage(named: url.lastPathComponent),
      let depthData = SampleImage.depthData(forItemAt: url),
      let filterImage = CIImage(image: original)
      else {
        return nil
    }

    self.url = url
    self.original = original
    self.depthData = depthData
    self.filterImage = filterImage.oriented(original.imageOrientation.cgImageOrientation)
  }

  static func depthData(forItemAt url: URL) -> UIImage? {
    guard let depthDataMap = depthDataMap(forItemAt: url) else { return nil }
    depthDataMap.normalize()
    let ciImage = CIImage(cvPixelBuffer: depthDataMap)
    return UIImage(ciImage: ciImage)
  }

  static func depthDataMap(forItemAt url: URL) -> CVPixelBuffer? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
      return nil
    }

    let cfAuxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
      source,
      0,
      kCGImageAuxiliaryDataTypeDisparity
    )
    
    guard let auxDataInfo = cfAuxDataInfo as? [AnyHashable : Any] else {
      return nil
    }

    let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
    guard
      let properties = cfProperties as? [CFString: Any],
      let orientationValue = properties[kCGImagePropertyOrientation] as? UInt32,
      let orientation = CGImagePropertyOrientation(rawValue: orientationValue)
      else {
        return nil
    }

    guard var depthData = try? AVDepthData(
      fromDictionaryRepresentation: auxDataInfo
    ) else {
      return nil
    }

    if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
      depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
    }

    return depthData.applyingExifOrientation(orientation).depthDataMap
  }
}

private extension UIImage.Orientation {
  var cgImageOrientation: CGImagePropertyOrientation {
    switch self {
    case .up:
      return .up
    case .down:
      return .down
    case .left:
      return .left
    case .right:
      return .right
    case .upMirrored:
      return .upMirrored
    case .downMirrored:
      return .downMirrored
    case .leftMirrored:
      return .leftMirrored
    case .rightMirrored:
      return .rightMirrored
    @unknown default:
      fatalError()
    }
  }
}

extension CVPixelBuffer {
  func normalize() {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
    var minPixel: Float = 1.0
    var maxPixel: Float = 0.0
    
    /// You might be wondering why the for loops below use `stride(from:to:step:)`
    /// instead of a simple `Range` such as `0 ..< height`?
    /// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
    /// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
    /// which is eactly what happens when running this sample project in Debug mode.
    /// If this was a production app then it might not be worth worrying about but it is still
    /// worth being aware of.
    
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    
    let range = maxPixel - minPixel
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        floatBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }
    
    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
  }
}

