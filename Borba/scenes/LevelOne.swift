//
//  LevelOne.swift
//  Borba
//
//  Created by Gabriel Uribe on 6/22/15.
//  Copyright (c) 2015 Team Five Three. All rights reserved.
//

import SpriteKit

final class LevelOne: SKScene, SKPhysicsContactDelegate {
  var width: CGFloat
  var height: CGFloat
  let player = Player()
  let cameraNode = SKNode()
  let map = MapObject(map: MapObject.Level.Demo)
  let hud: HUD
  var enemies: [Enemy] = []
  var playerEnemyInContact = false
  var enemiesInContact: [Enemy] = []
  var enemiesKilled = 0
  var playerModel = PlayerModel.newGame()
  var enemiesModel = EnemiesModel.newGame()
  var enemyGenerator = EnemyGenerator.newGame()
  
  override init(size: CGSize) {
    hud = HUD(size: size)
    width = size.width
    height = size.height
    super.init(size: size)
  }
  
  // MARK: Setup functions
  override func didMoveToView(view: SKView) {
    setup()
  }
  
  private func setup() {
    playerModel.delegate = self
    enemiesModel.delegate = self
    view?.multipleTouchEnabled = true
    physicsWorld.contactDelegate = self
    
    setupProperties()
    setupMap()
    setupHUD()
    setupPlayer()
    runAction(SKAction.repeatActionForever(SKAction.playSoundFileNamed(SoundFile.Music, waitForCompletion: true)))
    setupCamera()
    loadEnemies()
  }
  
  private func loadEnemies() {
    let enemies = enemyGenerator.generateEnemies()
    spawnEnemies(enemies)
  }
  
  private func setupHUD() {
    hud.zPosition = zPositions.UIObjects
    hud.delegate = self
    addChild(hud)
  }
  
  private func setupMap() {
    self.addChild(map)
  }
  
  private func setupProperties() {
    width = scene!.size.width
    height = scene!.size.height
  }
  
  private func setupPlayer() {
    map.addChild(player)
  }
  
  private func setupCamera() {
    cameraNode.name = "camera"
    map.addChild(cameraNode)
  }
  
  // MARK: - Update
  
  override func update(currentTime: CFTimeInterval) {
    updatePlayerState()
    updateEnemies()
    
    updatePlayerEnemyConditions()
  }
  
  // MARK: - Physics functions
  
  override func didSimulatePhysics() {
    updateCamera()
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    let bodyA = contact.bodyA
    let bodyB = contact.bodyB
    
    handleGameObjectContact(bodyA, bodyB: bodyB)
    hud.updateHealthFrame(playerModel.getRemainingHealthFraction())
  }
  
  func didEndContact(contact: SKPhysicsContact) {
    let bodyA = contact.bodyA
    let bodyB = contact.bodyB
    
    if bodyA.categoryBitMask == CategoryBitMasks.Hero {
      if let enemy = bodyB.node as? Enemy {
        contactEnded(enemy)
      }
    } else if bodyB.categoryBitMask == CategoryBitMasks.Hero {
      if let enemy = bodyA.node as? Enemy {
        contactEnded(enemy)
      }
    }
  }
  
  private func contactEnded(enemy: Enemy) {
    enemy.inContactWithPlayer = false
    removeEnemyFromEnemiesInContact(enemy)
    
    if !enemiesAreInContact() {
      playerEnemyInContact = false
    }
  }
  
  private func handleGameObjectContact(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody) {
    if bodyA.categoryBitMask == CategoryBitMasks.Hero {
      if let enemy = bodyB.node as? Enemy {
        handlePlayerAndEnemyContact(enemy)
      }
    } else if bodyB.categoryBitMask == CategoryBitMasks.Hero {
      if let enemy = bodyA.node as? Enemy {
        handlePlayerAndEnemyContact(enemy)
      }
    } else if bodyA.categoryBitMask == CategoryBitMasks.Spell {
      let spell = bodyA.node as? SpellNode
      spell?.fizzleOut()
      if let enemy = bodyB.node as? Enemy {
        onSpellHitEffects(enemy.position)
        handleSpellAndEnemyContact(enemy)
      }
    } else if bodyB.categoryBitMask == CategoryBitMasks.Spell {
      let spell = bodyB.node as? SpellNode
      spell?.fizzleOut()
      if let enemy = bodyA.node as? Enemy {
        onSpellHitEffects(enemy.position)
        handleSpellAndEnemyContact(enemy)
      }
    } else if bodyA.categoryBitMask == CategoryBitMasks.PenetratingSpell {
      if let enemy = bodyB.node as? Enemy {
        handleSpellAndEnemyContact(enemy)
      }
    } else if bodyB.categoryBitMask == CategoryBitMasks.PenetratingSpell {
      if let enemy = bodyA.node as? Enemy {
        handleSpellAndEnemyContact(enemy)
      }
    }
  }
  
