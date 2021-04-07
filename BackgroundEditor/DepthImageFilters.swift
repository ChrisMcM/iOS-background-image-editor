//
//  DepthImageFilters.swift
//  BackgroundEditor
//
//  Created by cmcmillan on 7/04/21.
//

import Foundation

import UIKit

enum MaskParams {
  static let slope: CGFloat = 4.0
  static let width: CGFloat = 0.1
}

class DepthImageFilters {
  var context: CIContext
  
  init(context: CIContext) {
    self.context = context
  }
  
  func createMask(for image: SampleImage, withFocus focus: CGFloat) -> CIImage {
    let s1 = MaskParams.slope
    let s2 = -MaskParams.slope
    let filterWidth =  2 / MaskParams.slope + MaskParams.width
    let b1 = -s1 * (focus - filterWidth / 2)
    let b2 = -s2 * (focus + filterWidth / 2)

    let depthImage = image.depthData.ciImage!
    let mask0 = depthImage
      .applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: s1, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: s1, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: s1, w: 0),
        "inputBiasVector": CIVector(x: b1, y: b1, z: b1, w: 0)])
      .applyingFilter("CIColorClamp")

    let mask1 = depthImage
      .applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: s2, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: s2, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: s2, w: 0),
        "inputBiasVector": CIVector(x: b2, y: b2, z: b2, w: 0)])
      .applyingFilter("CIColorClamp")

    let combinedMask = mask0.applyingFilter("CIDarkenBlendMode", parameters: [
      "inputBackgroundImage": mask1
    ])
    let mask = combinedMask.applyingFilter("CIBicubicScaleTransform", parameters: [
      "inputScale": image.depthDataScale
    ])

    return mask
  }

  func createSpotlightImage(
    for image: SampleImage,
    withFocus focus: CGFloat
  ) -> UIImage? {
    let mask = createMask(for: image, withFocus: focus)
    let output = image.filterImage.applyingFilter("CIBlendWithMask", parameters: [
      "inputMaskImage": mask
    ])

    guard let cgImage = context.createCGImage(output, from: output.extent) else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }
}

private extension SampleImage {
  var depthDataScale: CGFloat {
    let maxToDim = max(original.size.width, original.size.height)
    let maxFromDim = max(depthData.size.width, depthData.size.height)
    return maxToDim / maxFromDim
  }
}
