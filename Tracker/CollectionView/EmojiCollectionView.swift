import UIKit

final class EmojiCollectionView: UICollectionView {

    var emojis: [String] = [] {
        didSet {
            reloadData()
            updateHeightIfNeeded()
        }
    }

    var onSelectEmoji: ((String) -> Void)?
    private(set) var selectedEmoji: String?

    private let numberOfColumns: CGFloat = 6
    private let sectionInsets = UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
    private let interItemSpacing: CGFloat = 25
    private let lineSpacing: CGFloat = 14

    private var lastWidth: CGFloat = 0
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        (collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = .zero

        delegate = self
        dataSource = self

        backgroundColor = .clear
        contentInset = .zero
        contentInsetAdjustmentBehavior = .never
        isScrollEnabled = false
        allowsMultipleSelection = false

        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width != lastWidth {
            lastWidth = bounds.width
            updateHeightIfNeeded()
        }
    }

    private func calculatedHeight(for width: CGFloat) -> CGFloat {
        let totalHorizontalInset = sectionInsets.left + sectionInsets.right
        let totalInterItemSpacing = interItemSpacing * (numberOfColumns - 1)
        let availableWidth = width - totalHorizontalInset - totalInterItemSpacing
        guard availableWidth > 0 else { return 0 }
        let cellSide = floor(availableWidth / numberOfColumns)
        let numberOfRows = ceil(CGFloat(emojis.count) / numberOfColumns)
        return numberOfRows * cellSide
            + max(0, numberOfRows - 1) * lineSpacing
            + sectionInsets.top + sectionInsets.bottom
    }

    private func updateHeightIfNeeded() {
        let currentWidth = bounds.width
        guard currentWidth > 0 else { return }
        let newHeight = calculatedHeight(for: currentWidth)
        if abs(heightConstraint.constant - newHeight) > 0.5 {
            heightConstraint.constant = newHeight
            invalidateIntrinsicContentSize()
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
        }
    }
}

extension EmojiCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojis[indexPath.item]
        if selectedEmoji != emoji {
            if let previousEmoji = selectedEmoji,
               let previousIndex = emojis.firstIndex(of: previousEmoji) {
                let previousIndexPath = IndexPath(item: previousIndex, section: 0)
                collectionView.deselectItem(at: previousIndexPath, animated: false)
                (collectionView.cellForItem(at: previousIndexPath) as? EmojiCell)?.isSelected = false
            }
            selectedEmoji = emoji
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        (collectionView.cellForItem(at: indexPath) as? EmojiCell)?.isSelected = true
        onSelectEmoji?(emoji)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let emoji = emojis[indexPath.item]
        let isSelectedEmoji = (emoji == selectedEmoji)
        if isSelectedEmoji {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        (cell as? EmojiCell)?.isSelected = isSelectedEmoji
    }
}

extension EmojiCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojis.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EmojiCell.reuseIdentifier,
            for: indexPath
        ) as! EmojiCell
        let emoji = emojis[indexPath.item]
        cell.configure(with: emoji, selected: emoji == selectedEmoji)
        return cell
    }
}

extension EmojiCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalHorizontalInset = sectionInsets.left + sectionInsets.right
        let totalInterItemSpacing = interItemSpacing * (numberOfColumns - 1)
        let availableWidth = collectionView.bounds.width - totalHorizontalInset - totalInterItemSpacing
        let cellSide = floor(availableWidth / numberOfColumns)
        return CGSize(width: cellSide, height: cellSide)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        interItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        lineSpacing
    }
}
