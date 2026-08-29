import SwiftUI
import Foundation

public enum ScreenSaverType: String, CaseIterable, Identifiable {
    case none = "none"
    case pipes3D = "pipes3D"
    case starfield = "starfield"
    case xp3DLogo = "xp3DLogo"
    case mystify = "mystify"
    case blank = "blank"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .none: return "(None)"
        case .pipes3D: return "3D Pipes"
        case .starfield: return "Starfield"
        case .xp3DLogo: return "Windows XP 3D"
        case .mystify: return "Mystify"
        case .blank: return "Blank Screen"
        }
    }

    public var hasSettings: Bool {
        switch self {
        case .pipes3D, .starfield, .mystify, .xp3DLogo: return true
        case .blank, .none: return false
        }
    }
}

public struct StarfieldSettings: Equatable {
    public var starCount: Int
    public var speed: Double
    public var warpTrail: Bool

    public init(starCount: Int = 400, speed: Double = 10.0, warpTrail: Bool = true) {
        self.starCount = max(50, min(3000, starCount))
        self.speed = max(1.0, min(50.0, speed))
        self.warpTrail = warpTrail
    }
}

public struct Star3D {
    public var x: Double
    public var y: Double
    public var z: Double
    public var pz: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.pz = z
    }
}

public struct StarfieldEngine {
    public var settings: StarfieldSettings
    public var stars: [Star3D]

    public init(settings: StarfieldSettings = StarfieldSettings()) {
        self.settings = settings
        self.stars = []
        resetStars()
    }

    public mutating func resetStars() {
        stars = (0..<settings.starCount).map { _ in
            let x = Double.random(in: -1000...1000)
            let y = Double.random(in: -1000...1000)
            let z = Double.random(in: 10...1000)
            return Star3D(x: x, y: y, z: z)
        }
    }

    public mutating func update(deltaTime: Double) {
        let dz = settings.speed * 60.0 * deltaTime * 10.0
        for i in 0..<stars.count {
            stars[i].pz = stars[i].z
            stars[i].z -= dz
            if stars[i].z <= 1.0 {
                stars[i].x = Double.random(in: -1000...1000)
                stars[i].y = Double.random(in: -1000...1000)
                stars[i].z = 1000.0
                stars[i].pz = 1000.0
            }
        }
    }
}

// MARK: - 3D Pipes Models

public enum Pipes3DJointType: String, CaseIterable, Identifiable {
    case elbow = "elbow"
    case ball = "ball"
    case mixed = "mixed"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .elbow: return "Elbow"
        case .ball: return "Ball"
        case .mixed: return "Mixed"
        }
    }
}

public struct Pipes3DSettings: Equatable {
    public var maxPipes: Int
    public var pipeRadius: Double
    public var jointType: Pipes3DJointType
    public var isSmooth: Bool

    public init(
        maxPipes: Int = 4,
        pipeRadius: Double = 8.0,
        jointType: Pipes3DJointType = .mixed,
        isSmooth: Bool = true
    ) {
        self.maxPipes = max(1, min(8, maxPipes))
        self.pipeRadius = max(4.0, min(16.0, pipeRadius))
        self.jointType = jointType
        self.isSmooth = isSmooth
    }
}

public struct PipeSegment3D {
    public var p1: SIMD3<Float>
    public var p2: SIMD3<Float>
    public var colorIndex: Int
    public var hasJoint: Bool
    public var isBallJoint: Bool

    public init(p1: SIMD3<Float>, p2: SIMD3<Float>, colorIndex: Int, hasJoint: Bool, isBallJoint: Bool) {
        self.p1 = p1
        self.p2 = p2
        self.colorIndex = colorIndex
        self.hasJoint = hasJoint
        self.isBallJoint = isBallJoint
    }
}

public struct PipeLeader {
    public var currentGrid: SIMD3<Int>
    public var currentDir: SIMD3<Int>
    public var colorIndex: Int
    public var segments: [PipeSegment3D]

    public init(currentGrid: SIMD3<Int>, colorIndex: Int) {
        self.currentGrid = currentGrid
        self.currentDir = SIMD3<Int>(1, 0, 0)
        self.colorIndex = colorIndex
        self.segments = []
    }
}

public struct Pipes3DEngine {
    public var settings: Pipes3DSettings
    public var pipes: [PipeLeader]
    public var gridBounds: SIMD3<Int> = SIMD3<Int>(14, 10, 10)
    public var totalSegments: Int = 0
    private let maxTotalSegments: Int = 300

