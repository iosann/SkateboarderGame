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
	static let gem: UInt32 = 0x1 << 2
}


class GameScene: SKScene, SKPhysicsContactDelegate {

	enum GameState {
		case running, notRunning
	}

	enum BrickLevel: CGFloat {
		case low = 0.0
		case high = 100.0
	}

	var gameState = GameState.notRunning
	let skater = Skater(imageNamed: "skater")
	var bricks = [SKSpriteNode]()
	var gems = [SKSpriteNode]()
	var brickSize = CGSize.zero
	var brickLevel = BrickLevel.low
	let startingScrollSpeed: CGFloat = 5
	var scrollSpeed: CGFloat = 5
	let gravitySpeed: CGFloat = 1.5
	var lastUpdateTime: TimeInterval?
	var score = 0
	var bestScore = 0
	var lastScoreUpdateTime: TimeInterval = 0.0
    
    override func didMove(to view: SKView) {
		physicsWorld.gravity = CGVector(dx: 0, dy: -6)
		physicsWorld.contactDelegate = self
		anchorPoint = CGPoint.zero

		let background = SKSpriteNode(imageNamed: "background")
		background.position = CGPoint(x: frame.midX, y: frame.midY)
		addChild(background)

		skater.setupPhysicsBody()
		addChild(skater)

		setupLabels()

		let tap = UITapGestureRecognizer(target: self, action: #selector(tappedScreen))
		view.addGestureRecognizer(tap)

		createMenuLayer(message: "Tap to play", score: nil)
    }

	func startGame() {
		gameState = .running
		resetSkater()
		score = 0
		scrollSpeed = startingScrollSpeed
		brickLevel = .low
		lastUpdateTime = nil
		for brick in bricks {
			brick.removeFromParent()
		}
		bricks.removeAll(keepingCapacity: true)
		for gem in gems { removeGem(gem) }
	}

	func gameOver() {
		gameState = .notRunning
		if score > bestScore {
			bestScore = score
			updateBestScoreLabelText()
		}
		createMenuLayer(message: "Game over!", score: score)
	}

	func createMenuLayer(message: String, score: Int?) {
		let menuLayer = MenuLayer(color: UIColor.black.withAlphaComponent(0.4), size: frame.size)
		menuLayer.anchorPoint = CGPoint.zero
		menuLayer.position = CGPoint.zero
		menuLayer.zPosition = 30
		menuLayer.name = "menuLayer"
		menuLayer.display(message: message, score: score)
		addChild(menuLayer)
	}

	func resetSkater() {
		skater.position = CGPoint(x: frame.midX/3.0, y: skater.frame.height/2.0 + 64.0)
		skater.zPosition = 10
		skater.zRotation = 0
		skater.minimumY = skater.frame.height/2.0 + 64.0
		skater.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
		skater.physicsBody?.angularVelocity = 0
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

	func spawnGem(atPosition position: CGPoint) {
		let gem = SKSpriteNode(imageNamed: "gem")
		gem.position = position
		gem.zPosition = 9
		addChild(gem)
		gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
		gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
		gem.physicsBody?.affectedByGravity = false
		gems.append(gem)
	}

	func removeGem(_ gem: SKSpriteNode) {
		gem.removeFromParent()
		guard let gemIndex = gems.firstIndex(of: gem) else { return }
		gems.remove(at: gemIndex)
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
			if randomNumber < 3 && score > 10 {
				let gap = 20.0 * scrollSpeed
				brickX += gap
				let randomGemAmount = CGFloat(arc4random_uniform(150))
				let gemY = brickY + skater.size.height + randomGemAmount
				let gemX = brickX - gap/2.0
				spawnGem(atPosition: CGPoint(x: gemX, y: gemY))
			} else if randomNumber < 5 && score > 20 {
				if brickLevel == .high { brickLevel = .low }
				else if brickLevel == .low { brickLevel = .high }
			}

			let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
			farthestRightBrickX = newBrick.position.x
		}
	}

	func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
		for gem in gems {
			let newX = gem.position.x - currentScrollAmount
			gem.position = CGPoint(x: newX, y: gem.position.y)
			if gem.position.x < -gem.size.width { removeGem(gem) }
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

	func updateScore(_ currentTime: TimeInterval) {
		let elapsedTime = currentTime - lastScoreUpdateTime
		guard elapsedTime > 1.0 else { return }
		score += Int(scrollSpeed)
		lastScoreUpdateTime = currentTime
		updateScoreLabelText()
	}
    
    override func update(_ currentTime: TimeInterval) {
		guard gameState == .running else { return }
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
		updateGems(withScrollAmount: currentScrollAmount)
		updateSkater()
		updateScore(currentTime)
    }

	@objc func tappedScreen(tap: UITapGestureRecognizer) {
		if gameState == .running {
			guard skater.isOnGroung else { return }
			skater.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 260))
		} else {
			guard let menuLayer = childNode(withName: "menuLayer") as? SKSpriteNode else { return }
			menuLayer.removeFromParent()
			startGame()
		}
	}

	func didBegin(_ contact: SKPhysicsContact) {
		if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
			skater.isOnGroung = true
		}
		if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
			guard let gem = contact.bodyB.node as? SKSpriteNode else { return }
			removeGem(gem)
			score += 50
			updateScoreLabelText()
		}
	}

	func setupLabels() {
		let scoreTextLabel = SKLabelNode(text: "Score")
		scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
		scoreTextLabel.horizontalAlignmentMode = .left
		scoreTextLabel.fontName = "Courier-Bold"
		scoreTextLabel.fontSize = 14.0
		scoreTextLabel.zPosition = 20
		addChild(scoreTextLabel)

		let scoreLabel = SKLabelNode(text: "0")
		scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
		scoreLabel.horizontalAlignmentMode = .left
		scoreLabel.fontName = "Courier-Bold"
		scoreLabel.fontSize = 18.0
		scoreLabel.name = "scoreLabel"
		scoreLabel.zPosition = 20
		addChild(scoreLabel)

		let bestScoreTextLabel = SKLabelNode(text: "Best score")
		bestScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
		bestScoreTextLabel.horizontalAlignmentMode = .right
		bestScoreTextLabel.fontName = "Courier-Bold"
		bestScoreTextLabel.fontSize = 14.0
		bestScoreTextLabel.zPosition = 20
		addChild(bestScoreTextLabel)

		let bestScoreLabel = SKLabelNode(text: "0")
		bestScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
		bestScoreLabel.horizontalAlignmentMode = .right
		bestScoreLabel.fontName = "Courier-Bold"
		bestScoreLabel.fontSize = 18.0
		bestScoreLabel.name = "bestScoreLabel"
		bestScoreLabel.zPosition = 20
		addChild(bestScoreLabel)
	}

	func updateScoreLabelText() {
		guard let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode else { return }
		scoreLabel.text = String(format: "%04d", score)
	}

	func updateBestScoreLabelText() {
		guard let bestScoreLabel = childNode(withName: "bestScoreLabel") as? SKLabelNode else { return }
		bestScoreLabel.text = String(format: "%04d", bestScore)
	}
}
