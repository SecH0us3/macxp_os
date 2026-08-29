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
