//
//  MenuLayer.swift
//  SkateboarderGame
//
//  Created by Anna Belousova on 24.04.2021.
//

import SpriteKit

class MenuLayer: SKSpriteNode {

	func display(message: String, score: Int?) {
		let messageLabel = SKLabelNode(text: message)
		messageLabel.position = CGPoint(x: -frame.width, y: frame.height/2)
		messageLabel.horizontalAlignmentMode = .center
		messageLabel.fontName = "Courier-Bold"
		messageLabel.fontSize = 48.0
		messageLabel.zPosition = 20
		addChild(messageLabel)

		let messageAction = SKAction.moveTo(x: frame.width/2, duration: 0.8)
		messageLabel.run(messageAction)

		guard let scoreToDisplay = score else { return }
		let scoreString = String(format: "Score: %04d", scoreToDisplay)
		let scoreLabel = SKLabelNode(text: scoreString)
		scoreLabel.position = CGPoint(x: frame.width, y: messageLabel.position.y - messageLabel.frame.height)
		scoreLabel.horizontalAlignmentMode = .center
		scoreLabel.fontName = "Courier-Bold"
		scoreLabel.fontSize = 32.0
		scoreLabel.zPosition = 20
		addChild(scoreLabel)

		let scoreAction = SKAction.moveTo(x: frame.width/2, duration: 0.5)
		scoreLabel.run(scoreAction)
	}

}
