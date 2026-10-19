import SwiftUI
import WidgetKit

// MARK: - Moon

/// Same drawing as the app's Dart `MoonPainter`: a lit half disc plus a
/// terminator ellipse of half-width r·|1 − 2k|, tilted 40° the way the moon
/// lies near 20°N (waxing lit toward the lower right, waning the upper left).
struct MoonLitShape: Shape {
    let illumination: Double
    let isWaxing: Bool
    static let tilt = 40.0 * Double.pi / 180

    func path(in rect: CGRect) -> Path {
        let k = min(max(illumination, 0), 1)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        if k < 0.015 { return path }
        if k > 0.985 {
            path.addEllipse(in: CGRect(x: rect.midX - r, y: rect.midY - r, width: 2 * r, height: 2 * r))
            return path
        }
        let terminator = r * abs(1 - 2 * k)
        let bulge = k < 0.5 ? 1.0 : -1.0
        let steps = 48
        var points: [CGPoint] = []
        for i in 0...steps {
            let a = -Double.pi / 2 + Double.pi * Double(i) / Double(steps)
            points.append(CGPoint(x: r * cos(a), y: r * sin(a)))
        }
        for i in 1..<steps {
            let a = Double.pi / 2 - Double.pi * Double(i) / Double(steps)
            points.append(CGPoint(x: bulge * terminator * cos(a), y: r * sin(a)))
        }
        let transform = CGAffineTransform(scaleX: isWaxing ? 1 : -1, y: 1)
            .concatenating(CGAffineTransform(rotationAngle: Self.tilt))
            .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))
        path.addLines(points.map { $0.applying(transform) })
        path.closeSubpath()
        return path
    }
}

struct MoonView: View {
    let illumination: Double
    let isWaxing: Bool
    let lit: Color
    let shade: Color

    init(day: WidgetPayload.Day, palette: Palette) {
        illumination = day.il
        isWaxing = day.wx
        lit = palette.moon
        shade = palette.shade
    }

    init(illumination: Double, isWaxing: Bool, lit: Color, shade: Color) {
        self.illumination = illumination
        self.isWaxing = isWaxing
        self.lit = lit
        self.shade = shade
    }

    var body: some View {
        ZStack {
            Circle().fill(shade)
            MoonLitShape(illumination: illumination, isWaxing: isWaxing)
                .fill(lit)
                .widgetAccentable()
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - Chips

struct Chip: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }
}

// MARK: - Month grid

/// The month as 7 columns of days with lunar days under them, today filled,
/// holidays in red and Sabbath dots. Trailing weeks wholly in the next month
/// are dropped.
struct MonthGridView: View {
    let payload: WidgetPayload
    let month: WidgetPayload.Month
    let monthDate: Date
    let today: Date
    let look: WidgetLook
    let dense: Bool

    var body: some View {
        let p = look.palette
        let rows = visibleRows
        let todayDay = Calendar.current.isDate(monthDate, equalTo: today, toGranularity: .month)
            ? Calendar.current.component(.day, from: today) : nil
        VStack(spacing: dense ? 1 : 2) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(payload.s.weekdaysShort[i])
                        .font(.system(size: dense ? 8.5 : 10, weight: .semibold))
                        .foregroundStyle(i == 0 ? p.holiday : p.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        cell(month.cells[row * 7 + col], col: col, todayDay: todayDay)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private var visibleRows: Int {
        // Six rows unless the last week holds no day of this month.
        month.cells[35].in ? 6 : 5
    }

    @ViewBuilder
    private func cell(_ c: WidgetPayload.Month.Cell, col: Int, todayDay: Int?) -> some View {
        let p = look.palette
        let isToday = c.in && c.d == todayDay
        let red = c.in && (c.hol || col == 0)
        VStack(spacing: dense ? 0 : 1.5) {
            Text(payload.num(c.d))
                .font(look.number(dense ? 11 : 13.5, weight: isToday ? .bold : .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
                .foregroundStyle(isToday ? p.onAccent : (red ? p.holiday : p.ink))
            if !dense {
                Group {
                    if c.ph == 1 {
                        Circle().fill(p.moon).frame(width: 5, height: 5)
                    } else if c.ph == 3 {
                        Circle().stroke(p.muted, lineWidth: 1).frame(width: 5, height: 5)
                    } else {
                        Text(c.ln)
                            .font(.system(size: 7.5))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(isToday ? p.onAccent.opacity(0.85) : p.muted)
                    }
                }
                .frame(height: 11)
                Circle()
                    .fill(c.sab && c.in ? p.sabbath : .clear)
                    .frame(width: 3.5, height: 3.5)
            }
        }
        .padding(.vertical, dense ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: dense ? 6 : 8).fill(p.accent).widgetAccentable()
            } else if c.in && c.hol {
                RoundedRectangle(cornerRadius: dense ? 6 : 8).fill(p.holidaySoft)
            }
        }
        .opacity(c.in ? 1 : 0.32)
    }
}

// MARK: - Week strip

struct WeekStripView: View {
    let payload: WidgetPayload
    let start: Date
    let look: WidgetLook

    var body: some View {
        let p = look.palette
        HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: start)!
                let day = payload.day(for: date)
                VStack(spacing: 3) {
                    Text(day.map { payload.s.weekdaysShort[$0.wd] } ?? "")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(day?.wd == 0 ? p.holiday : p.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(payload.num(Calendar.current.component(.day, from: date)))
                        .font(look.number(16))
                        .monospacedDigit()
                        .foregroundStyle(i == 0 ? p.accent : ((day?.hol.isEmpty == false) ? p.holiday : p.ink))
                    if let day {
                        MoonView(day: day, palette: p).frame(width: 13, height: 13)
                    }
                    Circle()
                        .fill(day?.isSabbath == true ? p.sabbath : .clear)
                        .frame(width: 4, height: 4)
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background {
                    if i == 0 { RoundedRectangle(cornerRadius: 10).fill(p.soft) }
                }
            }
        }
    }
}

// MARK: - Empty state

/// Before the app has written any data.
struct OpenAppView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 22, weight: .semibold))
            Text("Myanmar Calendar")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
