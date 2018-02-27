//
//  RingView.swift
//  RingProgressRecognizer
//
//  Created by Dennis Merli on 24/02/18.
//  Copyright © 2018 Dennis Merli. All rights reserved.
//

import Foundation
import UIKit

protocol RingViewDelegate: class {
    func didUpdateValue(view: RingView, value : Double)
}

@IBDesignable
public class RingView: UIView {
    
    // MARK: Line Cap
    public enum LineCap: Int {
        case round, butt, square
        
        public func style() -> CGLineCap {
            switch self {
            case .round:
                return .round
            case .butt:
                return .butt
            case .square:
                return .square
            }
        }
    }
    
    // MARK: Properties
    weak var delegate: RingViewDelegate?
    private var circleHandle: UIView?
    var lineCap: LineCap = .round
    
    
    var progress: Float = 0 {
        didSet {
            if progress < 0 {
                progress = 0
            } else if progress > 1 {
                progress = 1
            } else {
                updateProgressStroke()
            }
        }
    }
  
    fileprivate var value: Double = 22 {
        didSet {
            switch value {
            case let x where x < minValue:
                self.value = minValue
            case let x where x > maxValue:
                self.value = maxValue
            default:
                break
            }
            let calculatedprogress = Float((value - minValue) / (maxValue - minValue))
            self.progress = calculatedprogress
            delegate?.didUpdateValue(view: self, value: self.value)
        }
    }
    
    private var radiansCount: CGFloat = 10
    fileprivate var bearing: CGFloat = 0.0
    fileprivate var oldBearing: CGFloat = 0.0
    public var  valueVariation: Double = 1 {
        didSet {
            updateProgressStroke()
        }
    }
    // MARK: Inspectable Properties
    @IBInspectable let circleHandleSize: Double = 17.0
    @IBInspectable var isCircleHandleEnabled: Bool = true
    @IBInspectable public var minValue: Double = 10 {
        didSet {
            updateProgressStroke()
        }
    }
    
    @IBInspectable public var maxValue: Double = 100 {
        didSet {
            updateProgressStroke()
        }
    }
    
    @IBInspectable public var progressTintColor: UIColor? = UIColor.blue {
        didSet {
            circleHandle?.backgroundColor = progressTintColor
            updateProgressStroke()
        }
    }
    
    @IBInspectable public var trackWidth: CGFloat = 2 {
        didSet {
            updateProgressStroke()
        }
    }
    
    @IBInspectable public var progressWidth: CGFloat = 6 {
        didSet {
            updateProgressStroke()
        }
    }
    
    @IBInspectable public var trackTintColor: UIColor? = UIColor.darkGray {
        didSet {
            updateProgressStroke()
        }
    }
   
