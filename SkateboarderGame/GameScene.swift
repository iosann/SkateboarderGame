//
//  GameScene.swift
//  SkateboarderGame
//
//  Created by Anna Belousova on 20.03.2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

	let skater = Skater(imageNamed: "skater")
    
    override func didMove(to view: SKView) {
		anchorPoint = CGPoint.zero

		let background = SKSpriteNode(imageNamed: "background")
		background.position = CGPoint(x: frame.midX, y: frame.midY)
		addChild(background)

		resetSkater()
		addChild(skater)
    }

	func resetSkater() {
		skater.position = CGPoint(x: frame.midX/2.0, y: skater.frame.height/2.0 + 64.0)
		skater.zPosition = 10
		skater.minimumY = skater.frame.height/2.0 + 64.0
	}
    
    override func update(_ currentTime: TimeInterval) {
    }
}