    public init(settings: Pipes3DSettings = Pipes3DSettings()) {
        self.settings = settings
        self.pipes = []
        resetPipes()
    }

    public mutating func resetPipes() {
        pipes = (0..<settings.maxPipes).map { idx in
            let gx = Int.random(in: 2..<(gridBounds.x - 2))
            let gy = Int.random(in: 2..<(gridBounds.y - 2))
            let gz = Int.random(in: 2..<(gridBounds.z - 2))
            return PipeLeader(currentGrid: SIMD3<Int>(gx, gy, gz), colorIndex: idx % 6)
        }
        totalSegments = 0
    }

    public mutating func step() {
        if totalSegments >= maxTotalSegments {
            resetPipes()
            return
        }

        let dirs: [SIMD3<Int>] = [
            SIMD3<Int>(1, 0, 0), SIMD3<Int>(-1, 0, 0),
            SIMD3<Int>(0, 1, 0), SIMD3<Int>(0, -1, 0),
            SIMD3<Int>(0, 0, 1), SIMD3<Int>(0, 0, -1)
        ]

        for i in 0..<pipes.count {
            var leader = pipes[i]
            let oppositeDir = SIMD3<Int>(0, 0, 0) &- leader.currentDir
            // Decide whether to turn or go straight
            var nextDir = leader.currentDir
            if Double.random(in: 0...1) < 0.35 {
                let validDirs = dirs.filter { $0 != oppositeDir }
                if let chosen = validDirs.randomElement() {
                    nextDir = chosen
                }
            }

            var nextGrid = leader.currentGrid &+ nextDir
            if nextGrid.x < 0 || nextGrid.x >= gridBounds.x ||
               nextGrid.y < 0 || nextGrid.y >= gridBounds.y ||
               nextGrid.z < 0 || nextGrid.z >= gridBounds.z {
                // Bounce / turn inside
                let insideDirs = dirs.filter { d in
                    let cand = leader.currentGrid &+ d
                    return cand.x >= 0 && cand.x < gridBounds.x &&
                           cand.y >= 0 && cand.y < gridBounds.y &&
                           cand.z >= 0 && cand.z < gridBounds.z &&
                           d != oppositeDir
                }
                if let inside = insideDirs.randomElement() {
                    nextDir = inside
                    nextGrid = leader.currentGrid &+ nextDir
                } else {
                    // Respawn leader
                    leader.currentGrid = SIMD3<Int>(
                        Int.random(in: 2..<(gridBounds.x - 2)),
                        Int.random(in: 2..<(gridBounds.y - 2)),
                        Int.random(in: 2..<(gridBounds.z - 2))
                    )
                    leader.colorIndex = (leader.colorIndex + 1) % 6
                    pipes[i] = leader
                    continue
                }
            }

            let hasTurn = (nextDir != leader.currentDir)
            let isBall: Bool
            switch settings.jointType {
            case .ball: isBall = true
            case .elbow: isBall = false
            case .mixed: isBall = Bool.random()
            }

            let p1 = SIMD3<Float>(Float(leader.currentGrid.x), Float(leader.currentGrid.y), Float(leader.currentGrid.z))
            let p2 = SIMD3<Float>(Float(nextGrid.x), Float(nextGrid.y), Float(nextGrid.z))
            let seg = PipeSegment3D(p1: p1, p2: p2, colorIndex: leader.colorIndex, hasJoint: hasTurn, isBallJoint: isBall)

            leader.segments.append(seg)
            leader.currentGrid = nextGrid
            leader.currentDir = nextDir
            pipes[i] = leader
            totalSegments += 1
        }
    }
}

// MARK: - Mystify Models

public struct MystifySettings: Equatable {
    public var polygonCount: Int
    public var lineCount: Int

    public init(polygonCount: Int = 2, lineCount: Int = 10) {
        self.polygonCount = max(1, min(8, polygonCount))
        self.lineCount = max(4, min(30, lineCount))
    }
}

public struct MystifyVertex {
    public var x: Double
    public var y: Double
    public var vx: Double
    public var vy: Double
}

public struct MystifyPolygon {
    public var vertices: [MystifyVertex]
    public var history: [[CGPoint]]
    public var colorHue: Double
    public var maxLines: Int

