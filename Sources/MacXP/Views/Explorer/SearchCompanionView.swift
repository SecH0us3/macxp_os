import SwiftUI

public enum SearchCategory: String, CaseIterable, Identifiable {
    case picturesAndMusic = "Pictures, music, or video"
    case documents = "Documents (word processing, spreadsheet, etc.)"
    case allFiles = "All files and folders"
    case computers = "Computers or people"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .picturesAndMusic: return "photo.on.rectangle.angled"
        case .documents: return "doc.text.fill"
        case .allFiles: return "folder.fill"
        case .computers: return "network"
        }
    }
}

public struct RoverPuppyView: View {
    public var isSearching: Bool
    @State private var tailAngle: Double = 0.0
    @State private var eyeBlink: Bool = false
    @State private var bounceOffset: CGFloat = 0.0

    public init(isSearching: Bool = false) {
        self.isSearching = isSearching
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.15)) { timeline in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let cx = w / 2.0
                let cy = h / 2.0 + bounceOffset

                // Shadow
                let shadowRect = CGRect(x: cx - 28, y: cy + 32, width: 56, height: 12)
                context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.18)))

                // Tail (Animated wagging)
                var tail = Path()
                tail.move(to: CGPoint(x: cx - 22, y: cy + 12))
                let tailTip = CGPoint(x: cx - 36 + CGFloat(sin(tailAngle) * 8.0), y: cy - 6 + CGFloat(cos(tailAngle) * 4.0))
                tail.addQuadCurve(to: tailTip, control: CGPoint(x: cx - 32, y: cy + 4))
                context.stroke(tail, with: .color(Color(red: 0.82, green: 0.58, blue: 0.22)), style: StrokeStyle(lineWidth: 6, lineCap: .round))

                // Body (Golden retriever / puppy shape)
                let bodyRect = CGRect(x: cx - 26, y: cy - 4, width: 44, height: 36)
                context.fill(Path(roundedRect: bodyRect, cornerRadius: 16), with: .color(Color(red: 0.94, green: 0.72, blue: 0.32)))

                // Paws
                let frontPaw = CGRect(x: cx + 6, y: cy + 24, width: 12, height: 14)
                let backPaw = CGRect(x: cx - 22, y: cy + 24, width: 12, height: 14)
                context.fill(Path(roundedRect: frontPaw, cornerRadius: 6), with: .color(Color(red: 0.88, green: 0.65, blue: 0.26)))
                context.fill(Path(roundedRect: backPaw, cornerRadius: 6), with: .color(Color(red: 0.88, green: 0.65, blue: 0.26)))

                // Head
                let headRect = CGRect(x: cx - 4, y: cy - 28, width: 34, height: 32)
                context.fill(Path(ellipseIn: headRect), with: .color(Color(red: 0.96, green: 0.76, blue: 0.36)))

                // Floppy Brown Ear
                var ear = Path()
                ear.move(to: CGPoint(x: cx + 4, y: cy - 24))
                ear.addQuadCurve(to: CGPoint(x: cx - 8, y: cy - 4), control: CGPoint(x: cx - 12, y: cy - 18))
                ear.addQuadCurve(to: CGPoint(x: cx + 4, y: cy - 24), control: CGPoint(x: cx - 2, y: cy - 10))
                context.fill(ear, with: .color(Color(red: 0.75, green: 0.48, blue: 0.16)))

                // Muzzle & Black Snout
                let muzzleRect = CGRect(x: cx + 14, y: cy - 18, width: 18, height: 16)
                context.fill(Path(ellipseIn: muzzleRect), with: .color(Color(red: 0.98, green: 0.84, blue: 0.50)))
                let noseRect = CGRect(x: cx + 24, y: cy - 17, width: 7, height: 6)
                context.fill(Path(ellipseIn: noseRect), with: .color(Color.black))

                // Shiny Eye
                if eyeBlink {
                    var eyeLine = Path()
                    eyeLine.move(to: CGPoint(x: cx + 10, y: cy - 18))
                    eyeLine.addLine(to: CGPoint(x: cx + 18, y: cy - 18))
                    context.stroke(eyeLine, with: .color(Color.black), lineWidth: 2)
                } else {
                    let eyeRect = CGRect(x: cx + 11, y: cy - 21, width: 7, height: 7)
                    context.fill(Path(ellipseIn: eyeRect), with: .color(Color.black))
                    let pupilRect = CGRect(x: cx + 14, y: cy - 20, width: 2.5, height: 2.5)
                    context.fill(Path(ellipseIn: pupilRect), with: .color(Color.white))
                }

                // Red Collar
                var collar = Path()
                collar.move(to: CGPoint(x: cx + 2, y: cy - 2))
                collar.addLine(to: CGPoint(x: cx + 20, y: cy + 3))
                context.stroke(collar, with: .color(Color(red: 0.85, green: 0.15, blue: 0.15)), lineWidth: 3.5)
                let tagRect = CGRect(x: cx + 11, y: cy + 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: tagRect), with: .color(Color(red: 0.95, green: 0.80, blue: 0.20)))
            }
            .onChange(of: timeline.date) { _ in
                if isSearching {
                    tailAngle += 0.8
                    bounceOffset = (bounceOffset == 0.0) ? -3.0 : 0.0
                } else {
                    tailAngle = sin(Date().timeIntervalSince1970 * 4.0) * 0.4
                    bounceOffset = 0.0
                    if Int.random(in: 0...20) == 5 {
                        eyeBlink.toggle()
                    }
                }
            }
        }
        .frame(width: 100, height: 90)
    }
}

public struct SearchCompanionView: View {
    @ObservedObject public var viewModel: ExplorerViewModel
    public var onPerformSearch: (String) -> Void

    public init(viewModel: ExplorerViewModel, onPerformSearch: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onPerformSearch = onPerformSearch
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("Search Companion")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.25, blue: 0.55))
                Spacer()
                Button(action: {
                    withAnimation {
                        viewModel.isSearchActive = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(width: 16, height: 16)
                        .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.90, blue: 0.98), Color(red: 0.72, green: 0.80, blue: 0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Rover Dog Animation Box
            VStack(spacing: 4) {
                RoverPuppyView(isSearching: viewModel.isSearchingRunning)
                
                // Speech Balloon
                VStack(alignment: .leading, spacing: 6) {
                    Text("What do you want to search for?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.20, blue: 0.45))

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(SearchCategory.allCases) { cat in
                            HStack(spacing: 6) {
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 0.20, green: 0.40, blue: 0.80))
                                    .frame(width: 14)

                                Text(cat.rawValue)
                                    .font(.system(size: 10, weight: viewModel.searchCategory == cat ? .bold : .regular))
                                    .foregroundColor(Color(red: 0.05, green: 0.20, blue: 0.60))
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.searchCategory = cat
                                SoundManager.shared.play(.navigation)
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color(red: 1.0, green: 0.98, blue: 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 0.90, green: 0.80, blue: 0.45), lineWidth: 1))
            }
            .padding(8)

            // Search Inputs Form
            VStack(alignment: .leading, spacing: 8) {
                Text("All or part of the file name:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)

                TextField("", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 11))
                    .padding(4)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color(red: 0.45, green: 0.60, blue: 0.85), lineWidth: 1))
                    .onSubmit {
                        onPerformSearch(viewModel.searchQuery)
                    }

                HStack {
                    Spacer()
                    Button(action: {
                        onPerformSearch(viewModel.searchQuery)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10))
                            Text("Search")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(width: 76, height: 22)
                        .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            Spacer()
        }
        .frame(width: 210)
        .background(
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.88, blue: 0.98), Color(red: 0.68, green: 0.77, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
