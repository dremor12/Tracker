import UIKit

protocol TrackerEditViewControllerDelegate: AnyObject {
    func trackerEditViewController(
        _ vc: TrackerEditViewController,
        didSave tracker: Tracker,
        toCategoryTitle categoryTitle: String
    )
}

final class TrackerEditViewController: UIViewController {
    weak var delegate: TrackerEditViewControllerDelegate?

    private let trackerCategoryStore: TrackerCategoryStore
    private let originalTracker: Tracker
    private let originalCategoryTitle: String
    private let completedCount: Int
    
    init(
        tracker: Tracker,
        categoryTitle: String,
        completedCount: Int,
        categoryStore: TrackerCategoryStore
    ) {
        self.originalTracker = tracker
        self.originalCategoryTitle = categoryTitle
        self.completedCount = completedCount
        self.trackerCategoryStore = categoryStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private let emojiItems: [String] = [
        "🙂","😻","🌺","🐶","❤️","😱",
        "😇","😡","🥶","🤔","🙌","🍔",
        "🥦","🏓","🥇","🎸","🏝","😪"
    ]
    
    private let colorItems: [UIColor] = [
        .colorSelection1,.colorSelection2,.colorSelection3,
        .colorSelection4,.colorSelection5,.colorSelection6,
        .colorSelection7,.colorSelection8,.colorSelection9,
        .colorSelection10,.colorSelection11,.colorSelection12,
        .colorSelection13,.colorSelection14,.colorSelection15,
        .colorSelection16,.colorSelection17,.colorSelection18
    ]

    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let daysLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = Colors.buttonColor
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let nameField: UITextField = {
        let f = UITextField()
        f.placeholder = NSLocalizedString("enter_name_tracker", comment: "")
        f.backgroundColor = Colors.backgroundView
        f.layer.cornerRadius = 16
        f.font = .systemFont(ofSize: 17, weight: .regular)
        f.translatesAutoresizingMaskIntoConstraints = false
        f.clearButtonMode = .whileEditing
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        let pad = UIView(frame: .init(x: 0, y: 0, width: 16, height: 0))
        f.leftView = pad
        f.leftViewMode = .always
        return f
    }()
    
    private let optionsContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.backgroundColor = Colors.backgroundView
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .ypGray
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }()
    
    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = Colors.buttonTextColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        c.contentInsets = .init(top: 19, leading: 32, bottom: 19, trailing: 32)
        b.configuration = c
        b.setTitle(NSLocalizedString("cancel_button", comment: ""), for: .normal)
        b.setTitleColor(.systemRed, for: .normal)
        b.backgroundColor = .clear
        b.layer.borderColor = UIColor.systemRed.cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        c.contentInsets = .init(top: 19, leading: 32, bottom: 19, trailing: 32)
        b.configuration = c
        b.setTitle(NSLocalizedString("save", comment: "Сохранить"), for: .normal)
        b.setTitleColor(Colors.buttonTextColor, for: .normal)
        b.setTitleColor(.ypWhiteDay, for: .disabled)
        b.backgroundColor = Colors.buttonColor
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let emojiLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("emoji", comment: "")
        l.font = .systemFont(ofSize: 19, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let emojiCollectionView: EmojiCollectionView = {
        let v = EmojiCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let colorLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("color", comment: "")
        l.font = .systemFont(ofSize: 19, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let colorCollectionView: ColorCollectionView = {
        let v = ColorCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let categoryButton = TrackerEditViewController.cellButton(title: NSLocalizedString("category", comment: ""))
    private let scheduleButton = TrackerEditViewController.cellButton(title: NSLocalizedString("shedule", comment: ""))
    
    private var selectedCategoryTitle: String?
    private var selectedDays: [WeekDay] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor
        navigationItem.title = NSLocalizedString("edit_habit_title", comment: "")
        
        configureLayout()
        configureBindings()
        fillInitialValues()
    }

    
    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([scrollView, bottomBar, cancelButton, saveButton])
        scrollView.addSubview(contentView)
        
        contentView.addSubviews([
            daysLabel, nameField,
            optionsContainer, emojiLabel,
            emojiCollectionView, colorLabel,
            colorCollectionView
        ])
        
        optionsContainer.addSubviews([categoryButton, separatorView, scheduleButton])
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            daysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            daysLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            nameField.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 40),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 75),
            
            optionsContainer.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 24),
            optionsContainer.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            optionsContainer.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            optionsContainer.heightAnchor.constraint(equalToConstant: 150),
            
