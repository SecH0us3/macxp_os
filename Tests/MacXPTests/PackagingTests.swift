import XCTest
import Foundation
@testable import MacXP

final class PackagingTests: XCTestCase {
    
    private var rootDirectoryURL: URL {
        // Locate repository root based on current file location
        let currentFileURL = URL(fileURLWithPath: #file)
        // Tests/MacXPTests/PackagingTests.swift -> 3 levels up to root
        return currentFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    
    func testInfoPlistStructureAndContent() throws {
        let infoPlistURL = rootDirectoryURL.appendingPathComponent("Resources/Info.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: infoPlistURL.path), "Info.plist should exist at Resources/Info.plist")
        
        let data = try Data(contentsOf: infoPlistURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format) as? [String: Any] else {
            XCTFail("Info.plist could not be deserialized as a dictionary")
            return
        }
        
        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, "com.macxp.os", "Bundle identifier must be com.macxp.os")
        XCTAssertEqual(plist["CFBundleName"] as? String, "MacXP", "Bundle name must be MacXP")
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, "MacXP", "Executable name must be MacXP")
        XCTAssertEqual(plist["CFBundlePackageType"] as? String, "APPL", "Package type must be APPL")
        XCTAssertEqual(plist["CFBundleIconFile"] as? String, "AppIcon", "Icon file must be AppIcon")
        
        let highRes = plist["NSHighResolutionCapable"]
        if let boolVal = highRes as? Bool {
            XCTAssertTrue(boolVal, "NSHighResolutionCapable should be true")
        } else if let numVal = highRes as? NSNumber {
            XCTAssertEqual(numVal.boolValue, true, "NSHighResolutionCapable should be true")
        } else {
            XCTFail("NSHighResolutionCapable key missing or invalid in Info.plist")
        }
    }
    
    func testAppIconIcnsHeaderAndExistence() throws {
        let iconURL = rootDirectoryURL.appendingPathComponent("Resources/AppIcon.icns")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iconURL.path), "Resources/AppIcon.icns must exist")
        
        let iconData = try Data(contentsOf: iconURL)
        XCTAssertGreaterThan(iconData.count, 1024, "AppIcon.icns should be larger than 1KB")
        
        // Check ICNS magic header 'icns' (0x69 0x63 0x6e 0x73)
        let header = [UInt8](iconData.prefix(4))
        let expectedHeader: [UInt8] = [0x69, 0x63, 0x6e, 0x73] // 'i', 'c', 'n', 's'
        XCTAssertEqual(header, expectedHeader, "AppIcon.icns must begin with 'icns' magic byte header")
    }
    
    func testMakefileTargets() throws {
        let makefileURL = rootDirectoryURL.appendingPathComponent("Makefile")
        XCTAssertTrue(FileManager.default.fileExists(atPath: makefileURL.path), "Makefile must exist at repo root")
        
        let makefileContent = try String(contentsOf: makefileURL, encoding: .utf8)
        XCTAssertTrue(makefileContent.contains(".PHONY:"), "Makefile must declare .PHONY")
        
        let requiredTargets = ["all", "build", "test", "app", "dmg", "run", "clean"]
        for target in requiredTargets {
            XCTAssertTrue(makefileContent.contains("\(target):"), "Makefile must include '\(target):' target")
        }
    }
    
    func testBuildAppScriptContentAndExecutable() throws {
        let scriptURL = rootDirectoryURL.appendingPathComponent("scripts/build_app.sh")
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path), "scripts/build_app.sh must exist")
        
        let attributes = try FileManager.default.attributesOfItem(atPath: scriptURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        let isExecutable = (permissions?.intValue ?? 0) & 0o111 != 0
        XCTAssertTrue(isExecutable, "scripts/build_app.sh must have executable permissions")
        
        let scriptContent = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(scriptContent.contains("swift build -c release"), "Script must compile swift package in release mode")
        XCTAssertTrue(scriptContent.contains("MacXP.app"), "Script must build MacXP.app bundle")
        XCTAssertTrue(scriptContent.contains("Info.plist"), "Script must copy Info.plist")
        XCTAssertTrue(scriptContent.contains("AppIcon.icns"), "Script must copy or handle AppIcon.icns")
    }
    
    func testBuildDmgScriptContentAndExecutable() throws {
        let scriptURL = rootDirectoryURL.appendingPathComponent("scripts/build_dmg.sh")
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path), "scripts/build_dmg.sh must exist")
        
        let attributes = try FileManager.default.attributesOfItem(atPath: scriptURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        let isExecutable = (permissions?.intValue ?? 0) & 0o111 != 0
        XCTAssertTrue(isExecutable, "scripts/build_dmg.sh must have executable permissions")
        
        let scriptContent = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(scriptContent.contains("hdiutil create"), "Script must use hdiutil create")
        XCTAssertTrue(scriptContent.contains("MacXP.dmg"), "Script must target MacXP.dmg")
        XCTAssertTrue(scriptContent.contains("/Applications"), "Script must link to /Applications")
    }
    
    func testReadmeDocumentationContents() throws {
        let readmeURL = rootDirectoryURL.appendingPathComponent("README.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: readmeURL.path), "README.md must exist at repo root")
        
        let readmeContent = try String(contentsOf: readmeURL, encoding: .utf8)
        let requiredSections = [
            "Explorer",
            "Start Menu",
            "Taskbar",
            "Notepad",
            "Calculator",
            "Paint",
            "Minesweeper",
            "Sound",
            "Hotkeys",
            "make app",
            "make dmg"
        ]
        
        for section in requiredSections {
            XCTAssertTrue(readmeContent.localizedCaseInsensitiveContains(section), "README.md should mention '\(section)'")
        }
    }
    
    func testBuiltAppBundleStructureIfPresent() throws {
        let appBundleURL = rootDirectoryURL.appendingPathComponent("build/MacXP.app")
        if FileManager.default.fileExists(atPath: appBundleURL.path) {
            let binaryURL = appBundleURL.appendingPathComponent("Contents/MacOS/MacXP")
            let infoPlistURL = appBundleURL.appendingPathComponent("Contents/Info.plist")
            let appIconURL = appBundleURL.appendingPathComponent("Contents/Resources/AppIcon.icns")
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: binaryURL.path), "MacXP executable must exist in .app bundle")
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: binaryURL.path), "MacXP binary must be executable")
            XCTAssertTrue(FileManager.default.fileExists(atPath: infoPlistURL.path), "Info.plist must exist in .app bundle")
            XCTAssertTrue(FileManager.default.fileExists(atPath: appIconURL.path), "AppIcon.icns must exist in .app bundle")
        }
    }
}