  // MARK: - Player and Enemy High Level Logic
  
  private func updateEnemies() {
    for enemy in enemies {
      let distance = getDistance(enemy.position, point2: player.position)
      enemy.handleSpriteMovement(player.position, duration: distance / Double(enemiesModel.getMovementSpeed(enemy.name!)))
    }
  }
  
  private func updatePlayerState() {
    regenPlayerResources()
    
    let (moveJoystickValues, skillJoystickValues) = hud.getJoystickValues()
    player.position = playerModel.getNewPlayerPosition(moveJoystickValues.0, vY: moveJoystickValues.1, angle: moveJoystickValues.2, pos: player.position)
    if (skillJoystickValues.0 == 0 && skillJoystickValues.1 == 0) {
      player.changeDirection(moveJoystickValues.2)
    } else {
      player.changeDirection(skillJoystickValues.2)
      if playerModel.canUseSpell() {
        useSpell()
      }
    }
    
    hud.updateEnergyFrame(playerModel.getRemainingManaFraction())
    hud.updateHealthFrame(playerModel.getRemainingHealthFraction())
  }
  
  private func updatePlayerEnemyConditions() {
    if playerEnemyInContact {
      for enemy in enemiesInContact {
        damagePlayerAndEnemy(enemy)
      }
    }
  }
  
  private func spawnEnemies(var enemies: [Enemy]) {
    if enemies.count >= 1 {
      let spawnAction = SKAction.runBlock({
        if let enemy = enemies.popLast() {
          self.enemiesModel.addEnemy(enemy.name!)
          enemy.position = self.enemiesModel.getEnemySpawnPosition(self.player.position, mapSize: self.map.size)
          self.enemies.append(enemy)
          self.map.addChild(enemy)
        }
      })
      let waitAction = SKAction.waitForDuration(Double(getRandomNumber(30) / 50))
      let spawnMoreAction = SKAction.runBlock({
        self.spawnEnemies(enemies)
      })
      
      let sequence = SKAction.sequence([spawnAction, waitAction, spawnMoreAction])
      runAction(sequence)
    }
  }
  
  private func handleSpellAndEnemyContact(enemy: Enemy) {
    enemiesModel.takeDamage(enemy.name!, damage: playerModel.activeSpell.damage * playerModel.getSpellDamageModifier())
  }
  
  private func handlePlayerAndEnemyContact(enemy: Enemy) {
    damagePlayerAndEnemy(enemy)
    putEnemyInContact(enemy)
  }
  
  private func putEnemyInContact(enemy: Enemy) {
    if !enemiesInContact.contains(enemy) {
      enemiesInContact.append(enemy)
    }
    
    enemy.inContactWithPlayer = true
    playerEnemyInContact = true
  }
  
  
  // MARK: - Player and Enemy Death Helpers
  
  private func removeEnemyFromEnemiesInContact(enemy: Enemy) {
    if enemiesInContact.contains(enemy) {
      if let index = enemiesInContact.indexOf(enemy) {
        enemiesInContact.removeAtIndex(index)
        if enemiesInContact.isEmpty {
          playerEnemyInContact = false
        }
      }
    }
  }
  
  private func animateDeath(position: CGPoint) {
    if let deathEmitter = EmitterGenerator.sharedInstance.getEnemyDeathEmitter() {
      deathEmitter.position = position
      map.addChild(deathEmitter)
    }
  }
  
  // MARK: - Spells
  
  private func useSpell() {
    let spellSprite: SKSpriteNode
    let action: SKAction
    (spellSprite, action) = playerModel.handleSpellCast(player.zRotation)
    spellSprite.position = player.position
    player.runAction(action)
    
    switch playerModel.activeSpell.spellName {
    case .Lightning:
      useLinearSpell(spellSprite, missileSpeed: Spell.MissileSpeeds.LightningStorm)
    case .Fireball:
      useLinearSpell(spellSprite, missileSpeed: Spell.MissileSpeeds.Fireball)
    case .ArcaneBolt:
      useLinearSpell(spellSprite, missileSpeed: Spell.MissileSpeeds.ArcaneBolt)
    }
    map.addChild(spellSprite)
  }
  
