//
//  GameScene.swift
//  Fliege Shared
//
//  Created by Daniel Jilg on 10.03.21.
//

import SpriteKit

enum GameStatus {
    case playing
    case titleScreen
    case gameOver
}

class GameScene: SKScene {
    fileprivate var spinnyNode: SKSpriteNode?
    fileprivate var poopNode: SKSpriteNode?
    fileprivate var circleCenterNode: SKNode?
    fileprivate var scoreLabelNode: SKLabelNode?
    fileprivate var titleScreenOverlay: SKSpriteNode?
    fileprivate var gameOverScreenOverlay: SKSpriteNode?
    
    fileprivate var flies: [SKSpriteNode] = []
    
    fileprivate var score: Int = 0
    fileprivate var gameStatus: GameStatus = .titleScreen
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    func setUpScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.1)
        physicsWorld.speed = 0.5

        self.circleCenterNode = self.childNode(withName: "//circleCenterNode")
        self.poopNode = self.childNode(withName: "//poopNode") as? SKSpriteNode
        self.spinnyNode = self.childNode(withName: "//fly") as? SKSpriteNode
        self.scoreLabelNode = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        self.titleScreenOverlay = self.childNode(withName: "//titleScreen") as? SKSpriteNode
        self.gameOverScreenOverlay = self.childNode(withName: "//gameOverScreen") as? SKSpriteNode
        
        scoreLabelNode?.horizontalAlignmentMode = .right
        scoreLabelNode?.position = CGPoint(x: 980/2, y: 700/2)

        let wait = SKAction.wait(forDuration: 5) // time between new flies appearing
        let block = SKAction.run({
            [unowned self] in
            makeSpinny(at: CGPoint(x: -500, y: 500))
        })
        let sequence = SKAction.sequence([wait,block])

        run(SKAction.repeatForever(sequence), withKey: "countdown")
        
        let titleFadeInSequence = SKAction.sequence([SKAction.fadeOut(withDuration: 0), SKAction.fadeIn(withDuration: 1)])
        titleScreenOverlay?.run(titleFadeInSequence)
        
        gameOverScreenOverlay?.run(SKAction.fadeOut(withDuration: 0))
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif

    func makeSpinny(at pos: CGPoint) {
        if gameStatus == .titleScreen && flies.count > 4 {
            return
        }
        
        if gameStatus == .playing && flies.count > 20 {
            gameStatus = .gameOver
            return
        }
        
        if let spinny = self.spinnyNode?.copy() as! SKSpriteNode? {
            spinny.position = pos
            spinny.alpha = 1
            spinny.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            spinny.physicsBody?.mass = 0.0001
            spinny.physicsBody?.linearDamping = 0.5

            if let particles = SKEmitterNode(fileNamed: "TrailParticle.sks") {
                particles.position = spinny.position
                particles.targetNode = self
                spinny.addChild(particles)
            }

            let audioNode = SKAudioNode(fileNamed: "sssssss.m4a")
            audioNode.isPositional = true
            audioNode.autoplayLooped = true
            spinny.addChild(audioNode)

            self.addChild(spinny)
            flies.append(spinny)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let circleCenterNode = circleCenterNode else { return }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        switch gameStatus {
        case .playing:
            titleScreenOverlay?.run(fadeOut)
            gameOverScreenOverlay?.run(fadeOut)
        case .titleScreen:
            titleScreenOverlay?.run(fadeIn)
            gameOverScreenOverlay?.run(fadeOut)
        case .gameOver:
            titleScreenOverlay?.run(fadeOut)
            gameOverScreenOverlay?.run(fadeIn)
        }

        flies.forEach { fly in
            let idealX: CGFloat = circleCenterNode.position.x
            let idealY: CGFloat = circleCenterNode.position.y

            let forceX: CGFloat = min(1, (idealX - fly.position.x) * 0.01 * CGFloat(Float.random(in: 0...1))) + CGFloat(Float.random(in: -3...3))
            let forceY: CGFloat = min(1, (idealY - fly.position.y) * 0.005 * CGFloat(Float.random(in: 0...1))) + CGFloat(Float.random(in: -0.5...0.5))

            fly.physicsBody?.applyForce(CGVector.init(dx: forceX, dy: forceY))

            if let physicsBody = fly.physicsBody {
                let value = physicsBody.velocity.dx * -0.001
                let rotate = SKAction.rotate(toAngle: value, duration: 0.1)

                fly.run(rotate)
            }
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .playing:
            break
        case .titleScreen:
            gameStatus = .playing
        case .gameOver:
            gameStatus = .titleScreen
            score = 0
            flies.forEach { $0.removeFromParent() }
            flies.removeAll()
        }
        
        for t in touches {
            let node = self.atPoint(t.location(in: self))
            if node.name == "fly" {
                flies.removeAll(where: {  $0 == node })
                node.removeFromParent()
                
                let newScore = 100 / (flies.count + 1)
                score += newScore
                
                scoreLabelNode?.text = "\(score)"
            }
            
            // Gravity impulse to simulate flies shying away
            let gravity = SKFieldNode.radialGravityField()
            gravity.strength = -30
            self.addChild(gravity)
            gravity.position = t.location(in: self)
            
            let gravitySequence = SKAction.sequence([SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()])
            gravity.run(gravitySequence)
        }
    }
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    override func mouseDown(with event: NSEvent) {

    }

    override func mouseUp(with event: NSEvent) {
//        self.makeSpinny(at: event.location(in: self))
    }

}
#endif

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return abs(CGFloat(hypotf(Float(point.x - x), Float(point.y - y))))
    }
}
