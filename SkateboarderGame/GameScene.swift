//
//  GameScene.swift
//  SkateboarderGame
//
//  Created by Anna Belousova on 20.03.2021.
//

import SpriteKit

struct PhysicsCategory {
	static let skater: UInt32 = 0x1 << 0
	static let brick: UInt32 = 0x1 << 1
}


class GameScene: SKScene, SKPhysicsContactDelegate {

	enum BrickLevel: CGFloat {
		case low = 0.0
		case high = 100.0
	}

	let skater = Skater(imageNamed: "skater")
	var bricks = [SKSpriteNode]()
	var brickSize = CGSize.zero
	var brickLevel = BrickLevel.low
	let startingScrollSpeed: CGFloat = 5
	var scrollSpeed: CGFloat = 5
	let gravitySpeed: CGFloat = 1.5
	var lastUpdateTime: TimeInterval?
    
    override func didMove(to view: SKView) {
		physicsWorld.gravity = CGVector(dx: 0, dy: -6)
		physicsWorld.contactDelegate = self
		anchorPoint = CGPoint.zero

		let background = SKSpriteNode(imageNamed: "background")
		background.position = CGPoint(x: frame.midX, y: frame.midY)
		addChild(background)

		skater.setupPhysicsBody()
		addChild(skater)

		let tap = UITapGestureRecognizer(target: self, action: #selector(tappedScreen))
		view.addGestureRecognizer(tap)

		startGame()
    }

	func resetSkater() {
		skater.position = CGPoint(x: frame.midX/2.0, y: skater.frame.height/2.0 + 64.0)
		skater.zPosition = 10
		skater.zRotation = 0
		skater.minimumY = skater.frame.height/2.0 + 64.0
		skater.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
		skater.physicsBody?.angularVelocity = 0
	}

	func startGame() {
		resetSkater()
		scrollSpeed = startingScrollSpeed
		brickLevel = .low
		lastUpdateTime = nil
		for brick in bricks {
			brick.removeFromParent()
		}
		bricks.removeAll(keepingCapacity: true)
	}

	func gameOver() {
		startGame()
	}

	func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {
		let brick = SKSpriteNode(imageNamed: "sidewalk")
		brick.position = position
		brick.zPosition = 8
		addChild(brick)
		brickSize = brick.size
		bricks.append(brick)

		brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: brick.centerRect.origin)
		brick.physicsBody?.affectedByGravity = false
		brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
		brick.physicsBody?.collisionBitMask = 0
		return brick
	}

	func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
		var farthestRightBrickX: CGFloat = 0.0

		for brick in bricks {
			let newX = brick.position.x - currentScrollAmount
			if newX < -brickSize.width {
				brick.removeFromParent()
				guard let brickIndex = bricks.firstIndex(of: brick) else { return }
				bricks.remove(at: brickIndex)
			} else {
				brick.position = CGPoint(x: newX, y: brick.position.y)
				if brick.position.x > farthestRightBrickX {
					farthestRightBrickX = brick.position.x
				}
			}
		}

		while farthestRightBrickX < frame.width {
			var brickX = farthestRightBrickX + brickSize.width + 1.0
			let brickY = brickSize.height/2.0 + brickLevel.rawValue

			let randomNumber = arc4random_uniform(99)
			if randomNumber < 5 {
				let gap = 20.0 * scrollSpeed
				brickX += gap
			} else if randomNumber < 8 {
				if brickLevel == .high { brickLevel = .low }
				else if brickLevel == .low { brickLevel = .high }
			}

			let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
			farthestRightBrickX = newBrick.position.x
		}
	}

	func updateSkater() {
		if let velocityY = skater.physicsBody?.velocity.dy {
			if velocityY < -100 || velocityY > 100 {
				skater.isOnGroung = false
			}
		}
		let isOffScreen = skater.position.y < 0 || skater.position.x < 0
		let maxRotation = CGFloat(GLKMathDegreesToRadians(85))
		let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation

		if isOffScreen || isTippedOver { gameOver() }
	}
    
    override func update(_ currentTime: TimeInterval) {
		scrollSpeed += 0.01
		var elapsedTime: TimeInterval = 0.0
		if let lastTimeStamp = lastUpdateTime {
			elapsedTime = currentTime - lastTimeStamp
		}
		lastUpdateTime = currentTime
		let expectedElapsedTime: TimeInterval = 1/60
		let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
		let currentScrollAmount = scrollSpeed * scrollAdjustment

		updateBricks(withScrollAmount: currentScrollAmount)
		updateSkater()
    }

	@objc func tappedScreen(tap: UITapGestureRecognizer) {
		guard skater.isOnGroung else { return }
		skater.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 260))
	}

	func didBegin(_ contact: SKPhysicsContact) {
		if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
			skater.isOnGroung = true
		}
	}
}
