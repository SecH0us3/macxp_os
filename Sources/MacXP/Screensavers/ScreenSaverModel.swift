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
