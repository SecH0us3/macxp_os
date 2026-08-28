import SwiftUI

public enum PaintTool: String, CaseIterable, Equatable {
    case pencil = "Pencil"
    case brush = "Brush"
    case eraser = "Eraser"
    case fill = "Fill With Color"
    case eyedropper = "Pick Color"
    case line = "Line"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    
    public var iconName: String {
        switch self {
        case .pencil: return "pencil"
        case .brush: return "paintbrush.fill"
        case .eraser: return "eraser.fill"
        case .fill: return "drop.fill"
        case .eyedropper: return "eyedropper"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        }
    }
}

public struct PaintAction: Identifiable, Equatable {
    public let id: UUID
    public var tool: PaintTool
    public var points: [CGPoint]
    public var color: Color
    public var width: CGFloat
    public var isFilled: Bool
    
    public init(
        id: UUID = UUID(),
        tool: PaintTool,
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        isFilled: Bool = false
    ) {
        self.id = id
        self.tool = tool
        self.points = points
        self.color = color
        self.width = width
        self.isFilled = isFilled
    }
}

public class PaintEngine: ObservableObject {
    @Published public var selectedTool: PaintTool = .pencil
    @Published public var strokeWidth: CGFloat = 1
    @Published public var primaryColor: Color = .black
    @Published public var secondaryColor: Color = .white
    @Published public var actions: [PaintAction] = []
    @Published public var redoStack: [PaintAction] = []
    @Published public var currentAction: PaintAction? = nil
    
    public init() {}
    
    public var canUndo: Bool {
        !actions.isEmpty
    }
    
    public var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    public func selectTool(_ tool: PaintTool) {
        selectedTool = tool
    }
    
    public func setStrokeWidth(_ width: CGFloat) {
        strokeWidth = width
    }
    
    public func setPrimaryColor(_ color: Color) {
        primaryColor = color
    }
    
    public func setSecondaryColor(_ color: Color) {
        secondaryColor = color
    }
    
    public func addPencilStroke(points: [CGPoint], color: Color, width: CGFloat) {
        let action = PaintAction(tool: .pencil, points: points, color: color, width: width)
        actions.append(action)
        redoStack.removeAll()
    }
    
    public func startDrawing(at point: CGPoint) {
        let drawColor = (selectedTool == .eraser) ? secondaryColor : primaryColor
        let effectiveWidth = (selectedTool == .eraser) ? max(8, strokeWidth * 3) : strokeWidth
        currentAction = PaintAction(tool: selectedTool, points: [point], color: drawColor, width: effectiveWidth)
    }
    
    public func updateDrawing(to point: CGPoint) {
        guard var action = currentAction else { return }
        switch action.tool {
        case .pencil, .brush, .eraser:
            action.points.append(point)
        case .line, .rectangle, .ellipse:
            if action.points.count > 1 {
                action.points[1] = point
            } else {
                action.points.append(point)
            }
        case .fill, .eyedropper:
            break
        }
        currentAction = action
    }
    
    public func finishDrawing() {
        guard let action = currentAction else { return }
        actions.append(action)
        currentAction = nil
        redoStack.removeAll()
    }
    
    public func undo() {
        guard let last = actions.popLast() else { return }
        redoStack.append(last)
    }
    
    public func redo() {
        guard let next = redoStack.popLast() else { return }
        actions.append(next)
    }
    
    public func clearCanvas() {
        actions.removeAll()
        redoStack.removeAll()
        currentAction = nil
    }
}

