//
//  LevelBar.swift
//  Borba
//
//  Created by Gabriel Uribe on 8/2/15.
//  Copyright (c) 2015 Team Five Three. All rights reserved.
//

import SpriteKit

class LevelBar: SKSpriteNode
{
  var levelLabel = SKLabelNode(text: "1")
  init(width: CGFloat, height: CGFloat) {
    super.init(texture: nil, color: UIColor.blackColor(), size: CGSizeMake(40, 16))
    setup(width, height: height)
  }
  
  func setup(width: CGFloat, height: CGFloat)
  {
    let yPos = height - size.height/2
    position = CGPointMake(280, yPos)
    zPosition = 10
    
    levelLabel.fontSize = 12
    levelLabel.fontName = "AmericanTypewriter"
    levelLabel.fontColor = UIColor.whiteColor()
    levelLabel.position = CGPointMake(levelLabel.position.x, -4)
    addChild(levelLabel)
  }
  
  func setLevel()
  {
    // should add an animation to this
    
  }
  
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
  }
}