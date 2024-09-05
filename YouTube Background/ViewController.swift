//
//  ViewController.swift
//  YouTube Background
//
//  Created by paul on 2024/9/5.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var audio_id: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func paly(_ sender: Any) {
        audio_id.text = "";
    }
    
}

