import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Card Models

public enum CardSuit: String, CaseIterable, Codable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    
    public var isRed: Bool {
        self == .hearts || self == .diamonds
    }
    
    public var color: Color {
        isRed ? Color(red: 0.85, green: 0.1, blue: 0.1) : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
}

public enum CardRank: Int, CaseIterable, Comparable, Codable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    
    public static func < (lhs: CardRank, rhs: CardRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var displayString: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }
}

public struct PlayingCard: Identifiable, Equatable, Hashable, Codable {
    public let id: UUID
    public let suit: CardSuit
    public let rank: CardRank
    public var isFaceUp: Bool
    
    public init(id: UUID = UUID(), suit: CardSuit, rank: CardRank, isFaceUp: Bool = false) {
        self.id = id
        self.suit = suit
        self.rank = rank
        self.isFaceUp = isFaceUp
    }
}

public enum CardBackStyle: String, CaseIterable, Identifiable {
    case castle = "Blue Castle"
    case beach = "Tropical Beach"
    case hand = "Hand with Cards"
    case robot = "Robot"
    
    public var id: String { rawValue }
}

public enum SolitaireDrawMode: Int {
    case drawOne = 1
    case drawThree = 3
}

// MARK: - Solitaire Engine

public class SolitaireEngine: ObservableObject {
    @Published public var stock: [PlayingCard] = []
    @Published public var waste: [PlayingCard] = []
    @Published public var foundations: [[PlayingCard]] = [[], [], [], []]
    @Published public var tableau: [[PlayingCard]] = [[], [], [], [], [], [], []]
    
    @Published public var score: Int = 0
    @Published public var timeElapsed: Int = 0
    @Published public var moveCount: Int = 0
    @Published public var isWon: Bool = false
    @Published public var drawMode: SolitaireDrawMode = .drawOne
    @Published public var cardBack: CardBackStyle = .castle
    
    // Victory animation state
    @Published public var cascadeCards: [CascadeCard] = []
    
    private var timer: Timer?
    
    public init() {
        startNewGame()
    }
    
