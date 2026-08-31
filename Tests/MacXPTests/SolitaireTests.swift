import XCTest
@testable import MacXP

final class SolitaireTests: XCTestCase {
    
    func testNewGameSetup() {
        let engine = SolitaireEngine()
        
        // 7 tableau columns
        XCTAssertEqual(engine.tableau.count, 7)
        for col in 0..<7 {
            XCTAssertEqual(engine.tableau[col].count, col + 1)
            XCTAssertTrue(engine.tableau[col].last?.isFaceUp == true)
        }
        
        // 4 foundations
        XCTAssertEqual(engine.foundations.count, 4)
        for f in engine.foundations {
            XCTAssertTrue(f.isEmpty)
        }
        
        // Stock: 52 - 28 (tableau) = 24
        XCTAssertEqual(engine.stock.count, 24)
        XCTAssertTrue(engine.waste.isEmpty)
        XCTAssertEqual(engine.score, 0)
        XCTAssertFalse(engine.isWon)
    }
    
    func testDrawFromStock() {
        let engine = SolitaireEngine()
        engine.drawMode = .drawOne
        
        engine.drawFromStock()
        XCTAssertEqual(engine.waste.count, 1)
        XCTAssertEqual(engine.stock.count, 23)
        XCTAssertTrue(engine.waste.last?.isFaceUp == true)
        
        engine.drawMode = .drawThree
        engine.drawFromStock()
        XCTAssertEqual(engine.waste.count, 4)
        XCTAssertEqual(engine.stock.count, 20)
    }
    
    func testStockRecycle() {
        let engine = SolitaireEngine()
        // Empty stock to waste
        while !engine.stock.isEmpty {
            engine.drawFromStock()
        }
        XCTAssertTrue(engine.stock.isEmpty)
        XCTAssertEqual(engine.waste.count, 24)
        
        // Click to recycle
        engine.drawFromStock()
        XCTAssertEqual(engine.stock.count, 24)
        XCTAssertTrue(engine.waste.isEmpty)
        for c in engine.stock {
            XCTAssertFalse(c.isFaceUp)
        }
    }
    
    func testFoundationRules() {
        let engine = SolitaireEngine()
        
        let aceSpades = PlayingCard(suit: .spades, rank: .ace, isFaceUp: true)
        let twoSpades = PlayingCard(suit: .spades, rank: .two, isFaceUp: true)
        let twoHearts = PlayingCard(suit: .hearts, rank: .two, isFaceUp: true)
        
        XCTAssertTrue(engine.canAddToFoundation(card: aceSpades, foundationIndex: 0))
        XCTAssertFalse(engine.canAddToFoundation(card: twoSpades, foundationIndex: 0))
        
        // Place Ace
        engine.foundations[0].append(aceSpades)
        XCTAssertTrue(engine.canAddToFoundation(card: twoSpades, foundationIndex: 0))
        XCTAssertFalse(engine.canAddToFoundation(card: twoHearts, foundationIndex: 0))
    }
    
    func testTableauRules() {
        let engine = SolitaireEngine()
        
        let kingHearts = PlayingCard(suit: .hearts, rank: .king, isFaceUp: true)
        let queenSpades = PlayingCard(suit: .spades, rank: .queen, isFaceUp: true)
        let queenDiamonds = PlayingCard(suit: .diamonds, rank: .queen, isFaceUp: true)
        
        // Empty column accepts King
        engine.tableau[0].removeAll()
        XCTAssertTrue(engine.canAddToTableau(card: kingHearts, colIndex: 0))
        XCTAssertFalse(engine.canAddToTableau(card: queenSpades, colIndex: 0))
        
        // Column with King of Hearts accepts Queen of Spades (black on red), rejects Queen of Diamonds (red on red)
        engine.tableau[0].append(kingHearts)
        XCTAssertTrue(engine.canAddToTableau(card: queenSpades, colIndex: 0))
        XCTAssertFalse(engine.canAddToTableau(card: queenDiamonds, colIndex: 0))
    }
    
    func testWinConditionTrigger() {
        let engine = SolitaireEngine()
        
        // Fill all 4 foundations with 13 cards each
        for (fIdx, suit) in CardSuit.allCases.enumerated() {
            for rank in CardRank.allCases {
                engine.foundations[fIdx].append(PlayingCard(suit: suit, rank: rank, isFaceUp: true))
            }
        }
        
        engine.checkWin()
        XCTAssertTrue(engine.isWon)
        XCTAssertEqual(engine.cascadeCards.count, 52)
    }
}
