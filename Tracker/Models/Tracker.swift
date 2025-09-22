import UIKit

enum WeekDay: String, CaseIterable, Hashable {
    case monday = "Понедельник"
    case tuesday = "Вторник"
    case wednesday = "Среда"
    case thursday = "Четверг"
    case friday = "Пятница"
    case saturday = "Суббота"
    case sunday = "Воскресенье"

    var shortName: String {
        switch self {
        case .monday: "Пн"
        case .tuesday: "Вт"
        case .wednesday: "Ср"
        case .thursday: "Чт"
        case .friday: "Пт"
        case .saturday: "Сб"
        case .sunday: "Вс"
        }
    }

    var order: Int {
        switch self {
        case .monday:  1
        case .tuesday:  2
        case .wednesday:  3
        case .thursday:  4
        case .friday:  5
        case .saturday:  6
        case .sunday:  7
        }
    }

    static func from(calendarWeekday int: Int) -> WeekDay? {
        switch int {
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        case 1: .sunday
        default: nil
        }
    }
}


struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: [WeekDay]
}

