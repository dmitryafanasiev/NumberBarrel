//
//  BarellControl.swift
//  NumbersBarrel
//

import Foundation
import UIKit

protocol BarrelValueChangeProtocol {
    func decreaseBy(value: UInt32, animated: Bool)
    func increaseBy(value: UInt32, animated: Bool)
}

protocol AnimatableViewValueChangeProtocol {
    var value: AnimatableViewValues { get set }
    func decrease()
    func increase()
    func force(value: AnimatableViewValues)
}

enum AnimatableViewValues: UInt32 {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    
    static let allValues = [zero, one, two, three, four, five, six, seven, eight, nine]
}

@IBDesignable
class BarrelControl : UIControl, BarrelValueChangeProtocol {
    
    // Current value for Barrel
    // Change this if you don't need animated value change
    @IBInspectable var currentBarrelValue: UInt32 {
        get {
            return currentValue
        }
        set {
            if !isBetweenMinMax(value: newValue) {
                if newValue > maximumValue {
                    currentValue = maximumValue
                } else if newValue < minimumValue {
                    currentValue = minimumValue
                }
            } else {
                currentValue = newValue
            }

            applyValue(value: currentValue)
        }
    }
    
    // Count of digits on Barrel
    // value from 0 to 5
    @IBInspectable var barrelsCount: UInt32 {
        get {
            return countOfBarrels
        }
        set {
            if newValue >= 0 && newValue <= 5 {
                countOfBarrels = newValue
            }
        }
    }
    
    fileprivate var labelsStackView: UIStackView? {
        get {
            return subviews.first as? UIStackView
        }
    }
    
    fileprivate var currentValue: UInt32 = 0
    
    // Target value for Barrel
    // Change this if you need animated value change
    var targetBarrelValue: UInt32 = 0 {
        didSet {
            requestStopBarrelAnimation = false
            if isBetweenMinMax(value: targetBarrelValue) {
                if targetBarrelValue > currentValue {
                    increaseBy(value: targetBarrelValue - currentValue, animated: true)
                } else if targetBarrelValue < currentValue {
                    decreaseBy(value: currentValue - targetBarrelValue, animated: true)
                }
            } else {
                if targetBarrelValue > maximumValue {
                    currentBarrelValue = maximumValue
                } else {
                    currentBarrelValue = minimumValue
                }
            }
        }
    }
    
    var targetValueAnimatingStateChangeCallback: ((Bool)->())?
    var requestStopBarrelAnimation: Bool = false
    