public struct PaintView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var engine = PaintEngine()
    @State private var cursorLocation: CGPoint = .zero
    @State private var openMenu: String? = nil
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Menu Bar
            menuBar
            
            Divider()
            
            // 2. Main Work Area (Toolbox + Canvas)
            HStack(spacing: 0) {
                // Left Toolbox
                toolBoxView
                    .frame(width: 58)
                    .background(Color(red: 0.94, green: 0.94, blue: 0.94))
                
                Divider()
                
                // Canvas Area
                canvasContainer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // 3. Bottom Color Palette
            colorPaletteBar
            
            // 4. Status Bar
            statusBar
        }
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .overlay(
            openMenu != nil ? menuDropdownView : nil,
            alignment: .topLeading
        )
    }
    
    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 0) {
            menuButton(title: "File")
            menuButton(title: "Edit")
            menuButton(title: "View")
            menuButton(title: "Image")
            menuButton(title: "Help")
            Spacer()
        }
        .frame(height: 20)
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
    
    private var menuDropdownView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if openMenu == "File" {
                menuItem(title: "New", shortcut: "Ctrl+N") { engine.clearCanvas() }
                Divider()
                menuItem(title: "Exit") { windowManager.closeWindow(id: window.id) }
            } else if openMenu == "Edit" {
                menuItem(title: "Undo", shortcut: "Ctrl+Z") { engine.undo() }
                menuItem(title: "Redo", shortcut: "Ctrl+Y") { engine.redo() }
            } else if openMenu == "Image" {
                menuItem(title: "Clear Image", shortcut: "Ctrl+Shift+N") { engine.clearCanvas() }
            }
        }
        .frame(width: 140)
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
    
    // MARK: - Toolbox
    private var toolBoxView: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: [GridItem(.fixed(24)), GridItem(.fixed(24))], spacing: 2) {
                ForEach(PaintTool.allCases, id: \.self) { tool in
                    Button(action: {
                        engine.selectTool(tool)
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(engine.selectedTool == tool ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.94, green: 0.94, blue: 0.94))
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(
                                            engine.selectedTool == tool ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color(red: 0.7, green: 0.7, blue: 0.7),
                                            lineWidth: 1
                                        )
                                )
                            
                            Image(systemName: tool.iconName)
                                .font(.system(size: 11))
                                .foregroundColor(.black)
                        }
                        .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 4)
            
            // Stroke width selector box
            VStack(spacing: 2) {
                ForEach([CGFloat(1), CGFloat(2), CGFloat(4), CGFloat(8)], id: \.self) { w in
                    Button(action: {
                        engine.setStrokeWidth(w)
                    }) {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 28, height: w)
                            Spacer()
                        }
                        .frame(height: 14)
                        .background(engine.strokeWidth == w ? Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.3) : Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .border(Color(red: 0.6, green: 0.6, blue: 0.6), width: 1)
            .padding(.horizontal, 4)
            
            Spacer()
        }
    }
    
    // MARK: - Canvas
    private var canvasContainer: some View {
        ScrollView([.horizontal, .vertical]) {
            Canvas { context, size in
                // Draw committed actions
                for action in engine.actions {
                    drawAction(action, in: &context)
                }
                // Draw current in-progress action
                if let current = engine.currentAction {
                    drawAction(current, in: &context)
                }
            }
            .frame(width: 800, height: 600)
            .background(Color.white)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        cursorLocation = value.location
                        if engine.currentAction == nil {
                            engine.startDrawing(at: value.location)
                        } else {
                            engine.updateDrawing(to: value.location)
                        }
                    }
                    .onEnded { _ in
                        engine.finishDrawing()
                    }
            )
            .overlay(
                Rectangle()
                    .strokeBorder(Color.gray, lineWidth: 1)
            )
            .padding(8)
        }
        .background(Color(red: 0.80, green: 0.80, blue: 0.80))
    }
    
    private func drawAction(_ action: PaintAction, in context: inout GraphicsContext) {
        guard !action.points.isEmpty else { return }
        
        switch action.tool {
        case .pencil, .brush, .eraser:
            var path = Path()
            path.move(to: action.points[0])
            for i in 1..<action.points.count {
                path.addLine(to: action.points[i])
            }
            context.stroke(
                path,
                with: .color(action.color),
                style: StrokeStyle(lineWidth: action.width, lineCap: .round, lineJoin: .round)
            )
            
        case .line:
            guard action.points.count > 1 else { return }
            var path = Path()
            path.move(to: action.points[0])
            path.addLine(to: action.points[1])
            context.stroke(
                path,
                with: .color(action.color),
                style: StrokeStyle(lineWidth: action.width, lineCap: .square)
            )
            
        case .rectangle:
            guard action.points.count > 1 else { return }
            let p1 = action.points[0]
            let p2 = action.points[1]
            let rect = CGRect(
                x: min(p1.x, p2.x),
                y: min(p1.y, p2.y),
                width: abs(p2.x - p1.x),
                height: abs(p2.y - p1.y)
            )
            context.stroke(
                Path(rect),
                with: .color(action.color),
                style: StrokeStyle(lineWidth: action.width)
            )
            
        case .ellipse:
            guard action.points.count > 1 else { return }
            let p1 = action.points[0]
            let p2 = action.points[1]
            let rect = CGRect(
                x: min(p1.x, p2.x),
                y: min(p1.y, p2.y),
                width: abs(p2.x - p1.x),
                height: abs(p2.y - p1.y)
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(action.color),
                style: StrokeStyle(lineWidth: action.width)
            )
            
        case .fill, .eyedropper:
            break
        }
    }
    
    // MARK: - Color Palette
    private var colorPaletteBar: some View {
        HStack(spacing: 8) {
            // Selected Color Boxes (Primary / Secondary)
            ZStack(alignment: .topLeading) {
                // Secondary Color (Background)
                Rectangle()
                    .fill(engine.secondaryColor)
                    .frame(width: 16, height: 16)
                    .border(Color.black, width: 1)
                    .offset(x: 10, y: 10)
                
                // Primary Color (Foreground)
                Rectangle()
                    .fill(engine.primaryColor)
                    .frame(width: 16, height: 16)
                    .border(Color.black, width: 1)
            }
            .frame(width: 32, height: 32)
            .padding(.leading, 6)
            
            // 28 Colors in 2 Rows of 14
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(row1Colors, id: \.self) { c in
                        colorSquare(c)
                    }
                }
                HStack(spacing: 2) {
                    ForEach(row2Colors, id: \.self) { c in
                        colorSquare(c)
                    }
                }
            }
            
            Spacer()
        }
        .frame(height: 38)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
    }
    
    private func colorSquare(_ color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(
                Rectangle()
                    .strokeBorder(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: 1)
            )
            .onTapGesture {
                engine.setPrimaryColor(color)
            }
            .contextMenu {
                Button("Set Background Color") {
                    engine.setSecondaryColor(color)
                }
            }
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Text("\(Int(cursorLocation.x)), \(Int(cursorLocation.y))px")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 4)
                .overlay(Rectangle().strokeBorder(Color.gray, lineWidth: 1))
            
            Spacer()
            
            Text("800 x 600px")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal, 4)
                .overlay(Rectangle().strokeBorder(Color.gray, lineWidth: 1))
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .border(Color(red: 0.80, green: 0.80, blue: 0.80), width: 1)
    }
    
    // 28 Classic XP Colors
    private var row1Colors: [Color] {
        [
            .black,
            Color(red: 0.5, green: 0.5, blue: 0.5),
            Color(red: 0.5, green: 0.0, blue: 0.0),
            Color(red: 0.5, green: 0.5, blue: 0.0),
            Color(red: 0.0, green: 0.5, blue: 0.0),
            Color(red: 0.0, green: 0.5, blue: 0.5),
            Color(red: 0.0, green: 0.0, blue: 0.5),
            Color(red: 0.5, green: 0.0, blue: 0.5),
            Color(red: 0.5, green: 0.5, blue: 0.25),
            Color(red: 0.0, green: 0.25, blue: 0.25),
            Color(red: 0.0, green: 0.5, blue: 1.0),
            Color(red: 0.0, green: 0.25, blue: 0.5),
            Color(red: 0.5, green: 0.0, blue: 1.0),
            Color(red: 0.5, green: 0.25, blue: 0.0)
        ]
    }
    
    private var row2Colors: [Color] {
        [
            .white,
            Color(red: 0.75, green: 0.75, blue: 0.75),
            Color(red: 1.0, green: 0.0, blue: 0.0),
            Color(red: 1.0, green: 1.0, blue: 0.0),
            Color(red: 0.0, green: 1.0, blue: 0.0),
            Color(red: 0.0, green: 1.0, blue: 1.0),
            Color(red: 0.0, green: 0.0, blue: 1.0),
            Color(red: 1.0, green: 0.0, blue: 1.0),
            Color(red: 1.0, green: 1.0, blue: 0.5),
            Color(red: 0.0, green: 1.0, blue: 0.5),
            Color(red: 0.5, green: 1.0, blue: 1.0),
            Color(red: 0.5, green: 0.5, blue: 1.0),
            Color(red: 1.0, green: 0.0, blue: 0.5),
            Color(red: 1.0, green: 0.5, blue: 0.25)
        ]
    }
}
