//
//  BarellViewController.swift
//  NumbersBarrel
//

import Foundation
import UIKit

@IBDesignable
class BarrelViewController: UIViewController {
    @IBOutlet weak var barrel: BarrelControl!
    @IBOutlet weak var targetValueTextField: UITextField!
    @IBOutlet weak var showTargetValueButton: UIButton!
    @IBOutlet weak var showRandomValueButton: UIButton!
    @IBOutlet weak var stopBarrelAnimationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barrel.barrelsCount = 2
        barrel.currentBarrelValue = barrel.maximumValue
        barrel.translatesAutoresizingMaskIntoConstraints = false
        barrel.targetValueAnimatingStateChangeCallback = { [weak self] state in
            self?.changeEnabledStateForOutsideControls(state: !state)
        }
    }
    
    @IBAction func showTargetValuePressed() {
        if let text = targetValueTextField.text, let v = UInt32(text) {
            barrel.targetBarrelValue = v
            targetValueTextField.resignFirstResponder()
        }
    }
    
    @IBAction func showRandomValuePressed() {
        let randValue = arc4random_uniform(barrel.maximumValue)
        barrel.targetBarrelValue = randValue
        targetValueTextField.text = String(randValue)
        targetValueTextField.resignFirstResponder()
    }
    
    @IBAction func stopButtonPressed() {
        barrel.requestStopBarrelAnimation = true
    }
    
    private func changeEnabledStateForOutsideControls(state: Bool) {
        showRandomValueButton.isEnabled = state
        showTargetValueButton.isEnabled = state
        targetValueTextField.isEnabled = state
    }
    
}
