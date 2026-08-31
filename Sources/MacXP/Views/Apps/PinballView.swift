import SwiftUI
import SpriteKit
#if os(macOS)
import AppKit
#endif

// MARK: - Collision Categories

struct PinballPhysicsCategory {
    static let none: UInt32 = 0
    static let ball: UInt32 = 0b1
    static let wall: UInt32 = 0b10
    static let flipper: UInt32 = 0b100
    static let bumper: UInt32 = 0b1000
    static let target: UInt32 = 0b10000
    static let drain: UInt32 = 0b100000
    static let ramp: UInt32 = 0b1000000
}

// MARK: - Pinball SpriteKit Scene

public class PinballScene: SKScene, SKPhysicsContactDelegate {
    public var onScoreUpdated: ((Int) -> Void)?
    public var onBallDrained: (() -> Void)?
    public var onBumperHit: (() -> Void)?
    public var onFlipperMoved: (() -> Void)?
    
    private var ball: SKShapeNode?
    private var leftFlipper: SKShapeNode?
    private var rightFlipper: SKShapeNode?
    private var leftFlipperJoint: SKPhysicsJointPin?
    private var rightFlipperJoint: SKPhysicsJointPin?
    
    private var plungerNode: SKShapeNode?
    private var isPlungerCharging: Bool = false
    private var plungerPower: CGFloat = 0.0
    
    private var isLeftFlipperActive: Bool = false
    private var isRightFlipperActive: Bool = false
    
    private var score: Int = 0
    
