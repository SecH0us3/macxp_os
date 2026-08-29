import SwiftUI

public struct StarfieldScreenSaverView: View {
    public var settings: StarfieldSettings
    public var isMiniPreview: Bool

    @State private var engine: StarfieldEngine
    @State private var lastDate: Date = Date()

    public init(settings: StarfieldSettings = StarfieldSettings(), isMiniPreview: Bool = false) {
        self.settings = settings
        self.isMiniPreview = isMiniPreview
        let adjustedSettings = isMiniPreview ?
            StarfieldSettings(starCount: min(150, settings.starCount), speed: settings.speed, warpTrail: settings.warpTrail) :
            settings
        self._engine = State(initialValue: StarfieldEngine(settings: adjustedSettings))
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                let cx = size.width / 2.0
                let cy = size.height / 2.0

                for star in engine.stars {
                    guard star.z > 0 else { continue }
                    let k = 400.0 / star.z
                    let sx = cx + star.x * k
                    let sy = cy + star.y * k

                    let pk = 400.0 / max(1.0, star.pz)
                    let psx = cx + star.x * pk
                    let psy = cy + star.y * pk

                    if sx >= 0 && sx <= size.width && sy >= 0 && sy <= size.height {
                        let brightness = min(1.0, max(0.1, (1000.0 - star.z) / 800.0))
                        let starRadius = max(0.6, (1.0 - star.z / 1000.0) * (isMiniPreview ? 2.0 : 3.5))

                        if settings.warpTrail && (abs(sx - psx) > 0.5 || abs(sy - psy) > 0.5) {
                            var trail = Path()
                            trail.move(to: CGPoint(x: psx, y: psy))
                            trail.addLine(to: CGPoint(x: sx, y: sy))
                            context.stroke(
                                trail,
                                with: .color(Color.white.opacity(brightness)),
                                lineWidth: starRadius * 0.8
                            )
                        } else {
                            let rect = CGRect(x: sx - starRadius, y: sy - starRadius, width: starRadius * 2, height: starRadius * 2)
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(Color.white.opacity(brightness))
                            )
                        }
                    }
                }
            }
            .onChange(of: timeline.date) { newDate in
                let dt = min(0.1, newDate.timeIntervalSince(lastDate))
                lastDate = newDate
                engine.update(deltaTime: dt > 0 ? dt : 0.016)
            }
        }
        .background(Color.black)
    }
}
