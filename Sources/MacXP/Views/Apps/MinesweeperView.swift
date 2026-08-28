import SwiftUI

public enum MinesweeperDifficulty: Equatable {
    case beginner
    case intermediate
    case expert
    
    public var rows: Int {
        switch self {
        case .beginner: return 9
        case .intermediate: return 16
        case .expert: return 16
        }
    }
    
    public var cols: Int {
        switch self {
        case .beginner: return 9
        case .intermediate: return 16
        case .expert: return 30
        }
    }
    
    public var mines: Int {
        switch self {
        case .beginner: return 10
        case .intermediate: return 40
        case .expert: return 99
        }
    }
}

public enum MineCellState: Equatable {
    case hidden
    case flagged
    case question
}

public struct MineCell: Identifiable, Equatable {
    public let id = UUID()
    public let row: Int
    public let col: Int
    public var isMine: Bool = false
    public var isRevealed: Bool = false
    public var state: MineCellState = .hidden
    public var adjacentMines: Int = 0
    public var isExploded: Bool = false
    public var isWrongFlag: Bool = false
}

public enum MinesweeperGameState: Equatable {
    case ready
    case playing
    case won
    case lost
}

public enum SmileyFaceReaction: Equatable {
    case normal
    case clicking
    case won
    case lost
}

public class MinesweeperEngine: ObservableObject {
    @Published public var difficulty: MinesweeperDifficulty
    @Published public var rows: Int
    @Published public var cols: Int
    @Published public var totalMines: Int
    @Published public var remainingMines: Int
    @Published public var state: MinesweeperGameState = .ready
    @Published public var faceReaction: SmileyFaceReaction = .normal
    @Published public var elapsedSeconds: Int = 0
    @Published public var cells: [[MineCell]] = []
    
    private var timer: Timer? = nil
    
    public init(difficulty: MinesweeperDifficulty = .beginner) {
        self.difficulty = difficulty
        self.rows = difficulty.rows
        self.cols = difficulty.cols
        self.totalMines = difficulty.mines
        self.remainingMines = difficulty.mines
        
        reset(difficulty: difficulty)
    }
    
    public func reset(difficulty: MinesweeperDifficulty? = nil) {
        timer?.invalidate()
        timer = nil
        
        let diff = difficulty ?? self.difficulty
        self.difficulty = diff
        self.rows = diff.rows
        self.cols = diff.cols
        self.totalMines = diff.mines
        self.remainingMines = diff.mines
        self.state = .ready
        self.faceReaction = .normal
        self.elapsedSeconds = 0
        
        var grid: [[MineCell]] = []
        for r in 0..<rows {
            var rowCells: [MineCell] = []
            for c in 0..<cols {
                rowCells.append(MineCell(row: r, col: c))
            }
            grid.append(rowCells)
        }
        self.cells = grid
    }
    