            categoryButton.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            categoryButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            
            separatorView.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -16),
            
            scheduleButton.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            scheduleButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            scheduleButton.heightAnchor.constraint(equalTo: categoryButton.heightAnchor),
            scheduleButton.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor),
            
            emojiLabel.topAnchor.constraint(equalTo: optionsContainer.bottomAnchor, constant: 32),
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            emojiCollectionView.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            colorLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 16),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            colorCollectionView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -90),
            
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            cancelButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            cancelButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            cancelButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalToConstant: 166),
            
            saveButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            saveButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            saveButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -8),
            saveButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            saveButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])
    }
    
    private func configureBindings() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        nameField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)
        
        categoryButton.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
        
        emojiCollectionView.onSelectEmoji = { [weak self] _ in self?.updateSaveButtonState() }
        colorCollectionView.onSelectColor = { [weak self] _ in self?.updateSaveButtonState() }
    }
    
    private func fillInitialValues() {
        daysLabel.text = daysText(completedCount)
        nameField.text = originalTracker.title
        selectedCategoryTitle = originalCategoryTitle
        updateCategorySubtitle(with: originalCategoryTitle)
        selectedDays = originalTracker.schedule
        if Set(selectedDays) == Set(WeekDay.allCases) {
            updateScheduleSubtitle(with: NSLocalizedString("every_day", comment: ""))
        } else {
            let text = selectedDays
                .sorted { $0.order < $1.order }
                .map { $0.localizedShort }
                .joined(separator: ", ")
            updateScheduleSubtitle(with: text)
        }
        emojiCollectionView.emojis = emojiItems
        emojiCollectionView.select(emoji: originalTracker.emoji)

        colorCollectionView.colors = colorItems
        colorCollectionView.preselect(color: originalTracker.color)

        colorCollectionView.reloadData()
        emojiCollectionView.reloadData()
        
        updateSaveButtonState()
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    @objc private func saveTapped() {
        guard
            let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty,
            let emoji = emojiCollectionView.selectedEmoji,
            let color = colorCollectionView.selectedColor,
            !selectedDays.isEmpty
        else { return }
        
        let updated = Tracker(
            id: originalTracker.id,
            title: title,
            color: color,
            emoji: emoji,
            schedule: selectedDays
        )
        
        let categoryTitle = selectedCategoryTitle ?? originalCategoryTitle
        delegate?.trackerEditViewController(self, didSave: updated, toCategoryTitle: categoryTitle)
        dismiss(animated: true)
    }
    
    @objc private func nameFieldChanged() { updateSaveButtonState() }
    
    @objc private func categoryTapped() {
        let vm = CategoryViewModel(store: trackerCategoryStore)
        let vc = CategoryViewController(viewModel: vm)
        vc.onCategorySelected = { [weak self] title in
            self?.selectedCategoryTitle = title
            self?.updateCategorySubtitle(with: title)
            self?.updateSaveButtonState()
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func scheduleTapped() {
        let vc = ScheduleViewController(initialSelectedDays: selectedDays)
        vc.onDaysChanged = { [weak self] days in
            guard let self else { return }
            self.selectedDays = days
            self.updateSaveButtonState()
            
            if days.isEmpty {
                self.updateScheduleSubtitle(with: nil)
            } else if Set(days) == Set(WeekDay.allCases) {
                self.updateScheduleSubtitle(with: NSLocalizedString("every_day", comment: ""))
            } else {
                let text = days.sorted { $0.order < $1.order }
                    .map { $0.localizedShort }
                    .joined(separator: ", ")
                self.updateScheduleSubtitle(with: text)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func updateSaveButtonState() {
        let nameIsEmpty = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let hasSchedule = !selectedDays.isEmpty
        let hasEmoji = emojiCollectionView.selectedEmoji != nil
        let hasColor = colorCollectionView.selectedColor != nil
        let enabled = !nameIsEmpty && hasSchedule && hasEmoji && hasColor
        saveButton.isEnabled = enabled
        saveButton.backgroundColor = enabled ? Colors.buttonColor : .ypGray
    }
    
    private func updateCategorySubtitle(with text: String?) {
        let title = "\(NSLocalizedString("category", comment: ""))\n\(text ?? "")"
        let attr = NSMutableAttributedString(string: title)
        if let r = title.range(of: NSLocalizedString("category", comment: "")) {
            attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 17, weight: .regular), range: NSRange(r, in: title))
        }
        let sub = (title as NSString).range(of: text ?? "")
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: sub)
        attr.addAttribute(.foregroundColor, value: UIColor.ypGray, range: sub)
        categoryButton.setAttributedTitle(attr, for: .normal)
    }
    
    private func updateScheduleSubtitle(with text: String?) {
        let title = NSLocalizedString("shedule", comment: "")
        guard let text, !text.isEmpty else {
            scheduleButton.setAttributedTitle(nil, for: .normal)
            scheduleButton.setTitle(title, for: .normal)
            scheduleButton.titleLabel?.numberOfLines = 1
            return
        }
        let full = "\(title)\n\(text)"
        let attr = NSMutableAttributedString(string: full)
        if let r = full.range(of: title) {
            let ns = NSRange(r, in: full)
            attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 17, weight: .regular), range: ns)
            attr.addAttribute(.foregroundColor, value: Colors.buttonColor, range: ns)
        }
        let sub = (full as NSString).range(of: text)
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: sub)
        attr.addAttribute(.foregroundColor, value: UIColor.ypGray, range: sub)
        scheduleButton.setAttributedTitle(attr, for: .normal)
        scheduleButton.titleLabel?.numberOfLines = 2
    }
    
    private func daysText(_ count: Int) -> String {
        let format = NSLocalizedString("days_count", comment: "Plural form for days")
        return String.localizedStringWithFormat(format, count)
    }
    
    private static func cellButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        b.contentHorizontalAlignment = .left
        c.baseForegroundColor = Colors.buttonColor
        c.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        b.configuration = c
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.numberOfLines = 2
        b.titleLabel?.lineBreakMode = .byTruncatingTail
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .ypGray
        chevron.translatesAutoresizingMaskIntoConstraints = false
        b.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: b.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: -16)
        ])
        return b
    }
}

extension UIColor {
    func equalsTo(_ other: UIColor, tolerance: CGFloat = 0.01) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        let c1 = self.resolvedColor(with: .current)
        let c2 = other.resolvedColor(with: .current)
        
        guard c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return false }
        
        return abs(r1 - r2) < tolerance &&
        abs(g1 - g2) < tolerance &&
        abs(b1 - b2) < tolerance &&
        abs(a1 - a2) < tolerance
    }
}
