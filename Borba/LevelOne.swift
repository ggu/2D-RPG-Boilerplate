//
//  LevelOne.swift
//  Borba
//
//  Created by Gabriel Uribe on 6/22/15.
//  Copyright (c) 2015 Team Five Three. All rights reserved.
//

/*
==== to be refactored after playable demo/alpha once procedural content is ready to be generated
*/

import SpriteKit
class LevelOne: SKScene, SKPhysicsContactDelegate
{ // rename to .. ? Level? as LevelOne sounds hardcoded, everything should be procedural
  
  // MARK: Properties
  var width: CGFloat?
  var height: CGFloat?
  var player = Player(texture: AssetManager.sharedInstance.heroTexture)
  let cameraNode = SKNode()
  let movementJoystick = SKJoystick(color: UIColor.redColor(), size: CGSizeMake(100, 100))
  let skillJoystick = SKJoystick(color: UIColor.redColor(), size: CGSizeMake(100, 100))
  //let map = MapObject(map: MapBitMasks.Demo)
  let map = MapObject(map: MapBitMasks.Demo)
  let hud: HUD
  
  override init(size: CGSize) {
    hud = HUD(size: size)
    super.init(size: size)
  }
  
  // MARK: Setup functions
  override func didMoveToView(view: SKView)
  {
    setup()
  }
  
  func setup()
  {
    view?.multipleTouchEnabled = true
    print("round one - map one - wave one - start")
    
    physicsWorld.contactDelegate = self
    
    setupProperties()
    
    setupMap()
    
    setupHUD()
    
    setupPlayer()
    
    setupCamera()
    
    setupJoysticks()
  }
  
  func setupHUD()
  {
    hud.zPosition = zPositions.UIObjects
    addChild(hud)
  }
  
  func setupMap()
  {
    self.addChild(map)
    
    if let myParticlePath = NSBundle.mainBundle().pathForResource("Rain", ofType: "sks") {
      let rainParticles = NSKeyedUnarchiver.unarchiveObjectWithFile(myParticlePath) as! SKEmitterNode
      rainParticles.zPosition = zPositions.mapObjects
      rainParticles.position = CGPointMake(width! / 2, height! / 2)
      rainParticles.particlePositionRange = CGVectorMake(self.width!, self.height!)
      addChild(rainParticles)
    }
    
    if let myParticlePath = NSBundle.mainBundle().pathForResource("Fire", ofType: "sks") {
      let fireParticles = NSKeyedUnarchiver.unarchiveObjectWithFile(myParticlePath) as! SKEmitterNode
      fireParticles.zPosition = zPositions.mapObjects
      fireParticles.position = CGPointMake(map.frame.width / 2, map.frame.height / 2)
      map.addChild(fireParticles)
    }
  }
  
  func setupProperties()
  {
    width = scene!.size.width
    height = scene!.size.height
    print("\(width) and \(height)")
  }
  
  func setupPlayer()
  {
    
    player.position = CGPointMake(300, 160)
    player.zPosition = zPositions.mapObjects;
    player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
    player.physicsBody?.affectedByGravity = false
    player.physicsBody?.collisionBitMask = CategoryBitMasks.Map.rawValue
    player.lightingBitMask = 1
    player.shadowCastBitMask = 1
    player.shadowedBitMask = 1
    
    // MARK: TO DO above needs to be put in player class
    map.addChild(player)
  }
  
  func setupCamera()
  {
    cameraNode.name = "camera"
    map.addChild(cameraNode)
  }
  
  func setupJoysticks()
  {
    movementJoystick.position = CGPointMake(100, 100)
    addChild(movementJoystick)
    
    skillJoystick.position = CGPointMake(self.width! - 100, 100)
    addChild(skillJoystick)
  }
  
  // MARK: Touch functions
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
  {
//    for touch in (touches ) {
//      let location = touch.locationInNode(self)
//      
//    }
  }
  
  // MARK: Update functions
  