    public func initializeField(firstClickRow: Int, firstClickCol: Int) {
        // Place mines randomly, excluding first click and adjacent
        var available: [(Int, Int)] = []
        for r in 0..<rows {
            for c in 0..<cols {
                if abs(r - firstClickRow) <= 1 && abs(c - firstClickCol) <= 1 {
                    continue
                }
                available.append((r, c))
            }
        }
        
        available.shuffle()
        let count = min(totalMines, available.count)
        for i in 0..<count {
            let (r, c) = available[i]
            cells[r][c].isMine = true
        }
        
        // Calculate adjacent mines
        for r in 0..<rows {
            for c in 0..<cols {
                if !cells[r][c].isMine {
                    var adj = 0
                    for dr in -1...1 {
                        for dc in -1...1 {
                            let nr = r + dr
                            let nc = c + dc
                            if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                                if cells[nr][nc].isMine {
                                    adj += 1
                                }
                            }
                        }
                    }
                    cells[r][c].adjacentMines = adj
                }
            }
        }
    }
    
    public func revealCell(row: Int, col: Int) {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return }
        let cell = cells[row][col]
        guard !cell.isRevealed && cell.state != .flagged && state != .won && state != .lost else { return }
        
        if state == .ready {
            initializeField(firstClickRow: row, firstClickCol: col)
            state = .playing
            startTimer()
        }
        
        if cells[row][col].isMine {
            // Hit mine -> Loss
            cells[row][col].isRevealed = true
            cells[row][col].isExploded = true
            state = .lost
            faceReaction = .lost
            stopTimer()
            revealAllMines()
            return
        }
        
        // Reveal cell
        cells[row][col].isRevealed = true
        
        // If 0 adjacent, flood fill
        if cells[row][col].adjacentMines == 0 {
            floodFill(fromRow: row, fromCol: col)
        }
        
        checkWinCondition()
    }
    
    private func floodFill(fromRow: Int, fromCol: Int) {
        var queue = [(fromRow, fromCol)]
        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()
            for dr in -1...1 {
                for dc in -1...1 {
                    let nr = r + dr
                    let nc = c + dc
                    if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                        if !cells[nr][nc].isRevealed && !cells[nr][nc].isMine && cells[nr][nc].state != .flagged {
                            cells[nr][nc].isRevealed = true
                            if cells[nr][nc].adjacentMines == 0 {
                                queue.append((nr, nc))
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func toggleFlag(row: Int, col: Int) {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return }
        guard !cells[row][col].isRevealed && state != .won && state != .lost else { return }
        
        switch cells[row][col].state {
        case .hidden:
            cells[row][col].state = .flagged
            remainingMines -= 1
        case .flagged:
            cells[row][col].state = .question
            remainingMines += 1
        case .question:
            cells[row][col].state = .hidden
        }
    }
    
    public func checkWinCondition() {
        var unrevealedSafeCount = 0
        for r in 0..<rows {
            for c in 0..<cols {
                if !cells[r][c].isMine && !cells[r][c].isRevealed {
                    unrevealedSafeCount += 1
                }
            }
        }
        
        if unrevealedSafeCount == 0 {
            state = .won
            faceReaction = .won
            stopTimer()
            remainingMines = 0
            for r in 0..<rows {
                for c in 0..<cols {
                    if cells[r][c].isMine {
                        cells[r][c].state = .flagged
                    }
                }
            }
        }
    }
    
    private func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<cols {
                if cells[r][c].isMine {
                    cells[r][c].isRevealed = true
                } else if cells[r][c].state == .flagged {
                    cells[r][c].isWrongFlag = true
                }
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .playing else { return }
            if self.elapsedSeconds < 999 {
                self.elapsedSeconds += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

public struct MinesweeperView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var engine = MinesweeperEngine()
    @State private var openMenu: String? = nil
    @State private var isMouseDown: Bool = false
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Menu Bar
            HStack(spacing: 0) {
                menuButton(title: "Game")
                menuButton(title: "Help")
                Spacer()
            }
            .frame(height: 20)
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            // Beveled Playfield Container
            VStack(spacing: 6) {
                // Header (Mines counter, Smiley, Timer)
                headerScoreboard
                
                // Minefield Grid
                minefieldGrid
            }
            .padding(6)
            .background(Color(red: 0.75, green: 0.75, blue: 0.75))
            .overlay(
                Rectangle()
                    .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2)
            )
            .padding(6)
            
            Spacer()
        }
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .overlay(
            openMenu == "Game" ? gameDropdownMenu : nil,
            alignment: .topLeading
        )
    }
    
    private func menuButton(title: String) -> some View {
        Button(action: {
            openMenu = (openMenu == title ? nil : title)
        }) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var gameDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItem(title: "New", shortcut: "F2") {
                engine.reset()
            }
            Divider()
            menuItemWithCheck(title: "Beginner", isChecked: engine.difficulty == .beginner) {
                engine.reset(difficulty: .beginner)
            }
            menuItemWithCheck(title: "Intermediate", isChecked: engine.difficulty == .intermediate) {
                engine.reset(difficulty: .intermediate)
            }
            menuItemWithCheck(title: "Expert", isChecked: engine.difficulty == .expert) {
                engine.reset(difficulty: .expert)
            }
            Divider()
            menuItem(title: "Exit") {
                windowManager.closeWindow(id: window.id)
            }
        }
        .frame(width: 150)
        .padding(.vertical, 2)
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .border(Color(red: 0.55, green: 0.55, blue: 0.55), width: 1)
        .shadow(radius: 4)
        .offset(x: 4, y: 20)
    }
    
    private func menuItem(title: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: {
            openMenu = nil
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func menuItemWithCheck(title: String, isChecked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            openMenu = nil
            action()
        }) {
            HStack(spacing: 4) {
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 14)
                } else {
                    Spacer().frame(width: 14)
                }
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header Scoreboard
    private var headerScoreboard: some View {
        HStack {
            // Mines remaining LED
            sevenSegmentDisplay(number: engine.remainingMines)
            
            Spacer()
            
            // Smiley button
            Button(action: {
                engine.reset()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.75, green: 0.75, blue: 0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
                        )
                    
                    Text(smileyFaceEmoji)
                        .font(.system(size: 18))
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Timer LED
            sevenSegmentDisplay(number: engine.elapsedSeconds)
        }
        .padding(4)
        .background(Color(red: 0.75, green: 0.75, blue: 0.75))
        .overlay(
            Rectangle()
                .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 2)
        )
    }
    
    private var smileyFaceEmoji: String {
        switch engine.faceReaction {
        case .normal:
            return isMouseDown ? "😮" : "🙂"
        case .clicking:
            return "😮"
        case .won:
            return "😎"
        case .lost:
            return "😵"
        }
    }
    
    private func sevenSegmentDisplay(number: Int) -> some View {
        let clamped = max(-99, min(999, number))
        let text = clamped < 0 ? String(format: "-%02d", abs(clamped)) : String(format: "%03d", clamped)
        
        return ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 48, height: 26)
            
            Text("888")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.3, green: 0.0, blue: 0.0))
            
            Text(text)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 1.0, green: 0.1, blue: 0.1))
        }
        .overlay(
            Rectangle()
                .strokeBorder(Color(red: 0.4, green: 0.4, blue: 0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Minefield Grid
    private var minefieldGrid: some View {
        VStack(spacing: 1) {
            ForEach(0..<engine.rows, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<engine.cols, id: \.self) { c in
                        let cell = engine.cells[r][c]
                        cellView(cell: cell)
                    }
                }
            }
        }
        .padding(2)
        .background(Color(red: 0.6, green: 0.6, blue: 0.6))
        .overlay(
            Rectangle()
                .strokeBorder(Color(red: 0.4, green: 0.4, blue: 0.4), lineWidth: 2)
        )
    }
    
    private func cellView(cell: MineCell) -> some View {
        ZStack {
            if cell.isRevealed {
                // Revealed Cell
                Rectangle()
                    .fill(cell.isExploded ? Color(red: 1.0, green: 0.3, blue: 0.3) : Color(red: 0.78, green: 0.78, blue: 0.78))
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color(red: 0.6, green: 0.6, blue: 0.6), lineWidth: 0.5)
                    )
                
                if cell.isMine {
                    Text("💣")
                        .font(.system(size: 11))
                } else if cell.adjacentMines > 0 {
                    Text("\(cell.adjacentMines)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(colorForAdjacentNumber(cell.adjacentMines))
                }
            } else {
                // Unrevealed Cell (Raised 3D)
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.75, green: 0.75, blue: 0.75))
                    
                    // 3D Highlight & Shadow
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Color.white.frame(height: 2)
                        }
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Color.white.frame(width: 2)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Spacer()
                        Color(red: 0.45, green: 0.45, blue: 0.45).frame(height: 2)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Color(red: 0.45, green: 0.45, blue: 0.45).frame(width: 2)
                    }
                    
                    if cell.state == .flagged {
                        Text("🚩")
                            .font(.system(size: 11))
                    } else if cell.state == .question {
                        Text("?")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.blue)
                    }
                }
            }
        }
        .frame(width: 20, height: 20)
        .contentShape(Rectangle())
        .onTapGesture {
            engine.revealCell(row: cell.row, col: cell.col)
        }
        .contextMenu {
            Button("Flag / Unflag") {
                engine.toggleFlag(row: cell.row, col: cell.col)
            }
        }
    }
    
    private func colorForAdjacentNumber(_ num: Int) -> Color {
        switch num {
        case 1: return Color(red: 0.0, green: 0.0, blue: 1.0)
        case 2: return Color(red: 0.0, green: 0.5, blue: 0.0)
        case 3: return Color(red: 1.0, green: 0.0, blue: 0.0)
        case 4: return Color(red: 0.0, green: 0.0, blue: 0.5)
        case 5: return Color(red: 0.5, green: 0.0, blue: 0.0)
        case 6: return Color(red: 0.0, green: 0.5, blue: 0.5)
        case 7: return Color.black
        case 8: return Color.gray
        default: return Color.black
        }
    }
}