    public override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1.0)
        
        setupTableWalls()
        setupFlippers()
        setupBumpers()
        setupTargets()
        setupDecorations()
        spawnBall()
    }
    
    // MARK: - Table Setup
    
    private func setupTableWalls() {
        // Table Boundaries
        let path = CGMutablePath()
        // Left Wall
        path.move(to: CGPoint(x: 20, y: 140))
        path.addLine(to: CGPoint(x: 20, y: size.height - 80))
        // Top Arch
        path.addQuadCurve(to: CGPoint(x: size.width - 20, y: size.height - 80), control: CGPoint(x: size.width / 2, y: size.height - 10))
        // Right Outer Wall
        path.addLine(to: CGPoint(x: size.width - 20, y: 80))
        // Plunger Chute Divider
        path.addLine(to: CGPoint(x: size.width - 50, y: 80))
        path.addLine(to: CGPoint(x: size.width - 50, y: size.height - 120))
        
        let wallNode = SKShapeNode(path: path)
        wallNode.strokeColor = SKColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.8)
        wallNode.lineWidth = 4
        wallNode.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        wallNode.physicsBody?.categoryBitMask = PinballPhysicsCategory.wall
        wallNode.physicsBody?.restitution = 0.35
        addChild(wallNode)
        
        // Bottom Drain
        let drainRect = CGRect(x: 0, y: 0, width: size.width, height: 30)
        let drainNode = SKShapeNode(rect: drainRect)
        drainNode.fillColor = .clear
        drainNode.strokeColor = .clear
        drainNode.physicsBody = SKPhysicsBody(edgeLoopFrom: drainRect)
        drainNode.physicsBody?.categoryBitMask = PinballPhysicsCategory.drain
        drainNode.physicsBody?.contactTestBitMask = PinballPhysicsCategory.ball
        addChild(drainNode)
        
        // Left & Right Slingshot Triangles
        let leftSlingshotPath = CGMutablePath()
        leftSlingshotPath.move(to: CGPoint(x: 35, y: 180))
        leftSlingshotPath.addLine(to: CGPoint(x: 90, y: 150))
        leftSlingshotPath.addLine(to: CGPoint(x: 35, y: 240))
        leftSlingshotPath.closeSubpath()
        
        let leftSlingshot = SKShapeNode(path: leftSlingshotPath)
        leftSlingshot.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.7)
        leftSlingshot.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        leftSlingshot.lineWidth = 2
        leftSlingshot.physicsBody = SKPhysicsBody(polygonFrom: leftSlingshotPath)
        leftSlingshot.physicsBody?.isDynamic = false
        leftSlingshot.physicsBody?.categoryBitMask = PinballPhysicsCategory.bumper
        leftSlingshot.physicsBody?.restitution = 1.2
        addChild(leftSlingshot)
        
        let rightSlingshotPath = CGMutablePath()
        rightSlingshotPath.move(to: CGPoint(x: size.width - 65, y: 180))
        rightSlingshotPath.addLine(to: CGPoint(x: size.width - 120, y: 150))
        rightSlingshotPath.addLine(to: CGPoint(x: size.width - 65, y: 240))
        rightSlingshotPath.closeSubpath()
        
        let rightSlingshot = SKShapeNode(path: rightSlingshotPath)
        rightSlingshot.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.7)
        rightSlingshot.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        rightSlingshot.lineWidth = 2
        rightSlingshot.physicsBody = SKPhysicsBody(polygonFrom: rightSlingshotPath)
        rightSlingshot.physicsBody?.isDynamic = false
        rightSlingshot.physicsBody?.categoryBitMask = PinballPhysicsCategory.bumper
        rightSlingshot.physicsBody?.restitution = 1.2
        addChild(rightSlingshot)
    }
    
    private func setupFlippers() {
        let flipperWidth: CGFloat = 65
        let flipperHeight: CGFloat = 16
        
        // Left Flipper
        let leftF = SKShapeNode(rectOf: CGSize(width: flipperWidth, height: flipperHeight), cornerRadius: 6)
        leftF.fillColor = SKColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1.0)
        leftF.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1.0)
        leftF.position = CGPoint(x: 130, y: 120)
        leftF.zRotation = -0.4
        leftF.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: flipperWidth, height: flipperHeight))
        leftF.physicsBody?.isDynamic = true
        leftF.physicsBody?.mass = 0.5
        leftF.physicsBody?.categoryBitMask = PinballPhysicsCategory.flipper
        leftF.physicsBody?.contactTestBitMask = PinballPhysicsCategory.ball
        leftF.physicsBody?.collisionBitMask = PinballPhysicsCategory.ball | PinballPhysicsCategory.wall
        leftF.physicsBody?.restitution = 0.6
        addChild(leftF)
        self.leftFlipper = leftF
        
        // Left Flipper Pivot Anchor
        let leftAnchor = SKNode()
        leftAnchor.position = CGPoint(x: 100, y: 130)
        leftAnchor.physicsBody = SKPhysicsBody(circleOfRadius: 2)
        leftAnchor.physicsBody?.isDynamic = false
        addChild(leftAnchor)
        
        let leftJoint = SKPhysicsJointPin.joint(withBodyA: leftAnchor.physicsBody!, bodyB: leftF.physicsBody!, anchor: leftAnchor.position)
        leftJoint.shouldEnableLimits = true
        leftJoint.lowerAngleLimit = -0.45
        leftJoint.upperAngleLimit = 0.55
        physicsWorld.add(leftJoint)
        self.leftFlipperJoint = leftJoint
        
        // Right Flipper
        let rightF = SKShapeNode(rectOf: CGSize(width: flipperWidth, height: flipperHeight), cornerRadius: 6)
        rightF.fillColor = SKColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1.0)
        rightF.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1.0)
        rightF.position = CGPoint(x: size.width - 160, y: 120)
        rightF.zRotation = 0.4
        rightF.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: flipperWidth, height: flipperHeight))
        rightF.physicsBody?.isDynamic = true
        rightF.physicsBody?.mass = 0.5
        rightF.physicsBody?.categoryBitMask = PinballPhysicsCategory.flipper
        rightF.physicsBody?.contactTestBitMask = PinballPhysicsCategory.ball
        rightF.physicsBody?.collisionBitMask = PinballPhysicsCategory.ball | PinballPhysicsCategory.wall
        rightF.physicsBody?.restitution = 0.6
        addChild(rightF)
        self.rightFlipper = rightF
        
        // Right Flipper Pivot Anchor
        let rightAnchor = SKNode()
        rightAnchor.position = CGPoint(x: size.width - 130, y: 130)
        rightAnchor.physicsBody = SKPhysicsBody(circleOfRadius: 2)
        rightAnchor.physicsBody?.isDynamic = false
        addChild(rightAnchor)
        
        let rightJoint = SKPhysicsJointPin.joint(withBodyA: rightAnchor.physicsBody!, bodyB: rightF.physicsBody!, anchor: rightAnchor.position)
        rightJoint.shouldEnableLimits = true
        rightJoint.lowerAngleLimit = -0.55
        rightJoint.upperAngleLimit = 0.45
        physicsWorld.add(rightJoint)
        self.rightFlipperJoint = rightJoint
    }
    
    private func setupBumpers() {
        let bumperPositions: [CGPoint] = [
            CGPoint(x: size.width * 0.42, y: size.height * 0.68),
            CGPoint(x: size.width * 0.62, y: size.height * 0.68),
            CGPoint(x: size.width * 0.52, y: size.height * 0.54)
        ]
        
        for (i, pos) in bumperPositions.enumerated() {
            let bumper = SKShapeNode(circleOfRadius: 24)
            bumper.fillColor = (i == 2) ? SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) : SKColor(red: 0.2, green: 0.4, blue: 0.95, alpha: 1.0)
            bumper.strokeColor = .white
            bumper.lineWidth = 3
            bumper.position = pos
            bumper.name = "bumper"
            
            bumper.physicsBody = SKPhysicsBody(circleOfRadius: 24)
            bumper.physicsBody?.isDynamic = false
            bumper.physicsBody?.categoryBitMask = PinballPhysicsCategory.bumper
            bumper.physicsBody?.contactTestBitMask = PinballPhysicsCategory.ball
            bumper.physicsBody?.restitution = 1.6 // High elasticity bounce!
            addChild(bumper)
            
            // Inner Core Light
            let core = SKShapeNode(circleOfRadius: 10)
            core.fillColor = .white
            core.strokeColor = .clear
            bumper.addChild(core)
        }
    }
    
    private func setupTargets() {
        let targetX = [size.width * 0.25, size.width * 0.32, size.width * 0.39]
        for x in targetX {
            let target = SKShapeNode(rectOf: CGSize(width: 14, height: 18), cornerRadius: 3)
            target.fillColor = SKColor(red: 0.95, green: 0.6, blue: 0.1, alpha: 1.0)
            target.strokeColor = .white
            target.lineWidth = 1.5
            target.position = CGPoint(x: x, y: size.height * 0.78)
            target.name = "target"
            
            target.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 14, height: 18))
            target.physicsBody?.isDynamic = false
            target.physicsBody?.categoryBitMask = PinballPhysicsCategory.target
            target.physicsBody?.contactTestBitMask = PinballPhysicsCategory.ball
            target.physicsBody?.restitution = 1.1
            addChild(target)
        }
    }
    
    private func setupDecorations() {
        // Space Cadet Starfield and Hyperspace Logo
        for _ in 0..<35 {
            let x = CGFloat.random(in: 30...(size.width - 60))
            let y = CGFloat.random(in: 100...(size.height - 50))
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = SKColor.white.withAlphaComponent(CGFloat.random(in: 0.3...0.8))
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            addChild(star)
        }
        
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = "SPACE CADET"
        titleLabel.fontSize = 20
        titleLabel.fontColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.4)
        titleLabel.position = CGPoint(x: size.width * 0.52, y: size.height * 0.38)
        addChild(titleLabel)
    }
    
    // MARK: - Ball Management
    
    public func spawnBall() {
        ball?.removeFromParent()
        
        let b = SKShapeNode(circleOfRadius: 9)
        b.fillColor = SKColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1.0)
        b.strokeColor = .white
        b.lineWidth = 1
        b.position = CGPoint(x: size.width - 35, y: 100)
        b.name = "ball"
        
        b.physicsBody = SKPhysicsBody(circleOfRadius: 9)
        b.physicsBody?.mass = 0.18
        b.physicsBody?.restitution = 0.5
        b.physicsBody?.linearDamping = 0.05
        b.physicsBody?.angularDamping = 0.1
        b.physicsBody?.categoryBitMask = PinballPhysicsCategory.ball
        b.physicsBody?.contactTestBitMask = PinballPhysicsCategory.bumper | PinballPhysicsCategory.target | PinballPhysicsCategory.drain | PinballPhysicsCategory.flipper
        b.physicsBody?.collisionBitMask = PinballPhysicsCategory.wall | PinballPhysicsCategory.flipper | PinballPhysicsCategory.bumper | PinballPhysicsCategory.target
        addChild(b)
        self.ball = b
    }
    
    // MARK: - Controls
    
    public func triggerLeftFlipper(active: Bool) {
        isLeftFlipperActive = active
        if active {
            leftFlipper?.physicsBody?.applyAngularImpulse(22.0)
            onFlipperMoved?()
        } else {
            leftFlipper?.physicsBody?.applyAngularImpulse(-15.0)
        }
    }
    
    public func triggerRightFlipper(active: Bool) {
        isRightFlipperActive = active
        if active {
            rightFlipper?.physicsBody?.applyAngularImpulse(-22.0)
            onFlipperMoved?()
        } else {
            rightFlipper?.physicsBody?.applyAngularImpulse(15.0)
        }
    }
    
    public func launchPlunger(power: CGFloat) {
        guard let b = ball, b.position.x > size.width - 55 else { return }
        let impulse = max(35.0, min(95.0, power * 95.0))
        b.physicsBody?.applyImpulse(CGVector(dx: 0, dy: impulse))
    }
    
    // MARK: - Collision Handling
    
    public func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if mask & PinballPhysicsCategory.bumper != 0 {
            score += 500
            onScoreUpdated?(score)
            onBumperHit?()
            
            // Flash Bumper
            let bumperNode = (contact.bodyA.categoryBitMask == PinballPhysicsCategory.bumper) ? contact.bodyA.node : contact.bodyB.node
            bumperNode?.run(SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        } else if mask & PinballPhysicsCategory.target != 0 {
            score += 1000
            onScoreUpdated?(score)
            onBumperHit?()
        } else if mask & PinballPhysicsCategory.drain != 0 {
            onBallDrained?()
        }
    }
}

