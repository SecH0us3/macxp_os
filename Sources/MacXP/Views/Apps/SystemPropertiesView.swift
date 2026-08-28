import SwiftUI

public struct MacSystemInfo: Equatable {
    public var processorName: String
    public var memoryFormatted: String
    public var osVersion: String
    public var hostName: String
    public var userName: String
    public var windowsVersion: String = "Microsoft Windows XP Professional"
    public var servicePack: String = "Service Pack 3"
    public var productKey: String = "55274-640-0000325-23014"
    
    public init(
        processorName: String,
        memoryFormatted: String,
        osVersion: String,
        hostName: String,
        userName: String,
        windowsVersion: String = "Microsoft Windows XP Professional",
        servicePack: String = "Service Pack 3",
        productKey: String = "55274-640-0000325-23014"
    ) {
        self.processorName = processorName
        self.memoryFormatted = memoryFormatted
        self.osVersion = osVersion
        self.hostName = hostName
        self.userName = userName
        self.windowsVersion = windowsVersion
        self.servicePack = servicePack
        self.productKey = productKey
    }
}

public class SystemInfoProvider {
    public static func current() -> MacSystemInfo {
        let memBytes = ProcessInfo.processInfo.physicalMemory
        let memGB = Double(memBytes) / 1_073_741_824.0
        let memStr = String(format: "%.2f GB of RAM", memGB)
        
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var cpuName = "Apple Silicon"
        if size > 0 {
            var brand = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
            let brandStr = String(cString: brand).trimmingCharacters(in: .whitespacesAndNewlines)
            if !brandStr.isEmpty {
                cpuName = brandStr
            }
        }
        
        #if arch(arm64)
        if cpuName == "Apple Silicon" {
            cpuName = "Apple Silicon Processor"
        }
        #endif
        
        let osVer = ProcessInfo.processInfo.operatingSystemVersionString
        let host = ProcessInfo.processInfo.hostName
        #if os(macOS)
        let full = NSFullUserName()
        let short = NSUserName()
        let user = !full.isEmpty ? full : (!short.isEmpty ? short : "MacXP User")
        #else
        let user = "MacXP User"
        #endif
        
        return MacSystemInfo(
            processorName: cpuName,
            memoryFormatted: memStr,
            osVersion: osVer,
            hostName: host,
            userName: user
        )
    }
}

public struct SystemPropertiesView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @State private var selectedTab: Int = 0
    private let systemInfo = SystemInfoProvider.current()
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    private let tabNames = [
        "General",
        "Computer Name",
        "Hardware",
        "Advanced",
        "System Restore",
        "Automatic Updates",
        "Remote"
    ]
    
    public var body: some View {
        VStack(spacing: 8) {
            // Tab Header Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(0..<tabNames.count, id: \.self) { index in
                        tabButton(title: tabNames[index], index: index)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
            
            // Tab Content Box
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color(red: 0.7, green: 0.7, blue: 0.7), lineWidth: 1)
                    )
                
                switch selectedTab {
                case 0:
                    generalTabView
                case 1:
                    computerNameTabView
                default:
                    genericTabView(title: tabNames[selectedTab])
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Action Buttons
            HStack(spacing: 8) {
                Spacer()
                dialogButton(title: "OK") {
                    windowManager.closeWindow(id: window.id)
                }
                dialogButton(title: "Cancel") {
                    windowManager.closeWindow(id: window.id)
                }
                dialogButton(title: "Apply", isEnabled: false) {}
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        let isSelected = (selectedTab == index)
        return Button(action: {
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected ? Color(red: 0.94, green: 0.94, blue: 0.94) : Color(red: 0.88, green: 0.88, blue: 0.88)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color(red: 0.65, green: 0.65, blue: 0.65), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - General Tab
    private var generalTabView: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                // Windows XP Logo
                VStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                        .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                    
                    Text("Windows XP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.65))
                }
                .frame(width: 80)
                .padding(.top, 12)
                
                // Specifications Text
                VStack(alignment: .leading, spacing: 12) {
                    // System Section
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System:")
                            .font(.system(size: 11, weight: .bold))
                        Text(systemInfo.windowsVersion)
                            .font(.system(size: 11))
                        Text("Version 2002")
                            .font(.system(size: 11))
                        Text(systemInfo.servicePack)
                            .font(.system(size: 11))
                        Text("Host: \(systemInfo.osVersion)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    // Registered To Section
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Registered to:")
                            .font(.system(size: 11, weight: .bold))
                        Text(systemInfo.userName)
                            .font(.system(size: 11))
                        Text("MacXP Workstation")
                            .font(.system(size: 11))
                        Text(systemInfo.productKey)
                            .font(.system(size: 11))
                    }
                    
                    Divider()
                    
                    // Computer Hardware Section
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Computer:")
                            .font(.system(size: 11, weight: .bold))
                        Text(systemInfo.processorName)
                            .font(.system(size: 11))
                        Text(systemInfo.memoryFormatted)
                            .font(.system(size: 11))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
                .padding(.top, 8)
            }
            .padding(12)
        }
    }
    
    // MARK: - Computer Name Tab
    private var computerNameTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Windows uses the following information to identify your computer on the network.")
                .font(.system(size: 11))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Computer description:")
                        .font(.system(size: 11))
                        .frame(width: 140, alignment: .leading)
                    Text("MacXP Workstation")
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Full computer name:")
                        .font(.system(size: 11))
                        .frame(width: 140, alignment: .leading)
                    Text(systemInfo.hostName)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Workgroup:")
                        .font(.system(size: 11))
                        .frame(width: 140, alignment: .leading)
                    Text("WORKGROUP")
                        .font(.system(size: 11))
                }
            }
            .padding(8)
            .background(Color.white)
            .border(Color.gray.opacity(0.5), width: 1)
            
            Spacer()
        }
        .padding(16)
    }
    
    private func genericTabView(title: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Text("\(title) Settings")
                .font(.system(size: 13, weight: .bold))
            Text("These settings are managed automatically by macOS subsystem.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(16)
    }
    
    private func dialogButton(title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(isEnabled ? .black : .gray)
                .frame(width: 72, height: 22)
                .background(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.88, green: 0.88, blue: 0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color(red: 0.0, green: 0.2, blue: 0.6), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}
