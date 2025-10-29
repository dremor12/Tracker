import UIKit

final class ColorCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCell"

    private let colorCornerRadius: CGFloat = 8
    private let glowGap: CGFloat = 4
    private let glowWidth: CGFloat = 3

    private let colorView = UIView()
    private let glowLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: glowGap),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: glowGap),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -glowGap),
            colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -glowGap)
        ])
        
        colorView.layer.cornerRadius = colorCornerRadius
        colorView.layer.cornerCurve = .continuous
        colorView.layer.masksToBounds = true

        layer.insertSublayer(glowLayer, below: colorView.layer)
        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = UIColor.clear.cgColor
        glowLayer.lineWidth = glowWidth
        glowLayer.shadowOpacity = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = colorView.frame.insetBy(dx: -glowGap - glowWidth/2, dy: -glowGap - glowWidth/2)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: colorCornerRadius + glowGap + glowWidth/2)
        glowLayer.path = path.cgPath
    }

    func configure(color: UIColor, selected: Bool) {
        colorView.backgroundColor = color
        if selected {
            glowLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
            glowLayer.shadowColor = color.cgColor
            glowLayer.shadowOpacity = 0.6
            glowLayer.shadowRadius = 4
            glowLayer.shadowOffset = .zero
        } else {
            glowLayer.strokeColor = UIColor.clear.cgColor
            glowLayer.shadowOpacity = 0
        }
    }
}
