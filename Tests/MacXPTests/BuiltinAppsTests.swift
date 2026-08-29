import XCTest
@testable import MacXP

final class BuiltinAppsTests: XCTestCase {

    // MARK: - 1. ShellService Tests
    
    func testShellServiceDosVer() {
        let shell = ShellService()
        let result = shell.executeDosCommand("ver")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("Microsoft Windows XP [Version 5.1.2600]"))
    }
    
    func testShellServiceDosEcho() {
        let shell = ShellService()
        let result1 = shell.executeDosCommand("echo Hello World")
        XCTAssertEqual(result1, "Hello World")
        
        let result2 = shell.executeDosCommand("echo")
        XCTAssertEqual(result2, "ECHO is on.")
    }
    
    func testShellServiceDosHelp() {
        let shell = ShellService()
        let result = shell.executeDosCommand("help")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("CD"))
        XCTAssertTrue(result!.contains("CLS"))
        XCTAssertTrue(result!.contains("DIR"))
        XCTAssertTrue(result!.contains("ECHO"))
        XCTAssertTrue(result!.contains("EXIT"))
        XCTAssertTrue(result!.contains("TYPE"))
        XCTAssertTrue(result!.contains("VER"))
    }
    
    func testShellServiceDosPathMapping() {
        let shell = ShellService()
        let unixPath = "/Users/alex/Documents"
        let dosPath = shell.convertToDosPath(unixPath: unixPath)
        XCTAssertTrue(dosPath.hasPrefix("C:\\"))
        XCTAssertTrue(dosPath.contains("Documents"))
        
        let convertedUnix = shell.convertToUnixPath(dosPath: dosPath)
        XCTAssertEqual(convertedUnix, unixPath)
        
        // Root path
        let rootDos = shell.convertToDosPath(unixPath: "/")
        XCTAssertEqual(rootDos, "C:\\")
        let rootUnix = shell.convertToUnixPath(dosPath: "C:\\")
        XCTAssertEqual(rootUnix, "/")
    }
    
    func testShellServiceDosCdAndDir() {
        let shell = ShellService()
        let tempDir = FileManager.default.temporaryDirectory.path
        let cdResult = shell.executeDosCommand("cd \(tempDir)")
        XCTAssertEqual(cdResult, "")
        XCTAssertEqual(shell.currentUnixDirectory, tempDir)
        
        let dirResult = shell.executeDosCommand("dir")
        XCTAssertNotNil(dirResult)
        XCTAssertTrue(dirResult!.contains("Volume in drive C"))
        XCTAssertTrue(dirResult!.contains("Directory of"))
        
        // dir with Unix path
        let dirTmp = shell.executeDosCommand("dir /tmp")
        XCTAssertNotNil(dirTmp)
        XCTAssertTrue(dirTmp!.contains("Directory of"))
        
        // dir with root Unix path
        let dirRoot = shell.executeDosCommand("dir /")
        XCTAssertNotNil(dirRoot)
        XCTAssertTrue(dirRoot!.contains("Directory of C:\\"))
        
        // dir with Windows path
        let dirWin = shell.executeDosCommand("dir C:\\Users")
        XCTAssertNotNil(dirWin)
        XCTAssertTrue(dirWin!.contains("Directory of C:\\Users") || dirWin!.contains("File Not Found"))
        
        // Invalid CD
        let invalidCd = shell.executeDosCommand("cd /non_existent_directory_xyz_123")
        XCTAssertEqual(invalidCd, "The system cannot find the path specified.")
    }
    
    func testShellServiceDosTypeFile() throws {
        let shell = ShellService()
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_macxp_\(UUID().uuidString).txt")
        try "Hello MacXP DOS Type".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let typeResult = shell.executeDosCommand("type \(tempFile.path)")
        XCTAssertEqual(typeResult, "Hello MacXP DOS Type")
        
        // Type missing file
        let missingResult = shell.executeDosCommand("type non_existent_file_xyz.txt")
        XCTAssertEqual(missingResult, "The system cannot find the file specified.")
    }
    
    func testShellServiceHistoryNavigation() {
        let shell = ShellService()
        shell.recordCommand("dir")
        shell.recordCommand("echo test")
        shell.recordCommand("ver")
        
        XCTAssertEqual(shell.navigateHistory(direction: .previous), "ver")
        XCTAssertEqual(shell.navigateHistory(direction: .previous), "echo test")
        XCTAssertEqual(shell.navigateHistory(direction: .previous), "dir")
        XCTAssertEqual(shell.navigateHistory(direction: .next), "echo test")
        XCTAssertEqual(shell.navigateHistory(direction: .next), "ver")
    }
    
    func testShellServiceUnixProcessExecution() {
        let shell = ShellService()
        let exp = expectation(description: "Execute Unix command")
        
        shell.executeCommand("echo 'Unix Shell Working'") { output, isError in
            XCTAssertFalse(isError)
            XCTAssertTrue(output.contains("Unix Shell Working"))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }

    func testShellServiceUnixProcessLargeOutputNoDeadlock() {
        let shell = ShellService()
        let exp = expectation(description: "Execute Unix command with large output")
        
        // Output > 100KB to ensure pipe buffers do not deadlock
        shell.executeCommand("python3 -c \"print('A' * 128000)\"") { output, isError in
            XCTAssertFalse(isError)
            XCTAssertEqual(output.count, 128000)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }

    // MARK: - 2. Notepad Model Tests
    
    func testNotepadViewModelInitialState() {
        let model = NotepadViewModel()
        XCTAssertEqual(model.text, "")
        XCTAssertFalse(model.isDirty)
        XCTAssertNil(model.fileURL)
        XCTAssertTrue(model.isWordWrap)
        XCTAssertTrue(model.isStatusBarVisible)
        XCTAssertEqual(model.lineAndColumn, "Ln 1, Col 1")
    }
    
    func testNotepadViewModelCursorTracking() {
        let model = NotepadViewModel()
        model.text = "Hello\nWorld\nMacXP"
        
        // Character at index 8: 'r' in World (line 2, col 3)
        model.updateCursorPosition(charIndex: 8)
        XCTAssertEqual(model.lineAndColumn, "Ln 2, Col 3")
    }
    
    func testNotepadViewModelDateTimeInsertion() {
        let model = NotepadViewModel()
        model.text = "Notes: "
        model.insertDateTime()
        XCTAssertTrue(model.text.count > 10)
        XCTAssertTrue(model.isDirty)
    }
    
    func testNotepadViewModelFileSaveAndLoad() throws {
        let model = NotepadViewModel()
        model.text = "Authentic Windows XP Notepad text file content."
        
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("notepad_\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let saveSuccess = model.save(to: tempFile)
        XCTAssertTrue(saveSuccess)
        XCTAssertFalse(model.isDirty)
        XCTAssertEqual(model.fileURL, tempFile)
        
        let loadedModel = NotepadViewModel()
        let loadSuccess = loadedModel.load(from: tempFile)
        XCTAssertTrue(loadSuccess)
        XCTAssertEqual(loadedModel.text, "Authentic Windows XP Notepad text file content.")
        XCTAssertFalse(loadedModel.isDirty)
        
        // New document resets
        loadedModel.newDocument()
        XCTAssertEqual(loadedModel.text, "")
        XCTAssertNil(loadedModel.fileURL)
        XCTAssertFalse(loadedModel.isDirty)
    }

    // MARK: - 3. Calculator Engine Tests
    
    func testCalculatorBasicArithmetic() {
        let calc = CalculatorEngine()
        
        // 7 + 8 = 15
        calc.inputDigit("7")
        calc.setOperator(.add)
        calc.inputDigit("8")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "15")
        
        // 15 - 5 = 10
        calc.setOperator(.subtract)
        calc.inputDigit("5")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "10")
        
        // 10 * 3 = 30
        calc.setOperator(.multiply)
        calc.inputDigit("3")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "30")
        
        // 30 / 6 = 5
        calc.setOperator(.divide)
        calc.inputDigit("6")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "5")
    }
    
    func testCalculatorChainedOperations() {
        let calc = CalculatorEngine()
        
        // 2 + 3 + 4 = 9
        calc.inputDigit("2")
        calc.setOperator(.add)
        calc.inputDigit("3")
        calc.setOperator(.add) // Should calculate 2+3 = 5 and set op to +
        XCTAssertEqual(calc.displayValue, "5")
        calc.inputDigit("4")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "9")
    }
    
    func testCalculatorUnaryOperations() {
        let calc = CalculatorEngine()
        
        // sqrt(25) = 5
        calc.inputDigit("2")
        calc.inputDigit("5")
        calc.squareRoot()
        XCTAssertEqual(calc.displayValue, "5")
        
        // 1/x (4) = 0.25
        calc.clearAll()
        calc.inputDigit("4")
        calc.reciprocal()
        XCTAssertEqual(calc.displayValue, "0.25")
        
        // Negate (+/-)
        calc.clearAll()
        calc.inputDigit("8")
        calc.negate()
        XCTAssertEqual(calc.displayValue, "-8")
        calc.negate()
        XCTAssertEqual(calc.displayValue, "8")
        
        // Sqrt of negative
        calc.clearAll()
        calc.inputDigit("9")
        calc.negate()
        calc.squareRoot()
        XCTAssertEqual(calc.displayValue, "Invalid input for function")
        XCTAssertTrue(calc.hasError)
    }
    
    func testCalculatorMemoryFunctions() {
        let calc = CalculatorEngine()
        XCTAssertFalse(calc.hasMemory)
        
        // Store 42 in MS
        calc.inputDigit("4")
        calc.inputDigit("2")
        calc.memoryStore()
        XCTAssertTrue(calc.hasMemory)
        XCTAssertEqual(calc.memoryValue, 42)
        
        // Clear screen and recall MR
        calc.clearAll()
        XCTAssertEqual(calc.displayValue, "0")
        calc.memoryRecall()
        XCTAssertEqual(calc.displayValue, "42")
        
        // Add 8 via M+ (42 + 8 = 50)
        calc.clearAll()
        calc.inputDigit("8")
        calc.memoryAdd()
        XCTAssertEqual(calc.memoryValue, 50)
        
        // Memory Clear MC
        calc.memoryClear()
        XCTAssertFalse(calc.hasMemory)
        XCTAssertEqual(calc.memoryValue, 0)
    }
    
    func testCalculatorDivisionByZero() {
        let calc = CalculatorEngine()
        calc.inputDigit("5")
        calc.setOperator(.divide)
        calc.inputDigit("0")
        calc.calculate()
        XCTAssertEqual(calc.displayValue, "Cannot divide by zero")
        XCTAssertTrue(calc.hasError)
        
        // Clear resets error
        calc.clearAll()
        XCTAssertFalse(calc.hasError)
        XCTAssertEqual(calc.displayValue, "0")
    }
    
    func testCalculatorBackspaceAndCE() {
        let calc = CalculatorEngine()
        calc.inputDigit("1")
        calc.inputDigit("2")
        calc.inputDigit("3")
        XCTAssertEqual(calc.displayValue, "123")
        
        calc.backspace()
        XCTAssertEqual(calc.displayValue, "12")
        
        calc.clearEntry()
        XCTAssertEqual(calc.displayValue, "0")
    }

    // MARK: - 4. Minesweeper Engine Tests
    
    func testMinesweeperInitialization() {
        let game = MinesweeperEngine(difficulty: .beginner)
        XCTAssertEqual(game.rows, 9)
        XCTAssertEqual(game.cols, 9)
        XCTAssertEqual(game.totalMines, 10)
        XCTAssertEqual(game.remainingMines, 10)
        XCTAssertEqual(game.state, .ready)
        XCTAssertEqual(game.faceReaction, .normal)
        XCTAssertEqual(game.elapsedSeconds, 0)
        
        // Expert mode
        let expert = MinesweeperEngine(difficulty: .expert)
        XCTAssertEqual(expert.rows, 16)
        XCTAssertEqual(expert.cols, 30)
        XCTAssertEqual(expert.totalMines, 99)
    }
    
    func testMinesweeperFirstClickGuaranteedSafe() {
        let game = MinesweeperEngine(difficulty: .beginner)
        game.revealCell(row: 4, col: 4)
        
        XCTAssertEqual(game.state, .playing)
        XCTAssertFalse(game.cells[4][4].isMine)
        XCTAssertTrue(game.cells[4][4].isRevealed)
    }
    
    func testMinesweeperFlagging() {
        let game = MinesweeperEngine(difficulty: .beginner)
        XCTAssertEqual(game.remainingMines, 10)
        
        game.toggleFlag(row: 0, col: 0)
        XCTAssertEqual(game.cells[0][0].state, .flagged)
        XCTAssertEqual(game.remainingMines, 9)
        
        game.toggleFlag(row: 0, col: 0)
        XCTAssertEqual(game.cells[0][0].state, .question)
        XCTAssertEqual(game.remainingMines, 10)
        
        game.toggleFlag(row: 0, col: 0)
        XCTAssertEqual(game.cells[0][0].state, .hidden)
    }
    
    func testMinesweeperLossCondition() {
        let game = MinesweeperEngine(difficulty: .beginner)
        // Force mine at 0,0
        game.initializeField(firstClickRow: 4, firstClickCol: 4)
        game.cells[0][0].isMine = true
        
        game.revealCell(row: 0, col: 0)
        XCTAssertEqual(game.state, .lost)
        XCTAssertEqual(game.faceReaction, .lost)
    }
    
    func testMinesweeperWinCondition() {
        let game = MinesweeperEngine(difficulty: .beginner)
        game.initializeField(firstClickRow: 0, firstClickCol: 0)
        
        // Reveal all non-mine cells
        for r in 0..<game.rows {
            for c in 0..<game.cols {
                if !game.cells[r][c].isMine {
                    game.cells[r][c].isRevealed = true
                }
            }
        }
        
        game.checkWinCondition()
        XCTAssertEqual(game.state, .won)
        XCTAssertEqual(game.faceReaction, .won)
    }

    // MARK: - 5. Paint Engine Tests
    
    func testPaintEngineToolAndColorSelection() {
        let paint = PaintEngine()
        XCTAssertEqual(paint.selectedTool, .pencil)
        XCTAssertEqual(paint.strokeWidth, 1)
        XCTAssertEqual(paint.primaryColor, .black)
        XCTAssertEqual(paint.secondaryColor, .white)
        
        paint.selectTool(.brush)
        XCTAssertEqual(paint.selectedTool, .brush)
        
        paint.setStrokeWidth(4)
        XCTAssertEqual(paint.strokeWidth, 4)
        
        paint.setPrimaryColor(.red)
        XCTAssertEqual(paint.primaryColor, .red)
        
        paint.setSecondaryColor(.blue)
        XCTAssertEqual(paint.secondaryColor, .blue)
    }
    
    func testPaintEngineDrawingAndUndo() {
        let paint = PaintEngine()
        XCTAssertTrue(paint.actions.isEmpty)
        XCTAssertFalse(paint.canUndo)
        
        paint.addPencilStroke(points: [CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 20)], color: .black, width: 2)
        XCTAssertEqual(paint.actions.count, 1)
        XCTAssertTrue(paint.canUndo)
        
        paint.undo()
        XCTAssertEqual(paint.actions.count, 0)
        XCTAssertTrue(paint.canRedo)
        
        paint.redo()
        XCTAssertEqual(paint.actions.count, 1)
        
        paint.clearCanvas()
        XCTAssertEqual(paint.actions.count, 0)
    }

    // MARK: - 6. System Properties & Mac Specs Tests
    
    func testSystemInfoProvider() {
        let info = SystemInfoProvider.current()
        XCTAssertFalse(info.processorName.isEmpty)
        XCTAssertFalse(info.memoryFormatted.isEmpty)
        XCTAssertTrue(info.memoryFormatted.contains("RAM") || info.memoryFormatted.contains("GB") || info.memoryFormatted.contains("MB"))
        XCTAssertFalse(info.osVersion.isEmpty)
        XCTAssertFalse(info.hostName.isEmpty)
        XCTAssertEqual(info.windowsVersion, "Microsoft Windows XP Professional")
        XCTAssertEqual(info.servicePack, "Service Pack 3")
    }

    // MARK: - 7. Run Dialog Engine Tests
    
    func testRunDialogCommandParsing() {
        let engine = RunDialogEngine()
        
        XCTAssertEqual(engine.resolveCommand("notepad"), .openApp(.notepad(fileURL: nil)))
        XCTAssertEqual(engine.resolveCommand("cmd"), .openApp(.cmd))
        XCTAssertEqual(engine.resolveCommand("command"), .openApp(.cmd))
        XCTAssertEqual(engine.resolveCommand("calc"), .openApp(.calculator))
        XCTAssertEqual(engine.resolveCommand("paint"), .openApp(.paint))
        XCTAssertEqual(engine.resolveCommand("mspaint"), .openApp(.paint))
        XCTAssertEqual(engine.resolveCommand("winmine"), .openApp(.minesweeper))
        XCTAssertEqual(engine.resolveCommand("control"), .openApp(.controlPanel))
        XCTAssertEqual(engine.resolveCommand("sysdm.cpl"), .openApp(.systemProperties))
        XCTAssertEqual(engine.resolveCommand("explorer"), .openApp(.explorer(path: "/")))
        XCTAssertEqual(engine.resolveCommand("iexplore"), .openApp(.internetExplorer(url: "https://www.google.com")))
        
        // URL
        if case .openURL(let url) = engine.resolveCommand("https://www.google.com") {
            XCTAssertEqual(url.absoluteString, "https://www.google.com")
        } else {
            XCTFail("Expected openURL")
        }
        
        // Invalid command
        XCTAssertEqual(engine.resolveCommand("unknown_cmd_xyz_123"), .notFound("unknown_cmd_xyz_123"))
    }
    
    func testRunDialogHistory() {
        let engine = RunDialogEngine(history: [])
        engine.addToHistory("notepad")
        engine.addToHistory("cmd")
        
        XCTAssertEqual(engine.history.first, "cmd")
        XCTAssertEqual(engine.history.count, 2)
    }

    // MARK: - 8. Internet Explorer ViewModel Tests

    func testInternetExplorerURLNormalization() {
        let vm = InternetExplorerViewModel(initialURL: "https://www.google.com")
        XCTAssertEqual(vm.currentURLString, "https://www.google.com")

        // Domain without scheme
        let url1 = vm.normalizeInputURL("youtube.com")
        XCTAssertEqual(url1.absoluteString, "https://youtube.com")

        // Search query
        let url2 = vm.normalizeInputURL("windows xp blissful wallpaper")
        XCTAssertTrue(url2.absoluteString.contains("google.com/search?q=windows%20xp%20blissful%20wallpaper") || url2.absoluteString.contains("google.com/search?q=windows+xp+blissful+wallpaper"))

        // Local or custom schemes
        let url3 = vm.normalizeInputURL("http://localhost:3000")
        XCTAssertEqual(url3.absoluteString, "http://localhost:3000")
    }

    func testInternetExplorerNavigationHistory() {
        let vm = InternetExplorerViewModel(initialURL: "https://www.google.com")
        XCTAssertFalse(vm.canGoBack)
        XCTAssertFalse(vm.canGoForward)

        vm.loadURL("https://github.com")
        XCTAssertTrue(vm.canGoBack)
        XCTAssertEqual(vm.currentURLString, "https://github.com")

        vm.goBack()
        XCTAssertEqual(vm.currentURLString, "https://www.google.com")
        XCTAssertTrue(vm.canGoForward)

        vm.goForward()
        XCTAssertEqual(vm.currentURLString, "https://github.com")
    }
}
