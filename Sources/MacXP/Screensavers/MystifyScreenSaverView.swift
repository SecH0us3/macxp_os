import SwiftUI

public struct MystifyScreenSaverView: View {
    public var settings: MystifySettings
    public var isMiniPreview: Bool

    @State private var engine: MystifyEngine
    @State private var lastDate: Date = Date()

    public init(settings: MystifySettings = MystifySettings(), isMiniPreview: Bool = false) {
        self.settings = settings
        self.isMiniPreview = isMiniPreview
        let bounds = isMiniPreview ? CGSize(width: 200, height: 150) : CGSize(width: 1200, height: 800)
        self._engine = State(initialValue: MystifyEngine(settings: settings, bounds: bounds))
    }

    public var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                    for poly in engine.polygons {
                        for (idx, linePoints) in poly.history.enumerated() {
                            guard linePoints.count >= 2 else { continue }

                            var path = Path()
                            path.move(to: linePoints[0])
                            for p in linePoints.dropFirst() {
                                path.addLine(to: p)
                            }
                            path.closeSubpath()

                            let fade = 1.0 - (Double(idx) / Double(poly.maxLines))
                            let hue = (poly.colorHue + Double(idx) * 0.02).truncatingRemainder(dividingBy: 1.0)
                            let color = Color(hue: hue, saturation: 0.9, brightness: 1.0).opacity(fade * 0.85)

                            context.stroke(
                                path,
                                with: .color(color),
                                lineWidth: isMiniPreview ? 1.0 : 1.5
                            )
                        }
                    }
                }
                .onChange(of: timeline.date) { newDate in
                    engine.step(bounds: geo.size)
                }
            }
        }
        .background(Color.black)
    }
}
