//
//  ViewController.swift
//  BackgroundEditor
//
//  Created by cmcmillan on 7/04/21.
//

import UIKit

class ViewController: UIViewController {
    var initialLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if initialLoad {
            navigationController?.pushViewController(ImagePreviewViewController(imageURL: nil), animated: true)
        }
        initialLoad = false
    }
}
