import UIKit

final class ColorCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCell"

    private let colorView: UIView = {
        let colorView = UIView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        return colorView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            colorView.widthAnchor.constraint(equalTo: colorView.heightAnchor)
        ])

        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        colorView.layer.cornerRadius = 10
        colorView.layer.masksToBounds = true

        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = UIColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = UIColor.clear.cgColor
    }

    func applySelectedAppearance(_ selected: Bool) {
        contentView.layer.borderWidth = selected ? 2 : 0
        contentView.layer.borderColor = selected
            ? UIColor.label.withAlphaComponent(0.4).cgColor
            : UIColor.clear.cgColor
    }

    func configure(color: UIColor) {
        colorView.backgroundColor = color
    }
}