    fileprivate var countOfBarrels: UInt32 = 0 {
        didSet {
            if oldValue == countOfBarrels {
                return
            }
            minimumValue = 0
            maximumValue = UInt32(pow(10.0, Double(countOfBarrels)) - 1.0)
            
            if oldValue < countOfBarrels {
                let diff = countOfBarrels - oldValue
                for _ in 0..<diff {
                    let label = getLabel(value: String(AnimatableViewValues.allValues.first!.rawValue))
                    let previousDigit = (labelsStackView?.arrangedSubviews as? [AnimatableView])?.last
                    label.previousDigit = previousDigit
                    labelsStackView?.addArrangedSubview(label)
                }
            } else if oldValue > countOfBarrels {
                let diff = oldValue - countOfBarrels
                for _ in 0..<diff {
                    if let last = labelsStackView?.arrangedSubviews.last {
                        last.removeFromSuperview()
                    }
                }
            }
            
            if !isBetweenMinMax(value: currentBarrelValue) {
                if currentBarrelValue > maximumValue {
                    currentBarrelValue = maximumValue
                } else {
                    currentBarrelValue = minimumValue
                }
            }
        }
    }
    
    
    private(set) var maximumValue: UInt32 = 0
    private(set) var minimumValue: UInt32 = 0
    fileprivate var barrelIsAnimating = false {
        didSet {
            if oldValue != barrelIsAnimating {
                self.targetValueAnimatingStateChangeCallback?(barrelIsAnimating)
                self.layer.borderColor = barrelIsAnimating ? UIColor.red.cgColor : UIColor.green.cgColor
            }
        }
    }
    
    
    // MARK: - FUNCTIONS
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customizeUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        customizeUI()
    }
    
    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if self.subviews.count == 0 {
            return loadNib()
        }
        return self
    }
    
    fileprivate func loadNib() -> BarrelControl {
        return UINib(nibName: "BarrelControl", bundle: nil).instantiate(withOwner: nil, options: nil).first as! BarrelControl
    }
    
    private func isBetweenMinMax(value: UInt32) -> Bool {
        if value >= minimumValue && value <= maximumValue {
            return true
        }
        
        return false
    }
    
    private func customizeUI() {
        layer.borderColor = UIColor.green.cgColor
        layer.borderWidth = 1
    }
    
    private func applyValue(value: UInt32) {
        var valueToString = String(value)
        if let stack = labelsStackView?.arrangedSubviews as? [AnimatableView] {
            for i in 0..<stack.count {
                let view = stack[stack.count - i - 1]
                if let lastSymbol = valueToString.characters.last?.description {
                    valueToString.characters.removeLast()
                    if let v = UInt32(lastSymbol), let vv = AnimatableViewValues(rawValue: v) {
                        view.force(value: vv)
                    }
                } else {
                    view.force(value: .zero)
                }
            }
        }
    }
    
    private func getLabel(value: String) -> AnimatableView {
        return AnimatableView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40)))
    }
    
    private func changeCurrentValueToTargetValueRepeatedlyIfPossible() {
        if !barrelIsAnimating {
            barrelIsAnimating = true
            
            Timer.scheduledTimer(withTimeInterval:  AnimatableView.animationDuration + 0.01, repeats: true) { timer in
                if self.requestStopBarrelAnimation || self.currentValue == self.targetBarrelValue {
                    self.requestStopBarrelAnimation = false
                    self.barrelIsAnimating = false
                    timer.invalidate()
                } else {
                    let lastDigit = (self.labelsStackView?.arrangedSubviews as? [AnimatableView])?.last
                    if self.currentValue < self.targetBarrelValue {
                        self.currentValue += 1
                        lastDigit?.increase()
                    } else {
                        self.currentValue -= 1
                        lastDigit?.decrease()
                    }
                }
            }.fire()
        }
    }
    
    // MARK: - BarrelValueChangeProtocol
    
    func increaseBy(value: UInt32, animated: Bool) {
        if !animated {
            currentBarrelValue += value
        } else {
            changeCurrentValueToTargetValueRepeatedlyIfPossible()
        }
    }
    
    func decreaseBy(value: UInt32, animated: Bool) {
        if !animated {
           currentBarrelValue -= value
        } else {
            changeCurrentValueToTargetValueRepeatedlyIfPossible()
        }
    }
    
    // MARK: - ANIMATABLE VIEW CLASS
    
    class AnimatableView: UIView, AnimatableViewValueChangeProtocol {
        var value: AnimatableViewValues = .zero
        static let animationDuration = 0.2
        weak var previousDigit: AnimatableView?
        
        var isAnimating: Bool {
            get {
                return incomingLabel != nil
            }
        }
        private(set) var label: UILabel?
        private(set) var incomingLabel: UILabel?
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            commonInit()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        private func commonInit() {
            label = UILabel(frame: bounds)
            label?.text = String(value.rawValue)
            label?.textAlignment = .center
            addSubview(label!)
        }
        
        override var intrinsicContentSize: CGSize {
            get {
                return CGSize(width: 40, height: 40)
            }
        }
        
        private func animate(up: Bool) {
            if incomingLabel == nil {
                var newFrame = CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height), size: bounds.size)
                if !up {
                    newFrame = CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y - bounds.size.height), size: bounds.size)
                }
                let newLabel = UILabel(frame: newFrame)
                newLabel.text = String(value.rawValue)
                newLabel.textAlignment = .center
                newLabel.layer.opacity = 0.4
                addSubview(newLabel)
                incomingLabel = newLabel
                
                UIView.animate(withDuration: AnimatableView.animationDuration, animations: {
                    if up {
                        self.label?.center.y -= self.bounds.size.height
                        self.incomingLabel?.center.y -= self.bounds.size.height
                    } else {
                        self.label?.center.y += self.bounds.size.height
                        self.incomingLabel?.center.y += self.bounds.size.height
                    }
                    self.incomingLabel?.layer.opacity = 1
                    self.label?.layer.opacity = 0
                }, completion: { completed in
                    if completed {
                        self.label?.removeFromSuperview()
                        self.label = self.incomingLabel
                        self.incomingLabel = nil
                    }
                })
            }
        }
        
        func increase() {
            if value == AnimatableViewValues.allValues.last {
                value = AnimatableViewValues.allValues.first!
                previousDigit?.increase()
            } else {
                value = AnimatableViewValues(rawValue: value.rawValue + 1)!
            }
            animate(up: false)
        }
        
        func decrease() {
            if value == AnimatableViewValues.allValues.first {
                value = AnimatableViewValues.allValues.last!
                previousDigit?.decrease()
            } else {
                value = AnimatableViewValues(rawValue: value.rawValue - 1)!
            }
            animate(up: true)
        }
        
        func force(value: AnimatableViewValues) {
            self.value = value
            label?.text = String(value.rawValue)
        }
    }
}
