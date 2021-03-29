//
//  GameScene.swift
//  Fliege Shared
//
//  Created by Daniel Jilg on 10.03.21.
//

import SpriteKit
import TelemetryClient

enum GameStatus {
    case playing
    case titleScreen
    case gameOver
}

class GameScene: SKScene {
    fileprivate var flyPrototypeNode: SKNode?
    fileprivate var poopNode: SKSpriteNode?
    fileprivate var circleCenterNode: SKNode?
    fileprivate var scoreLabelNode: SKLabelNode?
    fileprivate var titleScreenOverlay: SKSpriteNode?
    fileprivate var gameOverScreenOverlay: SKSpriteNode?
    fileprivate var carlaNode: SKSpriteNode?
    
    fileprivate var flies: [SKNode] = []
    
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
    
    fileprivate func setupFlyGeneration() {
        let wait = SKAction.wait(forDuration: 1) // time between new flies appearing
        let block = SKAction.run({
            [unowned self] in
            makeNewFly(at: CGPoint(x: Int.random(in: -500...500), y: 500))
        })
        let sequence = SKAction.sequence([wait,block])
        
        run(SKAction.repeatForever(sequence), withKey: "countdown")
    }
    
    fileprivate func setupFlyUpdater() {
        let wait = SKAction.wait(forDuration: 0.02)
        let block = SKAction.run({
            [unowned self] in
            updateFlies()
        })
        let sequence = SKAction.sequence([wait,block])
        
        run(SKAction.repeatForever(sequence), withKey: "lakshfl")
    }
    
    func setUpScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.1)
        physicsWorld.speed = 0.5

        self.circleCenterNode = self.childNode(withName: "//circleCenterNode")
        self.poopNode = self.childNode(withName: "//poopNode") as? SKSpriteNode
        self.flyPrototypeNode = self.childNode(withName: "//fly")
        self.scoreLabelNode = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        self.titleScreenOverlay = self.childNode(withName: "//titleScreen") as? SKSpriteNode
        self.gameOverScreenOverlay = self.childNode(withName: "//gameOverScreen") as? SKSpriteNode
        self.carlaNode = self.childNode(withName: "//carlaNode") as? SKSpriteNode
        
        (self.childNode(withName: "//titleScreenLabel") as? SKLabelNode)?.text = NSLocalizedString("titleScreenLabel", comment: "")
        (self.childNode(withName: "//gameOverScreenLabel") as? SKLabelNode)?.text = NSLocalizedString("gameOverScreenLabel", comment: "")

        setupFlyGeneration()
        setupFlyUpdater()
        
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

    func makeNewFly(at pos: CGPoint) {
        if gameStatus == .titleScreen && flies.count > 4 {
            return
        }
        
        if gameStatus == .playing && flies.count > 20 {
            gameStatus = .gameOver
            return
        }
        
        if gameStatus == .gameOver {
            return
        }
        
        if let newFly = self.flyPrototypeNode?.copy() as! SKNode? {
            newFly.alpha = 1
            newFly.position = pos
            newFly.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            newFly.physicsBody?.mass = 0.0001
            newFly.physicsBody?.linearDamping = 0.5

            if let particles = SKEmitterNode(fileNamed: "TrailParticle.sks") {
                particles.name = "flyTrail"
                particles.position = newFly.position
                particles.targetNode = self
                newFly.addChild(particles)
                particles.position = CGPoint(x: 0, y: 0)
            }

            let audioNode = SKAudioNode(fileNamed: "sssssss.m4a")
            audioNode.isPositional = true
            audioNode.autoplayLooped = true
            newFly.addChild(audioNode)
            audioNode.position = CGPoint(x: 0, y: 0)

            self.addChild(newFly)
            flies.append(newFly)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
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
    }
    
    private func updateFlies() {
        guard let circleCenterNode = circleCenterNode else { return }
        
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
            TelemetryManager.send("tap")
            break
        case .titleScreen:
            gameStatus = .playing
            TelemetryManager.send("starGame")
        case .gameOver:
            gameStatus = .titleScreen
            score = 0
            flies.forEach { $0.removeFromParent() }
            flies.removeAll()
            TelemetryManager.send("restartGame")
        }
        
        for t in touches {
            let nodes = self.nodes(at: t.location(in: self))
            let flyNodes = nodes.filter { $0.name == "fly" }
            let closeFlyNodes = flyNodes.filter { $0.position.distance(to: t.location(in: self)) < 60 }
            
            for flyNode in closeFlyNodes {
                flies.removeAll(where: {  $0 == flyNode })
                flyNode.removeFromParent()
                
                let newScore = 1000 / (flies.count + 1)
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
            
            // move little carla to position
            carlaNode?.run(SKAction.move(to: CGPoint(x: t.location(in: self).x, y: carlaNode!.position.y), duration: 0.2))
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
