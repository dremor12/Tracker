import UIKit

final class EmojiCell: UICollectionViewCell {
    static let reuseIdentifier = "EmojiCell"

    let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        let bg = UIView()
        bg.backgroundColor = .systemGray5
        bg.layer.cornerRadius = 8
        bg.clipsToBounds = true
        self.selectedBackgroundView = bg
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let bg = selectedBackgroundView else { return }
        let emojiSize = emojiLabel.intrinsicContentSize
        let w = emojiSize.width  + 14
        let h = emojiSize.height + 14
        let cx = contentView.bounds.midX
        let cy = contentView.bounds.midY

        bg.frame = CGRect(
            x: cx - w/2,
            y: cy - h/2,
            width: w,
            height: h
        )
        bg.layer.cornerRadius = h/2
    }

    func configure(with emoji: String, selected: Bool) {
        emojiLabel.text = emoji
        isSelected = selected
    }
}
