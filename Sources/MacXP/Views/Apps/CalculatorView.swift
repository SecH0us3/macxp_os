import SwiftUI

public enum CalcOperator {
    case add
    case subtract
    case multiply
    case divide
}

public class CalculatorEngine: ObservableObject {
    @Published public var displayValue: String = "0"
    @Published public var memoryValue: Double = 0
    @Published public var hasMemory: Bool = false
    @Published public var hasError: Bool = false
    
    private var storedValue: Double? = nil
    private var pendingOperator: CalcOperator? = nil
    private var isEnteringNumber: Bool = false
    
    public init() {}
    
    public func inputDigit(_ digit: String) {
        guard !hasError else { return }
        
        if digit == "." {
            if !isEnteringNumber {
                displayValue = "0."
                isEnteringNumber = true
            } else if !displayValue.contains(".") {
                displayValue += "."
            }
            return
        }
        
        if !isEnteringNumber || displayValue == "0" {
            displayValue = digit
            isEnteringNumber = true
        } else {
            if displayValue.count < 16 {
                displayValue += digit
            }
        }
    }
    
    public func setOperator(_ op: CalcOperator) {
        guard !hasError else { return }
        
        if let stored = storedValue, let currentOp = pendingOperator, isEnteringNumber {
            let current = Double(displayValue) ?? 0
            let result = applyOperator(currentOp, left: stored, right: current)
            if hasError { return }
            displayValue = formatNumber(result)
            storedValue = result
        } else {
            storedValue = Double(displayValue) ?? 0
        }
        
        pendingOperator = op
        isEnteringNumber = false
    }
    
    public func calculate() {
        guard !hasError else { return }
        guard let stored = storedValue, let op = pendingOperator else { return }
        
        let current = Double(displayValue) ?? 0
        let result = applyOperator(op, left: stored, right: current)
        if !hasError {
            displayValue = formatNumber(result)
            storedValue = nil
            pendingOperator = nil
            isEnteringNumber = false
        }
    }
    
    private func applyOperator(_ op: CalcOperator, left: Double, right: Double) -> Double {
        switch op {
        case .add:
            return left + right
        case .subtract:
            return left - right
        case .multiply:
            return left * right
        case .divide:
            if right == 0 {
                hasError = true
                displayValue = "Cannot divide by zero"
                return 0
            }
            return left / right
        }
    }
    
    public func squareRoot() {
        guard !hasError else { return }
        let current = Double(displayValue) ?? 0
        if current < 0 {
            hasError = true
            displayValue = "Invalid input for function"
            return
        }
        let result = sqrt(current)
        displayValue = formatNumber(result)
        isEnteringNumber = false
    }
    
    public func reciprocal() {
        guard !hasError else { return }
        let current = Double(displayValue) ?? 0
        if current == 0 {
            hasError = true
            displayValue = "Cannot divide by zero"
            return
        }
        let result = 1.0 / current
        displayValue = formatNumber(result)
        isEnteringNumber = false
    }
    
    public func percentage() {
        guard !hasError else { return }
        let current = Double(displayValue) ?? 0
        if let stored = storedValue {
            let result = (stored * current) / 100.0
            displayValue = formatNumber(result)
        } else {
            let result = current / 100.0
            displayValue = formatNumber(result)
        }
        isEnteringNumber = false
    }
    
    public func negate() {
        guard !hasError else { return }
        if displayValue != "0" {
            if displayValue.hasPrefix("-") {
                displayValue.removeFirst()
            } else {
                displayValue = "-" + displayValue
            }
        }
    }
    
    public func backspace() {
        guard !hasError && isEnteringNumber else { return }
        if displayValue.count > 1 {
            displayValue.removeLast()
        } else {
            displayValue = "0"
            isEnteringNumber = false
        }
    }
    
    public func clearEntry() {
        guard !hasError else {
            clearAll()
            return
        }
        displayValue = "0"
        isEnteringNumber = false
    }
    
    public func clearAll() {
        displayValue = "0"
        storedValue = nil
        pendingOperator = nil
        isEnteringNumber = false
        hasError = false
    }
    
    public func memoryStore() {
        guard !hasError else { return }
        memoryValue = Double(displayValue) ?? 0
        hasMemory = (memoryValue != 0)
        isEnteringNumber = false
    }
    
    public func memoryRecall() {
        guard !hasError && hasMemory else { return }
        displayValue = formatNumber(memoryValue)
        isEnteringNumber = false
    }
    
    public func memoryAdd() {
        guard !hasError else { return }
        let current = Double(displayValue) ?? 0
        memoryValue += current
        hasMemory = (memoryValue != 0)
        isEnteringNumber = false
    }
    
    public func memoryClear() {
        memoryValue = 0
        hasMemory = false
    }
    
    public func handleKeyInput(_ input: Character) {
        switch input {
        case "0"..."9":
            inputDigit(String(input))
        case ".", ",":
            inputDigit(".")
        case "+":
            setOperator(.add)
        case "-":
            setOperator(.subtract)
        case "*", "x", "X":
            setOperator(.multiply)
        case "/":
            setOperator(.divide)
        case "=", "\r", "\n":
            calculate()
        case "\u{7f}", "\u{8}":
            backspace()
        case "c", "C", "\u{1b}":
            clearAll()
        case "e", "E":
            clearEntry()
        case "%":
            percentage()
        case "@", "s", "S":
            squareRoot()
        case "r", "R":
            reciprocal()
        case "n", "N":
            negate()
        default:
            break
        }
    }
    