    public func startNewGame() {
        timer?.invalidate()
        timeElapsed = 0
        score = 0
        moveCount = 0
        isWon = false
        cascadeCards = []
        
        // Generate and shuffle standard 52-card deck
        var deck: [PlayingCard] = []
        for suit in CardSuit.allCases {
            for rank in CardRank.allCases {
                deck.append(PlayingCard(suit: suit, rank: rank, isFaceUp: false))
            }
        }
        deck.shuffle()
        
        // Deal tableau (7 piles: 1..7 cards)
        var newTableau: [[PlayingCard]] = [[], [], [], [], [], [], []]
        for col in 0..<7 {
            for row in 0...col {
                var card = deck.removeLast()
                if row == col {
                    card.isFaceUp = true
                }
                newTableau[col].append(card)
            }
        }
        self.tableau = newTableau
        self.foundations = [[], [], [], []]
        self.waste = []
        self.stock = deck
        
        // Start game timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isWon else { return }
            self.timeElapsed += 1
            if self.timeElapsed % 10 == 0 && self.score > 2 {
                self.score -= 2 // Time penalty in standard rules
            }
        }
    }
    
    // Draw from Stock to Waste
    public func drawFromStock() {
        guard !isWon else { return }
        if stock.isEmpty {
            // Recycle waste back to stock
            stock = waste.reversed().map {
                var c = $0
                c.isFaceUp = false
                return c
            }
            waste.removeAll()
            score = max(0, score - 20)
        } else {
            let count = min(drawMode.rawValue, stock.count)
            for _ in 0..<count {
                var card = stock.removeLast()
                card.isFaceUp = true
                waste.append(card)
            }
            moveCount += 1
        }
    }
    
    // Move card from Waste to Foundation
    public func moveWasteToFoundation(index: Int) -> Bool {
        guard let card = waste.last else { return false }
        if canAddToFoundation(card: card, foundationIndex: index) {
            waste.removeLast()
            foundations[index].append(card)
            score += 10
            moveCount += 1
            checkWin()
            return true
        }
        return false
    }
    
    // Move card from Waste to Tableau
    public func moveWasteToTableau(colIndex: Int) -> Bool {
        guard let card = waste.last else { return false }
        if canAddToTableau(card: card, colIndex: colIndex) {
            waste.removeLast()
            tableau[colIndex].append(card)
            score += 5
            moveCount += 1
            return true
        }
        return false
    }
    
    // Move stack of cards between Tableau columns
    public func moveTableauStack(fromCol: Int, startingAtIndex: Int, toCol: Int) -> Bool {
        guard fromCol != toCol, startingAtIndex < tableau[fromCol].count else { return false }
        let stack = Array(tableau[fromCol][startingAtIndex...])
        guard let bottomCard = stack.first, bottomCard.isFaceUp else { return false }
        
        if canAddToTableau(card: bottomCard, colIndex: toCol) {
            tableau[fromCol].removeSubrange(startingAtIndex...)
            tableau[toCol].append(contentsOf: stack)
            
            // Turn over new top card in source column
            if let lastIdx = tableau[fromCol].indices.last, !tableau[fromCol][lastIdx].isFaceUp {
                tableau[fromCol][lastIdx].isFaceUp = true
                score += 5
            }
            moveCount += 1
            return true
        }
        return false
    }
    
    // Move single card from Tableau to Foundation
    public func moveTableauToFoundation(fromCol: Int, foundationIndex: Int) -> Bool {
        guard let card = tableau[fromCol].last, card.isFaceUp else { return false }
        if canAddToFoundation(card: card, foundationIndex: foundationIndex) {
            tableau[fromCol].removeLast()
            foundations[foundationIndex].append(card)
            
            if let lastIdx = tableau[fromCol].indices.last, !tableau[fromCol][lastIdx].isFaceUp {
                tableau[fromCol][lastIdx].isFaceUp = true
                score += 5
            }
            score += 10
            moveCount += 1
            checkWin()
            return true
        }
        return false
    }
    
    // Auto-move on double-click
    public func autoMoveCard(_ card: PlayingCard, fromTableauCol: Int? = nil, isFromWaste: Bool = false) {
        guard card.isFaceUp else { return }
        
        // 1. Try moving to foundation
        for fIdx in 0..<4 {
            if canAddToFoundation(card: card, foundationIndex: fIdx) {
                if isFromWaste {
                    _ = moveWasteToFoundation(index: fIdx)
                } else if let col = fromTableauCol {
                    _ = moveTableauToFoundation(fromCol: col, foundationIndex: fIdx)
                }
                return
            }
        }
        
        // 2. Try moving to tableau
        for col in 0..<7 {
            if let fromCol = fromTableauCol, fromCol == col { continue }
            if canAddToTableau(card: card, colIndex: col) {
                if isFromWaste {
                    _ = moveWasteToTableau(colIndex: col)
                } else if let fromCol = fromTableauCol, let cardIdx = tableau[fromCol].firstIndex(of: card) {
                    _ = moveTableauStack(fromCol: fromCol, startingAtIndex: cardIdx, toCol: col)
                }
                return
            }
        }
    }
    
    public func canAddToFoundation(card: PlayingCard, foundationIndex: Int) -> Bool {
        guard foundationIndex >= 0 && foundationIndex < 4 else { return false }
        let pile = foundations[foundationIndex]
        if pile.isEmpty {
            return card.rank == .ace
        } else if let top = pile.last {
            return top.suit == card.suit && card.rank.rawValue == top.rank.rawValue + 1
        }
        return false
    }
    
    public func canAddToTableau(card: PlayingCard, colIndex: Int) -> Bool {
        guard colIndex >= 0 && colIndex < 7 else { return false }
        let pile = tableau[colIndex]
        if pile.isEmpty {
            return card.rank == .king
        } else if let top = pile.last, top.isFaceUp {
            return top.suit.isRed != card.suit.isRed && top.rank.rawValue == card.rank.rawValue + 1
        }
        return false
    }
    
    public func checkWin() {
        let total = foundations.reduce(0) { $0 + $1.count }
        if total == 52 {
            isWon = true
            timer?.invalidate()
            startCascadeAnimation()
        }
    }
    
    private func startCascadeAnimation() {
        var allCards: [PlayingCard] = []
        for pile in foundations {
            allCards.append(contentsOf: pile)
        }
        allCards.shuffle()
        
        var generated: [CascadeCard] = []
        for (i, card) in allCards.enumerated() {
            let startX = 100.0 + Double(i % 4) * 110.0
            let startY = 80.0
            let vx = Double.random(in: -5.0...5.0)
            let vy = Double.random(in: -4.0...0.0)
            generated.append(CascadeCard(card: card, x: startX, y: startY, vx: vx, vy: vy, delay: Double(i) * 0.15))
        }
        self.cascadeCards = generated
    }
}