   // MARK: Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupCircleView()
        setupGestureRecognizer()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupCircleView()
        setupGestureRecognizer()
    }
    
    public init(frame: CGRect, progress: Float = 0, trackWidth: CGFloat = 2, progressWidth: CGFloat = 2,
                trackTintColor: UIColor, progressTintColor: UIColor) {
        super.init(frame: frame)
        self.trackWidth = trackWidth
        self.progressWidth = progressWidth
        self.trackTintColor = trackTintColor
        self.progressTintColor = progressTintColor
        self.progress = progress
        setupCircleView()
        setupGestureRecognizer()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupCircleView()
        setupGestureRecognizer()
    }
    
    private func setupGestureRecognizer() {
        let gesture = CircularGestureRecognizer(target: self, action: #selector(rotationAction(_:)), to: self)
        value = 0.0
        gesture.delegate = self
        self.addGestureRecognizer(gesture)
    }
    
    private func setupCircleView() {
        if isCircleHandleEnabled {
            setupCircleHandle()
        }
    }
    
    private func setupCircleHandle() {
        circleHandle = UIView(frame: CGRect(x: 0, y: 0, width: circleHandleSize, height: circleHandleSize))
        guard let circleHandle = self.circleHandle else {
            return
        }
        circleHandle.contentMode = UIViewContentMode.scaleAspectFill
        circleHandle.clipsToBounds = true
        circleHandle.layer.cornerRadius = CGFloat(circleHandleSize / 2)
        circleHandle.layer.masksToBounds = true
        circleHandle.backgroundColor = progressTintColor
        circleHandle.tintColor = progressTintColor
        self.insertSubview(circleHandle, aboveSubview: self)
    }
    
    public override func layoutSubviews() {
        updateProgressStroke()
    }
    
    // MARK: Update Progress
    /// Set value
    func setValue(newValue: Double?) {
        guard let newValue = newValue else {
            return
        }
        self.value = newValue
    }
    private func updateProgressStroke() {
       setNeedsDisplay()
    }
    
    override public func draw(_ rect: CGRect) {
        let bounds: CGRect = self.bounds
        let radius = (min(bounds.size.width, bounds.size.height) / 2.0)
        setTrackPath(radius: radius)
        setProgressPath(radius: radius)
        if isCircleHandleEnabled {
            moveHandle(value: self.progress)
        }
    }
    
    private func setProgressPath(radius: CGFloat) {
        let path: UIBezierPath = UIBezierPath()
        let angle = angleFromValue(value: self.progress)
        var center = CGPoint()
        center.x = bounds.origin.x + bounds.size.width / 2.0
        center.y = bounds.origin.y + bounds.size.height / 2.0
        let radian = CGFloat(angle) * CGFloat.pi / 180
        UIView.animate(withDuration: 1, animations: {
            path.addArc(withCenter: center, radius: radius - 5, startAngle: -90 * CGFloat.pi / 180, endAngle: radian, clockwise: true)
        })
        progressTintColor?.setStroke()
        path.lineWidth = progressWidth
        path.lineCapStyle = lineCap.style()
        path.stroke()
    }
    
    private func setTrackPath(radius: CGFloat) {
        let path2: UIBezierPath = UIBezierPath()
        path2.lineWidth = trackWidth
        var center = CGPoint()
        center.x = bounds.origin.x + bounds.size.width / 2.0
        center.y = bounds.origin.y + bounds.size.height / 2.0
        path2.addArc(withCenter: center, radius: radius - 5, startAngle: 0.0, endAngle: 360 * CGFloat.pi / 180, clockwise: true)
        trackTintColor?.setStroke()
        path2.stroke()
    }
    
    private func moveHandle(value: Float) {
        let radius = (min(bounds.size.width, bounds.size.height) / 2.0)
        let angle = angleFromValue(value: value)
        var center = CGPoint()
        center.x = bounds.origin.x + bounds.size.width / 2.0
        center.y = bounds.origin.y + bounds.size.height / 2.0
        guard let circleHandle = self.circleHandle else {
            return
        }
        let origin = self.point(angle: CGFloat(angle), radius: radius - 5, centerX: center.x, centerY: center.y)
        let newCoordinate = CGPoint(x: origin.x - circleHandle.frame.width / 2, y: origin.y - circleHandle.frame.height / 2)
        circleHandle.frame.origin = newCoordinate
    }
    
    private func angleFromValue(value: Float) -> Float {
        var angle: Float = 0
        angle = -90 + (360 * value / 1)
        return angle
    }

    // MARK: Math methods
    
    private func circleRadiusWithStrokeWidth(strokeWidth: CGFloat, withinSize size: CGSize) -> CGFloat {
        let width = size.width
        let height = size.height
        
        let length = width > height ? height : width
        return (length - strokeWidth) / 2
    }
    
    private func circleFrameWithStrokeWidth(strokeWidth: CGFloat, withRadius radius: CGFloat, withinSize size: CGSize) -> CGRect {
        let width = size.width
        let height = size.height
        
        let x: CGFloat
        let y: CGFloat
        
        if width > height {
            y = strokeWidth / 2
            x = (width / 2) - radius
        } else {
            x = strokeWidth / 2
            y = (height / 2) - radius
        }
        
        let diameter = 2 * radius
        return CGRect(x: x, y: y, width: diameter, height: diameter)
    }
    
    private func point(angle: CGFloat, radius: CGFloat, centerX: CGFloat, centerY: CGFloat) -> CGPoint {
        let radian = angle * CGFloat.pi / 180
        let x = (cos(radian) * radius + centerX)
        let y = sin(radian) * radius + centerY
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: Gesture recognizer handlers
    
    @objc private func rotationAction(_ sender: CircularGestureRecognizer) {
        switch sender.state {
        case .began:
            bearing = 0.0
            gestureHandler(sender)
        case .changed:
            gestureHandler(sender)
        default:
            break
        }
    }
    
    private func gestureHandler(_ sender: CircularGestureRecognizer) {
        bearing +=  radiansCount * sender.rotation / .pi
        
        if round(bearing) > oldBearing {
            value += valueVariation
        } else if round(bearing) < oldBearing {
            value -= valueVariation
        }
        oldBearing = round(bearing)
    }
}

extension RingView : UIGestureRecognizerDelegate {
    
}

