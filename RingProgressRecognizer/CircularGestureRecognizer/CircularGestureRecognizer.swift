//
//  CircularGestureRecognizer.swift
//  RingProgressRecognizer
//
//  Created by Dennis Merli on 24/02/18.
//  Copyright © 2018 Dennis Merli. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class CircularGestureRecognizer: UIGestureRecognizer {
    
    /// rotation in radians
    fileprivate(set) open var rotation: CGFloat = 0.0
    
    /// clockwise - true  counter-clockwise - false
    fileprivate(set) open var clockwiseDirection: Bool = true
    
    /// distance from anchor point
    fileprivate(set) open var radius: Float? = 0.0
    
    /// ignore event from center in %
    fileprivate(set) open var ignoreDistanceFromCenter: CGFloat = 10.0
    
    ///
    fileprivate(set) var controlView: UIView!
    
    /// rotation center
    open var anchor: CGPoint?
    
    fileprivate var prevTouch: UITouch?
    
    fileprivate lazy var center: CGPoint = {
        guard let anchor = self.anchor else {  return CGPoint(x: self.controlView.bounds.midX, y: self.controlView.bounds.midY)}
        return anchor
    }()
    
    // MARK: - Initializers
    
    public init(target: Any?, action: Selector?, to controlView: UIView) {
        super.init(target: target, action: action)
        
        self.controlView = controlView
        anchor = CGPoint(x: controlView.bounds.midX, y: controlView.bounds.midY)
    }
    
    // MARK: - LifeCycle
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        guard touches.count == 1 else {
            state = .failed
            return
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard let touch = touches.first else { return }
        
        radius = calculateDistance(fromCenter: touch.location(in: controlView))
        
        let currentAngle = getTouchAngle(touch.location(in: controlView))
        let previousAngle = getTouchAngle(touch.previousLocation(in: controlView))
        
        rotation = currentAngle - previousAngle
        
        if rotation > .pi {
            rotation -= .pi*2
        } else if rotation < -.pi {
            rotation += .pi*2
        }
        
        clockwiseDirection = currentAngle - previousAngle > 0
        state = .changed
        prevTouch = touch
    }
    
    func getTouchAngle(_ touch: CGPoint) -> CGFloat {
        
        guard let radius = radius else { return -1 }
        // ignore event near center, 10% of width default
        if radius < Float(controlView.bounds.width/ignoreDistanceFromCenter) && state == .changed {
            return -1
        }
        
        let x: CGFloat = touch.x - center.x
        let y: CGFloat = -(touch.y - center.y)
        
        let arctan: CGFloat = CGFloat(atanf(Float(x / y)))
        
        switch (x, y) {
        case let (x, y) where y == 0 && x > 0:
            return .pi / 2
        case let (_, y) where y == 0:
            return 3 * .pi / 2
        case let (x, y) where x >= 0 && y > 0:
            return arctan
        case let (x, y) where x < 0 && y > 0:
            return arctan + 2 * .pi
        case let (x, y) where x <= 0 && y < 0:
            return arctan + .pi
        case let (x, y) where x > 0 && y < 0:
            return arctan + .pi
        default:
            return -1
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
    }
    
    fileprivate func calculateDistance(fromCenter point: CGPoint) -> Float {
        
        let dx: CGFloat = CGFloat(point.x - center.x)
        let dy: CGFloat = CGFloat(point.y - center.y)
        return sqrt(Float(dx * dx + dy * dy))
    }
}
