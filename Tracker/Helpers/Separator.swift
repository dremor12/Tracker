import UIKit

extension UIStackView {
    func addSeparator(color: UIColor = UIColor.separator.withAlphaComponent(0.1)) {
        let separator = UIView()
        separator.backgroundColor = .ypSeparatorColors
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        addArrangedSubview(separator)
    }
}
