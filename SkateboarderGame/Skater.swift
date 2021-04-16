//
//  Skater.swift
//  SkateboarderGame
//
//  Created by Anna Belousova on 20.03.2021.
//

import SpriteKit

class Skater: SKSpriteNode {
	var velocity = CGPoint.zero
	var minimumY: CGFloat = 0.0
	let jumpSpeed: CGFloat = 20.0
	var isOnGroung = true

	func setupPhysicsBody() {
		if let skaterTexture = texture {
			physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
			physicsBody?.isDynamic = true
			physicsBody?.density = 6
			physicsBody?.allowsRotation = true
			physicsBody?.angularDamping = 1
			physicsBody?.categoryBitMask = PhysicsCategory.skater
			physicsBody?.collisionBitMask = PhysicsCategory.brick
			physicsBody?.contactTestBitMask = PhysicsCategory.brick
		}
	}
}