  override func update(currentTime: CFTimeInterval)
  {
    updatePlayer()
    
  }
  
  func updatePlayer()
  {
    player.handleSpriteMovement(movementJoystick.thumbX, vY: movementJoystick.thumbY, angle: movementJoystick.angle)
    if (skillJoystick.thumbX == 0 && skillJoystick.thumbY == 0)
    {
      player.changeDirection(movementJoystick.angle)
    } else
      
    {
      player.changeDirection(skillJoystick.angle)
      //print(skillJoystick.angle)
      if player.canUseSpell() {
        let spellSprite = player.handlePlayerSpellCast()
        spellSprite.position = player.position
        let moveAction = SKAction.moveByX(skillJoystick.thumbX * 100, y: skillJoystick.thumbY * 100, duration: getDistance(spellSprite.position, point2: CGPointMake(spellSprite.position.x + skillJoystick.thumbX * 100, spellSprite.position.y + skillJoystick.thumbY * 100)) / MissileSpeeds.fireball)
        let removeAction = SKAction.removeFromParent()
        let completeAction = SKAction.sequence([moveAction, removeAction])
        
        spellSprite.runAction(completeAction)
        map.addChild(spellSprite)
      }
      //map.addChild(player.activeSpell!)
      
    }
  }
  
  // MARK: Physics functions
  
  override func didSimulatePhysics()
  {
    updateCamera()
  }
  
  func didBeginContact(contact: SKPhysicsContact)
  {
    print("damaged the enemy")
  }
  
  func updateCamera()
  {
    let yBoundary = map.size.height/2 - frame.size.height/2;
    let xBoundary = map.size.width/2 - frame.size.width/2;
    
    if (player.position.x > frame.size.width/2 && player.position.x < (map.size.width - frame.size.width/2))
    {
      self.cameraNode.position = CGPointMake(player.position.x - frame.size.width/2, cameraNode.position.y);
    }
    if (player.position.y > frame.size.height/2 && player.position.y < (map.size.height - frame.size.height/2))
    {
      self.cameraNode.position = CGPointMake(cameraNode.position.x, player.position.y - frame.size.height/2);
    }
    
    centerOnNode(cameraNode)
    
    if (((cameraNode.position.y < -1 * yBoundary) || (cameraNode.position.y > yBoundary)) ||
      ((cameraNode.position.x < -1 * xBoundary) || (cameraNode.position.x > xBoundary)))
    {
      //player.hidden = YES
    } else if (((!(self.cameraNode.position.y < -1*yBoundary) || (!(self.cameraNode.position.y > yBoundary))) && ((!(self.cameraNode.position.x < -1*xBoundary)) || (self.cameraNode.position.x > xBoundary))))
    {
      //player.hidden = YES
    }
  }
  
  func centerOnNode(node: SKNode)
  {
    let cameraPositionInScene: CGPoint = node.scene!.convertPoint(node.position, fromNode: node.parent!)
    
    let xPos = node.parent!.position.x - cameraPositionInScene.x
    let yPos = node.parent!.position.y - cameraPositionInScene.y
    
    node.parent?.position = CGPointMake(xPos, yPos);
  }
  
  // MARK: Actions
  func buttonTapped(type: ButtonType)
  {
    /* this should contain the first level of buttons available on the screen (e.g. 'Menu', 'Attack'), which all lead to separate views that are managed independently of this function */
    switch type
    {
    case ButtonType.MainMenuPlay:
      print("tapped play button")
      // segue into main level
    case ButtonType.MainMenuSettings:
      print("tapped settings button")
      // segue into settings page
      //    default:
      //      print("tapped untagged button")
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: Helpers
  func getRandomNumber(upperLimit: CGFloat) -> CGFloat
  {
    return CGFloat(arc4random_uniform(UInt32(upperLimit + 1)))
  }
  
  func getDistance(point1: CGPoint, point2: CGPoint) -> Double {
    return Double(sqrt(pow((point1.x - point2.x), 2) + pow((point1.y - point2.y), 2)))
  }
}