// MARK: - Pinball View

public struct PinballView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @State private var score: Int = 0
    @State private var ballsRemaining: Int = 3
    @State private var isGameOver: Bool = false
    @State private var currentRank: String = "CADET"
    @State private var pinballScene: PinballScene? = nil
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Menu Bar
            menuBar
            
            // Score & Rank HUD
            hudView
            
            // Pinball SpriteKit Canvas
            ZStack(alignment: .bottom) {
                SpriteView(scene: getOrCreateScene())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // On-Screen Touch / Mouse Controls
                controlsOverlay
            }
        }
        .background(Color(red: 0.05, green: 0.08, blue: 0.16))
    }
    
    private func getOrCreateScene() -> PinballScene {
        if let scene = pinballScene {
            return scene
        }
        let newScene = PinballScene(size: CGSize(width: 480, height: 560))
        newScene.scaleMode = .aspectFit
        newScene.onScoreUpdated = { newScore in
            self.score = newScore
            updateRank(newScore)
        }
        newScene.onBallDrained = {
            if self.ballsRemaining > 1 {
                self.ballsRemaining -= 1
                newScene.spawnBall()
            } else {
                self.isGameOver = true
            }
        }
        self.pinballScene = newScene
        return newScene
    }
    
    private func updateRank(_ score: Int) {
        switch score {
        case 0..<10000:
            currentRank = "CADET"
        case 10000..<50000:
            currentRank = "ENSIGN"
        case 50000..<150000:
            currentRank = "LIEUTENANT"
        case 150000..<500000:
            currentRank = "COMMANDER"
        case 500000..<1500000:
            currentRank = "CAPTAIN"
        default:
            currentRank = "FLEET ADMIRAL"
        }
    }
    
    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 16) {
            Menu("Game") {
                Button("New Game (F2)") { restartGame() }
                Button("Pause / Resume (F3)") {}
                Button("High Scores...") {}
                Divider()
                Button("Exit") { windowManager.closeWindow(id: window.id) }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            Menu("Options") {
                Button("Player Controls...") {}
                Button("Sound Effects") {}
                Button("Music") {}
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            Menu("Help") {
                Button("Help Topics") {}
                Button("About 3D Pinball") {}
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            Spacer()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(red: 0.93, green: 0.91, blue: 0.85))
        .border(Color(red: 0.82, green: 0.80, blue: 0.72), width: 1)
    }
    
    // MARK: - HUD
    private var hudView: some View {
        HStack {
            // LED Score Display
            HStack(spacing: 4) {
                Text("SCORE:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(String(format: "%08d", score))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.2))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.cornerRadius(4))
            
            Spacer()
            
            // Rank Display
            Text("RANK: \(currentRank)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
            
            Spacer()
            
            // Ball Count
            HStack(spacing: 4) {
                Text("BALL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text("\(ballsRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.1))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.cornerRadius(4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(LinearGradient(colors: [Color(red: 0.1, green: 0.12, blue: 0.2), Color(red: 0.04, green: 0.06, blue: 0.12)], startPoint: .top, endPoint: .bottom))
    }
    
    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        HStack {
            // Left Flipper Button
            Button(action: {}) {
                Text("◀ LEFT (Z)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.7).cornerRadius(6))
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pinballScene?.triggerLeftFlipper(active: true) }
                    .onEnded { _ in pinballScene?.triggerLeftFlipper(active: false) }
            )
            
            Spacer()
            
            // Launch Plunger Button
            Button(action: {
                pinballScene?.launchPlunger(power: 1.0)
            }) {
                Text("LAUNCH (SPACE)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.orange.opacity(0.8).cornerRadius(6))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Right Flipper Button
            Button(action: {}) {
                Text("RIGHT (/) ▶")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.7).cornerRadius(6))
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pinballScene?.triggerRightFlipper(active: true) }
                    .onEnded { _ in pinballScene?.triggerRightFlipper(active: false) }
            )
        }
        .padding(12)
        .background(Color.black.opacity(0.4))
    }
    
    private func restartGame() {
        score = 0
        ballsRemaining = 3
        isGameOver = false
        currentRank = "CADET"
        pinballScene?.spawnBall()
    }
}
