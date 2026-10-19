import SwiftUI
import WidgetKit

/// The styles a widget can wear. `standard` uses the default chosen in the
/// app (Settings › Widgets).
enum WidgetStyleId: String {
    case app, plain, pagoda, jade, deepField
}

extension Color {
    init(argb: Int) {
        let v = UInt32(truncatingIfNeeded: argb)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: Double((v >> 24) & 0xFF) / 255
        )
    }
}

/// A style's colours for one colour scheme.
struct Palette {
    let bg, ink, muted, accent, onAccent, holiday, moon, sabbath: Color
    let soft, holidaySoft, line, shade: Color

    init(_ values: [String: Int]) {
        func c(_ key: String, _ fallback: Int) -> Color { Color(argb: values[key] ?? fallback) }
        bg = c("bg", 0xFFFFFFFF)
        ink = c("ink", 0xFF111216)
        muted = c("muted", 0xFF6B6B73)
        accent = c("accent", 0xFF2F5BEA)
        onAccent = c("onAccent", 0xFFFFFFFF)
        holiday = c("holiday", 0xFFE5383B)
        moon = c("moon", 0xFFF2A900)
        sabbath = c("sabbath", 0xFFB7700B)
        soft = c("soft", 0x1F2F5BEA)
        holidaySoft = c("holidaySoft", 0x17E5383B)
        line = c("line", 0x243C3C43)
        shade = c("shade", 0x33767680)
    }

    static let fallback = Palette([:])
}

/// What a widget view needs to draw: the style, its palette for the
/// current scheme, and fonts.
struct WidgetLook {
    let style: WidgetStyleId
    let palette: Palette

    init(styleName: String, payload: WidgetPayload?, scheme: ColorScheme) {
        style = WidgetStyleId(rawValue: styleName) ?? .app
        if let pair = payload?.styles[style.rawValue] {
            palette = Palette(scheme == .dark ? pair.dark : pair.light)
        } else {
            palette = .fallback
        }
    }

    /// Numbers: serif for the heritage themes, rounded for Deep Field.
    func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch style {
        case .pagoda, .jade: return .system(size: size, weight: weight, design: .serif)
        case .deepField: return .system(size: size, weight: weight, design: .rounded)
        default: return .system(size: size, weight: weight)
        }
    }
}

// MARK: - Motifs (the grid themes' header art)

struct StupaShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + w * x / 100, y: rect.minY + h * y / 100)
        }
        var path = Path()
        path.move(to: p(50, 6)); path.addLine(to: p(50, 16))
        path.move(to: p(50, 16))
        path.addQuadCurve(to: p(44, 34), control: p(45, 26))
        path.addLine(to: p(56, 34))
        path.addQuadCurve(to: p(50, 16), control: p(55, 26))
        path.move(to: p(36, 42))
        path.addQuadCurve(to: p(64, 42), control: p(50, 28))
        path.addRect(CGRect(origin: p(30, 42), size: CGSize(width: w * 0.4, height: h * 0.06)))
        path.move(to: p(34, 48))
        path.addCurve(to: p(66, 48), control1: p(34, 70), control2: p(66, 70))
        for (y, inset) in [(70.0, 24.0), (78.0, 20.0), (86.0, 16.0)] {
            path.move(to: p(inset, y)); path.addLine(to: p(100 - inset, y))
        }
        return path
    }
}

struct SealShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let outer = CGRect(x: rect.midX - s * 0.36, y: rect.midY - s * 0.36, width: s * 0.72, height: s * 0.72)
        var path = Path(roundedRect: outer, cornerRadius: s * 0.06)
        let inner = outer.insetBy(dx: s * 0.08, dy: s * 0.08)
        path.addRect(inner)
        for f in [0.28, 0.5, 0.72] {
            let y = inner.minY + inner.height * f
            path.move(to: CGPoint(x: inner.minX + inner.width * 0.18, y: y))
            path.addLine(to: CGPoint(x: inner.maxX - inner.width * 0.18, y: y))
        }
        path.move(to: CGPoint(x: inner.midX, y: inner.minY + inner.height * 0.18))
        path.addLine(to: CGPoint(x: inner.midX, y: inner.maxY - inner.height * 0.18))
        return path
    }
}

struct StarsShape: Shape {
    static let stars: [(Double, Double, Double)] = [
        (20, 22, 3), (48, 12, 2), (78, 24, 3.5), (30, 48, 2), (62, 44, 2.5),
        (86, 56, 2), (16, 74, 2.5), (46, 78, 3.5), (74, 84, 2),
    ]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (x, y, r) in Self.stars {
            let c = CGPoint(x: rect.minX + rect.width * x / 100, y: rect.minY + rect.height * y / 100)
            let radius = r * rect.width / 100
            path.addEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
        }
        return path
    }
}

/// The style's motif, faint, in a corner. Nothing for app and plain.
struct MotifView: View {
    let look: WidgetLook
    var size: CGFloat = 64

    var body: some View {
        Group {
            switch look.style {
            case .pagoda:
                StupaShape().stroke(look.palette.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            case .jade:
                SealShape().stroke(look.palette.accent, lineWidth: 2.2)
            case .deepField:
                StarsShape().fill(look.palette.accent)
            default:
                EmptyView()
            }
        }
        .frame(width: size, height: size)
        .opacity(0.14)
        .accessibilityHidden(true)
    }
}
