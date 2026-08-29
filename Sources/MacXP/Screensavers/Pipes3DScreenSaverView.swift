import SwiftUI

public struct Pipes3DScreenSaverView: View {
    public var settings: Pipes3DSettings
    public var isMiniPreview: Bool

    @State private var engine: Pipes3DEngine
    @State private var lastDate: Date = Date()
    @State private var stepTimer: Double = 0.0

    private static let pipeColors: [Color] = [
        Color(red: 0.85, green: 0.15, blue: 0.15), // Red
        Color(red: 0.15, green: 0.75, blue: 0.20), // Green
        Color(red: 0.20, green: 0.45, blue: 0.90), // Blue
        Color(red: 0.95, green: 0.75, blue: 0.10), // Yellow
        Color(red: 0.80, green: 0.20, blue: 0.80), // Magenta
        Color(red: 0.10, green: 0.80, blue: 0.80)  // Cyan
    ]

    public init(settings: Pipes3DSettings = Pipes3DSettings(), isMiniPreview: Bool = false) {
        self.settings = settings
        self.isMiniPreview = isMiniPreview
        self._engine = State(initialValue: Pipes3DEngine(settings: settings))
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                let pipeRadius = CGFloat(isMiniPreview ? max(3.0, settings.pipeRadius * 0.4) : settings.pipeRadius)
                let gxCount = Float(engine.gridBounds.x)
                let gyCount = Float(engine.gridBounds.y)

                let scaleX = Float(size.width) / (gxCount + 1.0)
                let scaleY = Float(size.height) / (gyCount + 1.0)

                for leader in engine.pipes {
                    let color = Self.pipeColors[leader.colorIndex % Self.pipeColors.count]

                    for seg in leader.segments {
                        let sx1 = CGFloat((seg.p1.x + 1.0) * scaleX)
                        let sy1 = CGFloat((seg.p1.y + 1.0) * scaleY)
                        let sx2 = CGFloat((seg.p2.x + 1.0) * scaleX)
                        let sy2 = CGFloat((seg.p2.y + 1.0) * scaleY)

                        var path = Path()
                        path.move(to: CGPoint(x: sx1, y: sy1))
                        path.addLine(to: CGPoint(x: sx2, y: sy2))

                        // Draw dark outer cylinder shadow
                        context.stroke(
                            path,
                            with: .color(color.opacity(0.85)),
                            style: StrokeStyle(lineWidth: pipeRadius * 2.0, lineCap: .round, lineJoin: .round)
                        )

                        // Draw specular highlight stripe
                        context.stroke(
                            path,
                            with: .color(Color.white.opacity(0.40)),
                            style: StrokeStyle(lineWidth: pipeRadius * 0.7, lineCap: .round, lineJoin: .round)
                        )

                        // Draw ball joint if turn
                        if seg.hasJoint && seg.isBallJoint {
                            let jointRadius = pipeRadius * 1.35
                            let jointRect = CGRect(x: sx2 - jointRadius, y: sy2 - jointRadius, width: jointRadius * 2, height: jointRadius * 2)
                            context.fill(Path(ellipseIn: jointRect), with: .color(color))
                            
                            // Specular shine on sphere
                            let shineRect = CGRect(x: sx2 - jointRadius * 0.4, y: sy2 - jointRadius * 0.6, width: jointRadius * 0.6, height: jointRadius * 0.6)
                            context.fill(Path(ellipseIn: shineRect), with: .color(Color.white.opacity(0.55)))
                        }
                    }
                }
            }
            .onChange(of: timeline.date) { newDate in
                let dt = min(0.1, newDate.timeIntervalSince(lastDate))
                lastDate = newDate
                stepTimer += dt
                if stepTimer >= (isMiniPreview ? 0.08 : 0.04) {
                    stepTimer = 0.0
                    engine.step()
                }
            }
        }
        .background(Color.black)
    }
}