    public func handleKeyInput(_ input: String) {
        for char in input {
            handleKeyInput(char)
        }
    }
    
    private func formatNumber(_ val: Double) -> String {
        if val.isInfinite || val.isNaN {
            hasError = true
            return "Error"
        }
        if floor(val) == val && abs(val) < 1e12 {
            return String(format: "%.0f", val)
        } else {
            var str = String(format: "%.8g", val)
            if str.contains(".") {
                while str.hasSuffix("0") {
                    str.removeLast()
                }
                if str.hasSuffix(".") {
                    str.removeLast()
                }
            }
            return str
        }
    }
}

public struct CalculatorView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var engine = CalculatorEngine()
    @State private var openMenu: String? = nil
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 6) {
                // Menu Bar
                HStack(spacing: 0) {
                    menuItem("Edit")
                    menuItem("View")
                    menuItem("Help")
                    Spacer()
                }
                .frame(height: 20)
                
                // Display Box
                HStack {
                    Spacer()
                    Text(engine.displayValue)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
                .frame(height: 32)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
                )
                .padding(.horizontal, 6)
                
                // Top Action Row
                HStack(spacing: 6) {
                    // Memory Status Box
                    ZStack {
                        Rectangle()
                            .fill(Color(red: 0.93, green: 0.91, blue: 0.85))
                            .overlay(Rectangle().strokeBorder(Color.gray, lineWidth: 1))
                        if engine.hasMemory {
                            Text("M")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.8, green: 0.0, blue: 0.0))
                        }
                    }
                    .frame(width: 32, height: 26)
                    
                    Spacer()
                    
                    calcButton(title: "Backspace", color: Color(red: 0.5, green: 0.0, blue: 0.0), width: 66) {
                        engine.backspace()
                    }
                    calcButton(title: "CE", color: Color(red: 0.5, green: 0.0, blue: 0.0), width: 44) {
                        engine.clearEntry()
                    }
                    calcButton(title: "C", color: Color(red: 0.5, green: 0.0, blue: 0.0), width: 44) {
                        engine.clearAll()
                    }
                }
                .padding(.horizontal, 6)
                
                // Button Grid
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        calcButton(title: "MC", color: .red) { engine.memoryClear() }
                        calcButton(title: "7", color: .blue) { engine.inputDigit("7") }
                        calcButton(title: "8", color: .blue) { engine.inputDigit("8") }
                        calcButton(title: "9", color: .blue) { engine.inputDigit("9") }
                        calcButton(title: "/", color: .red) { engine.setOperator(.divide) }
                        calcButton(title: "sqrt", color: .blue) { engine.squareRoot() }
                    }
                    
                    HStack(spacing: 5) {
                        calcButton(title: "MR", color: .red) { engine.memoryRecall() }
                        calcButton(title: "4", color: .blue) { engine.inputDigit("4") }
                        calcButton(title: "5", color: .blue) { engine.inputDigit("5") }
                        calcButton(title: "6", color: .blue) { engine.inputDigit("6") }
                        calcButton(title: "*", color: .red) { engine.setOperator(.multiply) }
                        calcButton(title: "%", color: .blue) { engine.percentage() }
                    }
                    
                    HStack(spacing: 5) {
                        calcButton(title: "MS", color: .red) { engine.memoryStore() }
                        calcButton(title: "1", color: .blue) { engine.inputDigit("1") }
                        calcButton(title: "2", color: .blue) { engine.inputDigit("2") }
                        calcButton(title: "3", color: .blue) { engine.inputDigit("3") }
                        calcButton(title: "-", color: .red) { engine.setOperator(.subtract) }
                        calcButton(title: "1/x", color: .blue) { engine.reciprocal() }
                    }
                    
                    HStack(spacing: 5) {
                        calcButton(title: "M+", color: .red) { engine.memoryAdd() }
                        calcButton(title: "0", color: .blue) { engine.inputDigit("0") }
                        calcButton(title: "+/-", color: .blue) { engine.negate() }
                        calcButton(title: ".", color: .blue) { engine.inputDigit(".") }
                        calcButton(title: "+", color: .red) { engine.setOperator(.add) }
                        calcButton(title: "=", color: .red) { engine.calculate() }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            }
            .background(Color(red: 0.93, green: 0.91, blue: 0.85))
            .focusable()
            .calculatorKeyInput { chars in
                engine.handleKeyInput(chars)
            }
        }
    }
    
    private func menuItem(_ title: String) -> some View {
        Button(action: {}) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func calcButton(title: String, color: Color, width: CGFloat? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color == .blue ? Color(red: 0.0, green: 0.0, blue: 0.6) : Color(red: 0.6, green: 0.0, blue: 0.0))
                .frame(maxWidth: width == nil ? .infinity : width, maxHeight: .infinity)
                .frame(height: 28)
                .background(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.88, green: 0.86, blue: 0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private extension View {
    @ViewBuilder
    func calculatorKeyInput(_ onInput: @escaping (String) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onKeyPress { keyPress in
                if !keyPress.characters.isEmpty {
                    onInput(keyPress.characters)
                    return .handled
                }
                return .ignored
            }
        } else {
            self
        }
    }
}
