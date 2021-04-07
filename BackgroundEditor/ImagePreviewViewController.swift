//
//  ImagePreviewViewController.swift
//  BackgroundEditor
//
//  Created by cmcmillan on 7/04/21.
//

import Foundation
import UIKit

import VideoToolbox

class ImagePreviewViewController: UIViewController {
    var imageURL: URL// = Bundle.main.url(forResource: "IMG_1311", withExtension: "heic")!
    let previewImageView = UIImageView()
    
    let colours: [UIColor] = [.white, .black, .red, .orange, .yellow, .green, .blue, .purple]
    
    var depthSlider: UISlider = UISlider()

    /// The sample resource currently being displayed.
    var currentSampleImage: SampleImage? = nil

    /// The context used for filtering images.
    let context = CIContext()

    /// A collection of filter methods that can be applied to images.
    lazy var depthFilters = DepthImageFilters(context: context)
    
    var colorCarousel: UICollectionView?
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     previewImageView.topAnchor.constraint(equalTo: view.topAnchor),
                                     previewImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.backgroundColor = .red
        
        depthSlider.translatesAutoresizingMaskIntoConstraints = false
        depthSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(depthSlider)
        NSLayoutConstraint.activate([depthSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                                     depthSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                                     depthSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)])
        
        loadSample(withFileURL: imageURL)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        do {
            try FileManager.default.removeItem(at: imageURL)
        } catch {
            print("Could not remove file at url: \(imageURL)")
        }
    }
    
    func setupColorCarousel() {
        
    }
}

// MARK: Helper Methods
extension ImagePreviewViewController {
    func loadSample(withFileURL url: URL) {
        // Load the sample image
        guard let image = SampleImage(url: url) else { return }
        currentSampleImage = image
        // Update the image view
        updateView()
    }
    
    func updateView() {
        guard let sampleImage = currentSampleImage else { return }
        previewImageView.image = createImage(for: sampleImage)
    }
    
    func createImage(for image: SampleImage) -> UIImage? {
        let focus = CGFloat(depthSlider.value)
        return depthFilters.createSpotlightImage(for: image, withFocus: focus)
    }
}

extension ImagePreviewViewController {
    @objc func sliderValueChanged(_ sender: UISlider) {
        updateView()
    }
}
