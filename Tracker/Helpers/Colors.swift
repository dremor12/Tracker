import UIKit

final class Colors {
    static let viewBackgroundColor = UIColor.systemBackground
    
    static let buttonColor = UIColor { (traits: UITraitCollection) -> UIColor in
        if traits.userInterfaceStyle == .light {
            return UIColor.ypBlackDay
        } else {
            return .ypBlackNight
        }
    }
    
    static let buttonTextColor = UIColor { (traits: UITraitCollection) -> UIColor in
        if traits.userInterfaceStyle == .light {
            return UIColor.ypWhiteDay
        } else {
            return .ypWhiteNight
        }
    }
    
    static let backgroundView = UIColor { (traits: UITraitCollection) -> UIColor in
        if traits.userInterfaceStyle == .light {
            return UIColor.ypBackgroundDay
        } else {
            return .ypBackgroundNight
        }
    }
}