// MARK: - Cascade Animation Card

public struct CascadeCard: Identifiable {
    public let id = UUID()
    public let card: PlayingCard
    public var x: Double
    public var y: Double
    public var vx: Double
    public var vy: Double
    public var delay: Double
    public var isActive: Bool = false
}

// MARK: - Solitaire View

public struct SolitaireView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var engine = SolitaireEngine()
    @State private var selectedCard: PlayingCard? = nil
    @State private var selectedSourceCol: Int? = nil
    @State private var isSelectedFromWaste: Bool = false
    @State private var showOptionsDialog: Bool = false
    
    // Animation timer for cascade
    @State private var cascadeTimer: Timer? = nil
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Menu Bar
            menuBar
            
            // Green Felt Table
            ZStack {
                Color(red: 0.0, green: 0.48, blue: 0.0) // Classic XP green felt
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Top Row: Stock, Waste, (Gap), 4 Foundations
                    HStack(spacing: 12) {
                        // Stock
                        Button(action: {
                            engine.drawFromStock()
                            clearSelection()
                        }) {
                            ZStack {
                                CardSlotView()
                                if let _ = engine.stock.last {
                                    CardBackView(style: engine.cardBack)
                                } else {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .frame(width: 58, height: 80)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Waste
                        ZStack {
                            CardSlotView()
                            if let card = engine.waste.last {
                                CardFaceView(card: card, isSelected: selectedCard?.id == card.id)
                                    .onTapGesture(count: 2) {
                                        engine.autoMoveCard(card, isFromWaste: true)
                                        clearSelection()
                                    }
                                    .onTapGesture {
                                        handleCardTap(card, fromCol: nil, isWaste: true)
                                    }
                            }
                        }
                        .frame(width: 58, height: 80)
                        
                        Spacer()
                        
                        // 4 Foundation Piles
                        ForEach(0..<4, id: \.self) { idx in
                            ZStack {
                                CardSlotView(icon: ["♠", "♥", "♦", "♣"][idx])
                                if let card = engine.foundations[idx].last {
                                    CardFaceView(card: card)
                                }
                            }
                            .frame(width: 58, height: 80)
                            .onTapGesture {
                                handleFoundationTap(foundationIndex: idx)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Tableau: 7 Columns
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(0..<7, id: \.self) { colIdx in
                            ZStack(alignment: .top) {
                                CardSlotView()
                                    .frame(width: 58, height: 80)
                                    .onTapGesture {
                                        handleEmptyTableauTap(colIndex: colIdx)
                                    }
                                
                                ForEach(Array(engine.tableau[colIdx].enumerated()), id: \.element.id) { cardIdx, card in
                                    Group {
                                        if card.isFaceUp {
                                            CardFaceView(card: card, isSelected: selectedCard?.id == card.id)
                                                .onTapGesture(count: 2) {
                                                    engine.autoMoveCard(card, fromTableauCol: colIdx)
                                                    clearSelection()
                                                }
                                                .onTapGesture {
                                                    handleCardTap(card, fromCol: colIdx, isWaste: false)
                                                }
                                        } else {
                                            CardBackView(style: engine.cardBack)
                                        }
                                    }
                                    .frame(width: 58, height: 80)
                                    .offset(y: Double(cardIdx) * 18.0)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                
                // Winning Cascade Animation Canvas
                if engine.isWon {
                    GeometryReader { geo in
                        Canvas { ctx, size in
                            for c in engine.cascadeCards where c.isActive {
                                let rect = CGRect(x: c.x, y: c.y, width: 58, height: 80)
                                ctx.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(.white))
                                ctx.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(.black), lineWidth: 1)
                                
                                let text = Text("\(c.card.rank.displayString)\(c.card.suit.rawValue)")
                                    .foregroundColor(c.card.suit.isRed ? .red : .black)
                                    .font(.system(size: 14, weight: .bold))
                                ctx.draw(text, at: CGPoint(x: c.x + 29, y: c.y + 40))
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            
            // Status Bar
            statusBar
        }
        .sheet(isPresented: $showOptionsDialog) {
            optionsDialog
        }
        .onAppear {
            startCascadeTicker()
        }
        .onDisappear {
            cascadeTimer?.invalidate()
        }
    }
    
    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 16) {
            Menu("Game") {
                Button("New Game") { engine.startNewGame() }
                Button("Deck...") { showOptionsDialog = true }
                Button("Options...") { showOptionsDialog = true }
                Divider()
                Button("Exit") { windowManager.closeWindow(id: window.id) }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            Menu("Help") {
                Button("Contents") {}
                Button("About Solitaire") {}
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            Spacer()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(red: 0.93, green: 0.91, blue: 0.85))
        .border(Color(red: 0.82, green: 0.80, blue: 0.72), width: 1)
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Text("Score: \(engine.score)")
                .frame(width: 100, alignment: .leading)
            Divider().frame(height: 14)
            Text("Time: \(String(format: "%02d:%02d", engine.timeElapsed / 60, engine.timeElapsed % 60))")
                .frame(width: 100, alignment: .leading)
            Divider().frame(height: 14)
            Text("Moves: \(engine.moveCount)")
                .frame(width: 100, alignment: .leading)
            Spacer()
        }
        .font(.system(size: 11, design: .default))
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(red: 0.93, green: 0.91, blue: 0.85))
        .border(Color(red: 0.82, green: 0.80, blue: 0.72), width: 1)
    }
    
    // MARK: - Interaction Handlers
    private func handleCardTap(_ card: PlayingCard, fromCol: Int?, isWaste: Bool) {
        if let selected = selectedCard {
            // Target is tableau column
            if let targetCol = fromCol {
                if isSelectedFromWaste {
                    if engine.moveWasteToTableau(colIndex: targetCol) {
                        clearSelection()
                        return
                    }
                } else if let sourceCol = selectedSourceCol, let idx = engine.tableau[sourceCol].firstIndex(of: selected) {
                    if engine.moveTableauStack(fromCol: sourceCol, startingAtIndex: idx, toCol: targetCol) {
                        clearSelection()
                        return
                    }
                }
            }
            clearSelection()
        } else {
            // Select card
            selectedCard = card
            selectedSourceCol = fromCol
            isSelectedFromWaste = isWaste
        }
    }
    
    private func handleEmptyTableauTap(colIndex: Int) {
        guard let selected = selectedCard else { return }
        if isSelectedFromWaste {
            _ = engine.moveWasteToTableau(colIndex: colIndex)
        } else if let sourceCol = selectedSourceCol, let idx = engine.tableau[sourceCol].firstIndex(of: selected) {
            _ = engine.moveTableauStack(fromCol: sourceCol, startingAtIndex: idx, toCol: colIndex)
        }
        clearSelection()
    }
    
    private func handleFoundationTap(foundationIndex: Int) {
        guard let _ = selectedCard else { return }
        if isSelectedFromWaste {
            _ = engine.moveWasteToFoundation(index: foundationIndex)
        } else if let sourceCol = selectedSourceCol {
            _ = engine.moveTableauToFoundation(fromCol: sourceCol, foundationIndex: foundationIndex)
        }
        clearSelection()
    }
    
    private func clearSelection() {
        selectedCard = nil
        selectedSourceCol = nil
        isSelectedFromWaste = false
    }
    
    private func startCascadeTicker() {
        cascadeTimer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { _ in
            guard engine.isWon else { return }
            for i in 0..<engine.cascadeCards.count {
                if !engine.cascadeCards[i].isActive {
                    engine.cascadeCards[i].delay -= 0.025
                    if engine.cascadeCards[i].delay <= 0 {
                        engine.cascadeCards[i].isActive = true
                    }
                } else {
                    engine.cascadeCards[i].vy += 0.45 // gravity
                    engine.cascadeCards[i].x += engine.cascadeCards[i].vx
                    engine.cascadeCards[i].y += engine.cascadeCards[i].vy
                    
                    // Bounce floor
                    if engine.cascadeCards[i].y > 380 {
                        engine.cascadeCards[i].y = 380
                        engine.cascadeCards[i].vy = -engine.cascadeCards[i].vy * 0.78
                    }
                }
            }
        }
    }
    
    // MARK: - Options Dialog
    private var optionsDialog: some View {
        VStack(spacing: 16) {
            Text("Solitaire Options")
                .font(.system(size: 14, weight: .bold))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Draw Mode:")
                    .font(.system(size: 12, weight: .bold))
                Picker("", selection: $engine.drawMode) {
                    Text("Draw One (1 card)").tag(SolitaireDrawMode.drawOne)
                    Text("Draw Three (3 cards)").tag(SolitaireDrawMode.drawThree)
                }
                .pickerStyle(RadioGroupPickerStyle())
                
                Text("Card Back:")
                    .font(.system(size: 12, weight: .bold))
                Picker("", selection: $engine.cardBack) {
                    ForEach(CardBackStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            
            HStack {
                Spacer()
                Button("OK") {
                    showOptionsDialog = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320, height: 260)
    }
}

// MARK: - Card Slot & Face Subviews

public struct CardSlotView: View {
    public var icon: String? = nil
    
    public init(icon: String? = nil) {
        self.icon = icon
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                .background(Color.black.opacity(0.12).cornerRadius(4))
            
            if let icon = icon {
                Text(icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}

public struct CardFaceView: View {
    public let card: PlayingCard
    public var isSelected: Bool = false
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color(red: 0.2, green: 0.5, blue: 1.0) : Color.black.opacity(0.5), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 1, y: 1)
            
            VStack(spacing: 0) {
                // Top Corner
                HStack(spacing: 2) {
                    Text(card.rank.displayString)
                        .font(.system(size: 11, weight: .bold))
                    Text(card.suit.rawValue)
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundColor(card.suit.color)
                .padding(.horizontal, 4)
                .padding(.top, 2)
                
                Spacer()
                
                // Center Suit / Face
                Text(card.suit.rawValue)
                    .font(.system(size: 22))
                    .foregroundColor(card.suit.color)
                
                Spacer()
                
                // Bottom Corner (Inverted)
                HStack(spacing: 2) {
                    Spacer()
                    Text(card.suit.rawValue)
                        .font(.system(size: 10))
                    Text(card.rank.displayString)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(card.suit.color)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
        }
    }
}

public struct CardBackView: View {
    public let style: CardBackStyle
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.1, green: 0.25, blue: 0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
            
            switch style {
            case .castle:
                VStack(spacing: 2) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.4))
                    Text("XP")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            case .beach:
                VStack(spacing: 2) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                    Image(systemName: "water.waves")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                }
            case .hand:
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            case .robot:
                Image(systemName: "cpu")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
    }
}