    public init(vertexCount: Int = 4, bounds: CGSize, maxLines: Int = 10, colorHue: Double = 0.0) {
        self.maxLines = maxLines
        self.colorHue = colorHue
        self.history = []
        self.vertices = (0..<vertexCount).map { _ in
            let x = Double.random(in: 50...max(100, Double(bounds.width) - 50))
            let y = Double.random(in: 50...max(100, Double(bounds.height) - 50))
            let vx = Double.random(in: 2.0...5.0) * (Bool.random() ? 1 : -1)
            let vy = Double.random(in: 2.0...5.0) * (Bool.random() ? 1 : -1)
            return MystifyVertex(x: x, y: y, vx: vx, vy: vy)
        }
    }

    public mutating func step(bounds: CGSize) {
        let bw = max(100.0, Double(bounds.width))
        let bh = max(100.0, Double(bounds.height))

        var currentPoints: [CGPoint] = []

        for i in 0..<vertices.count {
            vertices[i].x += vertices[i].vx
            vertices[i].y += vertices[i].vy

            if vertices[i].x <= 0 {
                vertices[i].x = 0
                vertices[i].vx = abs(vertices[i].vx)
            } else if vertices[i].x >= bw {
                vertices[i].x = bw
                vertices[i].vx = -abs(vertices[i].vx)
            }

            if vertices[i].y <= 0 {
                vertices[i].y = 0
                vertices[i].vy = abs(vertices[i].vy)
            } else if vertices[i].y >= bh {
                vertices[i].y = bh
                vertices[i].vy = -abs(vertices[i].vy)
            }

            currentPoints.append(CGPoint(x: vertices[i].x, y: vertices[i].y))
        }

        history.insert(currentPoints, at: 0)
        if history.count > maxLines {
            history.removeLast()
        }

        colorHue = (colorHue + 0.005).truncatingRemainder(dividingBy: 1.0)
    }
}

public struct MystifyEngine {
    public var settings: MystifySettings
    public var polygons: [MystifyPolygon]

    public init(settings: MystifySettings = MystifySettings(), bounds: CGSize = CGSize(width: 800, height: 600)) {
        self.settings = settings
        self.polygons = (0..<settings.polygonCount).map { idx in
            let hue = Double(idx) / Double(settings.polygonCount)
            return MystifyPolygon(vertexCount: 4, bounds: bounds, maxLines: settings.lineCount, colorHue: hue)
        }
    }

    public mutating func step(bounds: CGSize) {
        for i in 0..<polygons.count {
            polygons[i].step(bounds: bounds)
        }
    }
}

// MARK: - Windows XP 3D Logo Models

public struct XP3DLogoSettings: Equatable {
    public var speed: Double
    public var logoSize: Double

    public init(speed: Double = 1.0, logoSize: Double = 120.0) {
        self.speed = max(0.2, min(3.0, speed))
        self.logoSize = max(60.0, min(240.0, logoSize))
    }
}

public struct XP3DLogoState {
    public var position: CGPoint
    public var velocity: CGPoint
    public var rotationAngle: Double
    public var rotationSpeed: Double
    public var settings: XP3DLogoSettings

    public init(settings: XP3DLogoSettings = XP3DLogoSettings(), bounds: CGSize = CGSize(width: 800, height: 600)) {
        self.settings = settings
        self.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        self.velocity = CGPoint(x: 120.0 * settings.speed, y: 90.0 * settings.speed)
        self.rotationAngle = 0.0
        self.rotationSpeed = 45.0 * settings.speed
    }

    public mutating func update(deltaTime: Double, bounds: CGSize) {
        position.x += velocity.x * CGFloat(deltaTime)
        position.y += velocity.y * CGFloat(deltaTime)
        rotationAngle += rotationSpeed * deltaTime

        let radius = CGFloat(settings.logoSize / 2)
        let minX = radius
        let maxX = max(radius, bounds.width - radius)
        let minY = radius
        let maxY = max(radius, bounds.height - radius)

        if position.x <= minX {
            position.x = minX
            velocity.x = abs(velocity.x)
        } else if position.x >= maxX {
            position.x = maxX
            velocity.x = -abs(velocity.x)
        }

        if position.y <= minY {
            position.y = minY
            velocity.y = abs(velocity.y)
        } else if position.y >= maxY {
            position.y = maxY
            velocity.y = -abs(velocity.y)
        }
    }
}
