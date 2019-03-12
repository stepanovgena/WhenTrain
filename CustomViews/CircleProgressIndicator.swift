//
//  CircleProgressIndicator.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 12/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit

@IBDesignable class CircleProgressIndicator: UIView {
  
  let indicatorColor = UIColor.black
  
  override func draw(_ rect: CGRect) {
    
    let circlePath = UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 20, height: 20))
    indicatorColor.setStroke()
    circlePath.lineWidth = 5.0
    circlePath.stroke()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = circlePath.cgPath
    
    shapeLayer.strokeEnd = 0
    shapeLayer.lineWidth = 3
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.fillColor = UIColor.clear.cgColor
    
    self.layer.addSublayer(shapeLayer)
    
    let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
    strokeStartAnimation.fromValue = 0
    strokeStartAnimation.toValue = 1
    
    let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
    strokeEndAnimation.fromValue = 0
    strokeEndAnimation.toValue = 1.5
    
    let animationGroup = CAAnimationGroup()
    animationGroup.duration = 1
    animationGroup.repeatCount = .infinity
    animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
    
    shapeLayer.add(animationGroup, forKey: nil)
  }
}
