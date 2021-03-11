//
//  GameScene.swift
//  Fliege Shared
//
//  Created by Daniel Jilg on 10.03.21.
//

import SpriteKit

class GameScene: SKScene {
    
    
    fileprivate var label : SKLabelNode?
    fileprivate var spinnyNode : SKLabelNode?

    fileprivate var flies: [SKLabelNode] = []
    
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
        physicsWorld.gravity = .zero

        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//fly") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        self.spinnyNode = self.childNode(withName: "//fly") as? SKLabelNode
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))

        }
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
        if let spinny = self.spinnyNode?.copy() as! SKLabelNode? {
            spinny.position = pos
            spinny.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            self.addChild(spinny)
            flies.append(spinny)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

        flies.forEach { fly in
            fly.physicsBody?.applyForce(CGVector.init(dx: CGFloat(Double.random(in: -1...1)), dy: CGFloat(Double.random(in: -1...1))))
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

