import UIKit

enum Weekday: Int, CaseIterable {
    case monday = 2,
         tuesday = 3,
         wednesday = 4,
         thursday = 5,
         friday = 6,
         saturday = 7,
         sunday = 1
}

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: [Weekday]?
}

