import SwiftUI

public class FolderOptionsSettings: ObservableObject {
    public static let shared = FolderOptionsSettings()

    @Published public var showHiddenFiles: Bool = false
    @Published public var hideExtensions: Bool = true
    @Published public var useClassicFolders: Bool = false
    @Published public var openInNewWindow: Bool = false

    public init() {}
}

public struct FolderOptionsDialog: View {
    @ObservedObject public var settings = FolderOptionsSettings.shared
    public var onClose: () -> Void
    @State private var selectedTab: Int = 0

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Folder Options")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.33, blue: 0.92), Color(red: 0.05, green: 0.20, blue: 0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Tabs
            HStack(spacing: 2) {
                tabBtn("General", index: 0)
                tabBtn("View", index: 1)
                tabBtn("File Types", index: 2)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Pane
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 12) {
                    if selectedTab == 0 {
                        // General Tab
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tasks:")
                                .font(.system(size: 11, weight: .bold))
                            Toggle("Show common tasks in folders", isOn: Binding(
                                get: { !settings.useClassicFolders },
                                set: { settings.useClassicFolders = !$0 }
                            ))
                            .font(.system(size: 11))

                            Divider()

                            Text("Browse folders:")
                                .font(.system(size: 11, weight: .bold))
                            Toggle("Open each folder in its own window", isOn: $settings.openInNewWindow)
                                .font(.system(size: 11))
                        }
                    } else if selectedTab == 1 {
                        // View Tab
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Advanced settings:")
                                .font(.system(size: 11, weight: .bold))

                            Toggle("Show hidden files and folders", isOn: $settings.showHiddenFiles)
                                .font(.system(size: 11))

                            Toggle("Hide extensions for known file types", isOn: $settings.hideExtensions)
                                .font(.system(size: 11))
                        }
                    } else {
                        // File Types Tab
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Registered file types:")
                                .font(.system(size: 11, weight: .bold))
                            List {
                                Text("TXT - Text Document")
                                Text("BMP - Bitmap Image")
                                Text("PNG - PNG Image")
                                Text("WAV - Waveform Audio")
                                Text("EXE - Application")
                            }
                            .frame(height: 110)
                            .background(Color.white)
                            .overlay(Rectangle().stroke(Color.gray, lineWidth: 1))
                        }
                    }
                    Spacer()
                }
                .padding(12)
            }
            .padding(.horizontal, 8)
            .padding(.top, -1)

            // Buttons
            HStack(spacing: 8) {
                Spacer()
                Button("OK", action: onClose)
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 70, height: 22)
                    .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1))
                    .buttonStyle(PlainButtonStyle())

                Button("Cancel", action: onClose)
                    .font(.system(size: 11))
                    .frame(width: 70, height: 22)
                    .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1))
                    .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 340, height: 320)
        .background(Color(red: 0.93, green: 0.93, blue: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0.0, green: 0.2, blue: 0.7), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 2, y: 2)
    }

    private func tabBtn(_ title: String, index: Int) -> some View {
        let isSel = selectedTab == index
        return Button(action: { selectedTab = index }) {
            Text(title)
                .font(.system(size: 11, weight: isSel ? .bold : .regular))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSel ? Color(red: 0.94, green: 0.94, blue: 0.94) : Color(red: 0.88, green: 0.88, blue: 0.88))
                .clipShape(TopRoundedRectangle(radius: 3))
                .overlay(TopRoundedRectangle(radius: 3).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
