//
//  GameScene.swift
//  Fliege Shared
//
//  Created by Daniel Jilg on 10.03.21.
//

import SpriteKit

class GameScene: SKScene {
    fileprivate var spinnyNode : SKSpriteNode?
    fileprivate var poopNode : SKSpriteNode?
    fileprivate var flies: [SKSpriteNode] = []
    
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

        self.poopNode = self.childNode(withName: "//poopNode") as? SKSpriteNode
        self.spinnyNode = self.childNode(withName: "//fly") as? SKSpriteNode
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

    func makeSpinny(at pos: CGPoint, color: SKColor) {
        if let spinny = self.spinnyNode?.copy() as! SKSpriteNode? {
            spinny.position = pos
            spinny.alpha = 1
            spinny.physicsBody = SKPhysicsBody(circleOfRadius: 1)

            if let particles = SKEmitterNode(fileNamed: "TrailParticle.sks") {
                particles.position = spinny.position
                particles.targetNode = self
                spinny.addChild(particles)
            }

            self.addChild(spinny)
            flies.append(spinny)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

        guard let poopNode = poopNode else { return }

        flies.forEach { fly in
            fly.position.distance(to: poopNode.position)
            fly.physicsBody?.applyForce(CGVector.init(dx: CGFloat(Double.random(in: -1...1)), dy: CGFloat(Double.random(in: 0...0.2))))
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }

}
#endif

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return abs(CGFloat(hypotf(Float(point.x - x), Float(point.y - y))))
    }
}
