import UIKit

enum WeekDay: Int, CaseIterable, Hashable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7

    var order: Int { self == .sunday ? 7 : rawValue - 1 }

    static func from(calendarWeekday value: Int) -> WeekDay? { WeekDay(rawValue: value) }

    var localizedLong: String {
        let symbols = WeekDay.formatter.weekdaySymbols ?? []
        let index = rawValue - 1
        return (0..<symbols.count).contains(index) ? symbols[index] : ""
    }

    var localizedShort: String {
        let symbols = WeekDay.formatter.shortWeekdaySymbols ?? []
        let index = rawValue - 1
        return (0..<symbols.count).contains(index) ? symbols[index] : ""
    }

    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        return df
    }()
}

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: [WeekDay]
}
