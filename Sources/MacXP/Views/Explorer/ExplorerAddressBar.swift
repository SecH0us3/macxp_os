import SwiftUI

public struct ExplorerAddressBar: View {
    public var currentPath: String
    public var onNavigate: (String) -> Void

    @State private var inputText: String = ""
    @State private var isGoHovered: Bool = false

    public init(currentPath: String, onNavigate: @escaping (String) -> Void) {
        self.currentPath = currentPath
        self.onNavigate = onNavigate
        _inputText = State(initialValue: FileSystemService.shared.formatPathForDisplay(currentPath))
    }

    public var body: some View {
        HStack(spacing: 6) {
            // "Address" Label
            Text("Address")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.35))
                .padding(.leading, 6)

            // Address Input Combo Box
            HStack(spacing: 4) {
                // Folder / Location Icon
                Image(systemName: iconForCurrentPath)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                    .padding(.leading, 4)

                // Editable Path Text Field
                TextField("", text: $inputText, onCommit: {
                    commitNavigation()
                })
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)

                // Dropdown Chevron
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 6))
                    .foregroundColor(Color.black.opacity(0.6))
                    .padding(.trailing, 6)
            }
            .frame(height: 22)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.50, blue: 0.50),
                                Color(red: 0.75, green: 0.75, blue: 0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )

            // Green "Go" Button
            Button(action: {
                commitNavigation()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.50, blue: 0.15))

                    Text("Go")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.15))
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    LinearGradient(
                        colors: isGoHovered ?
                            [Color(red: 0.92, green: 0.98, blue: 0.90), Color(red: 0.75, green: 0.92, blue: 0.70)] :
                            [Color(red: 0.95, green: 1.0, blue: 0.95), Color(red: 0.85, green: 0.95, blue: 0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color(red: 0.25, green: 0.65, blue: 0.25), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isGoHovered = hovering
            }
            .padding(.trailing, 6)
        }
        .frame(height: 28)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.93),
                    Color(red: 0.90, green: 0.89, blue: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 0.80, green: 0.78, blue: 0.75))
            }
        )
        .onChange(of: currentPath) { newPath in
            inputText = FileSystemService.shared.formatPathForDisplay(newPath)
        }
    }

    private func commitNavigation() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onNavigate(trimmed)
        }
    }

    private var iconForCurrentPath: String {
        if currentPath == "computer://" || currentPath.caseInsensitiveCompare("My Computer") == .orderedSame {
            return "desktopcomputer"
        }
        if currentPath == "/" || currentPath == "C:\\" {
            return "internaldrive.fill"
        }
        return "folder.fill"
    }
}
