import UIKit

final class ColorCollectionView: UICollectionView {

    var colors: [UIColor] = [] {
        didSet {
            reloadData()
            updateHeightIfNeeded()
        }
    }

    private(set) var selectedColor: UIColor?
    var onSelectColor: ((UIColor) -> Void)?
    private(set) var selectedIndex: Int?

    private let numberOfColumns: CGFloat = 6
    private let sectionInsets = UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 18)
    private let interItemSpacing: CGFloat = 17
    private let lineSpacing: CGFloat = 12

    private var lastWidth: CGFloat = 0
    private var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        (collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = .zero

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

        dataSource = self
        delegate = self
        register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
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
        let numberOfRows = ceil(CGFloat(colors.count) / numberOfColumns)
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

extension ColorCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ColorCell.reuseIdentifier,
            for: indexPath
        ) as! ColorCell
        let color = colors[indexPath.item]
        cell.configure(color: color)
        cell.applySelectedAppearance(indexPath.item == selectedIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let isSelected = (indexPath.item == selectedIndex)
        if isSelected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        (cell as? ColorCell)?.applySelectedAppearance(isSelected)
    }
}

extension ColorCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previousIndex = selectedIndex
        selectedIndex = indexPath.item
        selectedColor = colors[indexPath.item]
        if let selectedColor {
            onSelectColor?(selectedColor)
        }
        if let previousIndex, previousIndex != indexPath.item {
            collectionView.deselectItem(at: IndexPath(item: previousIndex, section: 0), animated: false)
        }
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        var indicesToReload = [indexPath]
        if let previousIndex, previousIndex != indexPath.item {
            indicesToReload.append(IndexPath(item: previousIndex, section: 0))
        }
        reloadItems(at: indicesToReload)
    }
}

extension ColorCollectionView: UICollectionViewDelegateFlowLayout {
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
