import Foundation

enum Formatters {
    static let currency: FloatingPointFormatStyle<Double>.Currency = .currency(code: "USD").precision(.fractionLength(0))
    static let monthYear: Date.FormatStyle = .dateTime.month(.abbreviated).year()

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}
