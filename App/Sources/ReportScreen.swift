import ExpenseCore
import SwiftData
import SwiftUI
import UIKit

/// 1.19: the monthly report — a short preview and a PDF to share.
struct ReportScreen: View {
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @EnvironmentObject private var rates: ExchangeRates
    @State private var choice: Choice = .thisMonth
    @State private var pdfURL: URL?

    enum Choice: String, CaseIterable, Identifiable {
        case thisMonth = "This month", lastMonth = "Last month"
        var id: String { rawValue }
        var period: Statistics.Period { self == .thisMonth ? .thisMonth : .lastMonth }
    }

    private var calendar: Calendar { .current }
    private var report: MonthReport {
        MonthReport.make(expenses.map(\.spend), period: choice.period, now: Date(),
                         rates: rates.table, calendar: calendar)
    }

    /// Changes whenever the month or any shown number changes, so the file is rewritten.
    private var fileKey: String {
        let r = report
        return "\(choice.rawValue)|\(r.count)|\(r.total.kronor)|\(expenses.map { "\($0.date.timeIntervalSince1970)\($0.amount)\($0.title)\($0.category)\($0.consumer)\($0.visitedPlace)" }.joined())"
    }

    var body: some View {
        let r = report
        VStack(spacing: 0) {
            Picker("Month", selection: $choice) {
                ForEach(Choice.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("report-month")
            .padding(.horizontal)
            .padding(.vertical, 8)

            List {
                if r.count == 0 {
                    Text("Nothing was logged in this month.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("report-empty")
                } else {
                    Section {
                        Text(Self.title(r.interval.start, calendar: calendar))
                            .font(.headline)
                        Text(Money.text(r.total))
                            .font(.largeTitle.weight(.semibold))
                            .monospacedDigit()
                        Text(r.count == 1 ? "1 expense" : "\(r.count) expenses")
                            .foregroundStyle(.secondary)
                    }
                    Section("By category") {
                        ForEach(r.categories) { c in
                            HStack {
                                Text(c.name.isEmpty ? "No category" : c.name)
                                Spacer()
                                Text("\(c.count)× · \(Money.kronor(c.kronor))")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if r.count > 0, let url = pdfURL {
                ShareLink(item: url) {
                    Text("Share PDF").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("report-share")
                .padding()
            }
        }
        .navigationTitle("Monthly report")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: fileKey) { writeFile() }
    }

    private func writeFile() {
        let r = report
        guard r.count > 0 else { pdfURL = nil; return }
        let c = calendar
        let comps = c.dateComponents([.year, .month], from: r.interval.start)
        let name = String(format: "Expenses %04d-%02d.pdf", comps.year ?? 0, comps.month ?? 0)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let data = ReportPDF.data(report: r, expenses: Array(expenses), calendar: c)
        do {
            try data.write(to: url, options: .atomic)
            pdfURL = url
        } catch {
            pdfURL = nil
        }
    }

    static func title(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }
}

/// The A4 page drawing: plain black text on white, margins 40.
enum ReportPDF {
    private static let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let margin: CGFloat = 40

    static func data(report: MonthReport, expenses: [Expense], calendar: Calendar) -> Data {
        let rows = expenses
            .filter { $0.date >= report.interval.start && $0.date < report.interval.end }
            .sorted { $0.date < $1.date }

        let dayFormat = DateFormatter()
        dayFormat.calendar = calendar; dayFormat.timeZone = calendar.timeZone
        dayFormat.locale = Locale(identifier: "en_US"); dayFormat.dateFormat = "d MMM"
        let timeFormat = DateFormatter()
        timeFormat.calendar = calendar; timeFormat.timeZone = calendar.timeZone
        timeFormat.locale = Locale(identifier: "en_US_POSIX"); timeFormat.dateFormat = "HH:mm"

        func attrs(_ size: CGFloat, bold: Bool = false, align: NSTextAlignment = .left,
                   truncate: Bool = true) -> [NSAttributedString.Key: Any] {
            let p = NSMutableParagraphStyle()
            p.alignment = align
            p.lineBreakMode = truncate ? .byTruncatingTail : .byWordWrapping
            return [.font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size),
                    .foregroundColor: UIColor.black, .paragraphStyle: p]
        }

        let width = pageSize.width - 2 * margin
        let bottom = pageSize.height - margin - 14
        var page = 0
        var y = margin

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        return renderer.pdfData { ctx in
            func newPage() {
                ctx.beginPage()
                page += 1
                y = margin
                ("Page \(page)" as NSString).draw(
                    in: CGRect(x: margin, y: pageSize.height - margin, width: width, height: 14),
                    withAttributes: attrs(9, align: .center))
            }
            func text(_ s: String, _ x: CGFloat, _ w: CGFloat, _ a: [NSAttributedString.Key: Any]) {
                (s as NSString).draw(in: CGRect(x: x, y: y, width: w, height: 16), withAttributes: a)
            }
            func line(_ s: String, size: CGFloat, bold: Bool = false, gap: CGFloat) {
                if y + size + 4 > bottom { newPage() }
                text(s, margin, width, attrs(size, bold: bold))
                y += size + 4 + gap
            }

            newPage()
            line("Expenses — " + ReportScreen.title(report.interval.start, calendar: calendar),
                 size: 22, bold: true, gap: 4)
            line("Total \(totalText(report.total)) · \(report.count == 1 ? "1 expense" : "\(report.count) expenses")",
                 size: 13, gap: 14)

            line("By category", size: 15, bold: true, gap: 4)
            for c in report.categories {
                if y + 16 > bottom { newPage() }
                text(c.name.isEmpty ? "No category" : c.name, margin, 300, attrs(11))
                text("\(c.count)×", margin + 300, 50, attrs(11, align: .right))
                text(Money.kronor(c.kronor), margin + 360, width - 360, attrs(11, align: .right))
                y += 16
            }
            y += 12

            line("Every expense", size: 15, bold: true, gap: 4)
            // Columns: date 40, time 34, description 130, category 80, for 50, place 90, amount 91.
            let xs: [CGFloat] = [0, 40, 78, 210, 292, 344, 436].map { margin + $0 }
            let ws: [CGFloat] = [38, 34, 128, 78, 48, 88, width - 436]
            for e in rows {
                if y + 16 > bottom { newPage() }
                let small = attrs(10)
                text(dayFormat.string(from: e.date), xs[0], ws[0], small)
                text(timeFormat.string(from: e.date), xs[1], ws[1], small)
                text(e.title, xs[2], ws[2], small)
                text(e.category, xs[3], ws[3], small)
                text(e.consumer, xs[4], ws[4], small)
                text(e.visitedPlace, xs[5], ws[5], small)
                text(e.amount.formatted(.currency(code: e.currency)), xs[6], ws[6], attrs(10, align: .right))
                y += 15
            }
        }
    }

    private static func totalText(_ total: KronorTotal) -> String {
        var t = Money.text(total)
        t = t.replacingOccurrences(of: "\u{00A0}", with: " ")
        return t
    }
}