  private func useLinearSpell(spell: SKSpriteNode, missileSpeed: Double) {
    var sign = 1
    if hud.skillJoystick.thumbX < 0 {
      sign = -1
    }
    let angle = getAngle(hud.skillJoystick.thumbY, adjacent: hud.skillJoystick.thumbX)
    let (dx,dy) = getTriangleLegs(1000, angle: angle, sign: CGFloat(sign))
    
    let arbitraryPointFaraway = CGPoint(x: spell.position.x + dx, y: spell.position.y + dy)
    let duration = getDistance(spell.position, point2: arbitraryPointFaraway) / missileSpeed
    
    let moveAction = SKAction.moveTo(arbitraryPointFaraway, duration: duration)
    let removeAction = SKAction.removeFromParent()
    let completeAction = SKAction.sequence([moveAction, removeAction])
    spell.runAction(completeAction)
  }
  
  // MARK: - Low level calculations/helpers
  
  private func regenPlayerResources() {
    playerModel.regenMana()
    playerModel.regenHealth()
  }
  
  private func enemiesAreInContact() -> Bool {
    return !enemiesInContact.isEmpty
  }
  
  // MARK: Player and Enemy damage
  
  private func damagePlayerAndEnemy(enemy: Enemy) {
    playerModel.takeDamage(enemiesModel.getAttackValue(enemy.name!))
    enemiesModel.takeDamage(enemy.name!, damage: playerModel.getAttack())

  }
  
  // MARK: - Player and Enemy Visuals
  
  private func onSpellHitEffects(position: CGPoint) {
    if let dissipateEmitter = EmitterGenerator.sharedInstance.getDissipationEmitter() {
      map.addChild(dissipateEmitter, position: position)
    }
  }
  
  private func levelUpEffects() {
    if let levelUpEmitter = EmitterGenerator.sharedInstance.getLevelUpEmitter() {
      map.addChild(levelUpEmitter, position: player.position)
    }
  }
  
  // MARK: - Camera
  private func updateCamera() {
    if (player.position.x > frame.size.width/2 && player.position.x < (map.size.width - frame.size.width/2)) {
      self.cameraNode.position = CGPoint(x: player.position.x - frame.size.width/2, y: cameraNode.position.y);
    }
    if (player.position.y > frame.size.height/2 && player.position.y < (map.size.height - frame.size.height/2)) {
      self.cameraNode.position = CGPoint(x: cameraNode.position.x, y: player.position.y - frame.size.height/2);
    }
    
    centerOnNode(cameraNode)
  }
  
  private func centerOnNode(node: SKNode) {
    let cameraPositionInScene: CGPoint = node.scene!.convertPoint(node.position, fromNode: node.parent!)
    
    let xPos = node.parent!.position.x - cameraPositionInScene.x
    let yPos = node.parent!.position.y - cameraPositionInScene.y
    
    node.parent?.position = CGPoint(x: xPos, y: yPos);
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Extensions

extension LevelOne: HUDDelegate {
  func skillButtonTouched(skillName: SpellString) {
    playerModel.setActiveSkill(skillName)
  }
}


extension LevelOne: PlayerModelDelegate {
  func playerDeath() {
    let scene = MainMenu(size: view!.bounds.size)
    
    scene.scaleMode = .ResizeFill
    view!.presentScene(scene, transition: SKTransition.crossFadeWithDuration(1.0))
  }
  
  func playerLeveledUp() {
      levelUpEffects()
      hud.levelUp(String(playerModel.getLevel()))
  }
}

extension LevelOne: EnemiesModelDelegate {
  func enemyDeathSequence(id: EnemyID) {
    for enemy in enemies {
      if enemy.name! == id {
        enemyDeathSequence(enemy)
      }
    }
  }
  
  private func enemyDeathSequence(enemy: Enemy) {
    runAction(SKAction.playSoundFileNamed(SoundFile.ZombieDeath, waitForCompletion: false))
    enemyDeath(enemy)
    updateGameStateAfterEnemyDeath()
  }
  
  private func updateGameStateAfterEnemyDeath() {
    enemiesKilled += 1
    
    playerModel.checkIfLeveledUp()
    checkIfBeginNextRound()
    
    hud.updateKillCount(enemiesKilled)
    hud.updateExperienceFrameFrame(playerModel.getRemainingExpFraction())
  }
  
  private func checkIfBeginNextRound() {
    if enemies.isEmpty {
      enemiesModel.incrementDifficulty()
      let waitAction = SKAction.waitForDuration(4)
      let spawnAction = SKAction.runBlock({
        self.loadEnemies()
      })
      
      let sequence = SKAction.sequence([waitAction, spawnAction])
      runAction(sequence)
    }
  }
  
  private func enemyDeath(enemy: Enemy) {
    animateDeath(enemy.position)
    
    removeEnemyFromEnemiesInContact(enemy)
    
    if let index = enemies.indexOf(enemy) {
      enemies.removeAtIndex(index)
    }
    
    enemy.physicsBody = nil
    enemy.runAction(SKAction.fadeOutWithDuration(0.2))
    playerModel.gainExp(enemiesModel.getExpValue(enemy.name!))
  }
}