import UIKit

protocol CreateTrackerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker)
}

final class CreateTrackerViewController: UIViewController {
    
    weak var delegate: CreateTrackerDelegate?
    
    private let emojiItems: [String] = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]

    private let colorItems: [UIColor] = [
        .colorSelection1, .colorSelection2, .colorSelection3,
        .colorSelection4, .colorSelection5, .colorSelection6,
        .colorSelection7, .colorSelection8, .colorSelection9,
        .colorSelection10, .colorSelection11, .colorSelection12,
        .colorSelection13, .colorSelection14, .colorSelection15,
        .colorSelection16, .colorSelection17, .colorSelection18
    ]

    private let nameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = .ypBackgroundDay
        textField.layer.cornerRadius = 16
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = padding
        textField.leftViewMode = .always
        return textField
    }()

    private let separate: UIView = {
        let view = UIView()
        view.backgroundColor = .ypGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return view
    }()

    private let optionsContainer: UIView = {
        let container = UIView()
        container.layer.cornerRadius = 16
        container.backgroundColor = .ypBackgroundDay
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let bottomBar: UIView = {
        let bottomBar = UIView()
        bottomBar.backgroundColor = .ypWhiteDay
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        return bottomBar
    }()

    private let emojiLabel: UILabel = {
        let emojiLabel = UILabel()
        emojiLabel.text = "Emoji"
        emojiLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        return emojiLabel
    }()
    
    private let emojiCollectionView: EmojiCollectionView = {
        let emojiCollectionView = EmojiCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        emojiCollectionView.translatesAutoresizingMaskIntoConstraints = false
        return emojiCollectionView
    }()
    
    private let colorLabel: UILabel = {
        let colorLabel = UILabel()
        colorLabel.text = "Цвет"
        colorLabel.font = .systemFont(ofSize: 19, weight: .bold)
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        return colorLabel
    }()
    
    private let colorCollectionView: ColorCollectionView = {
        let colorCollectionView = ColorCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        colorCollectionView.translatesAutoresizingMaskIntoConstraints = false
        return colorCollectionView
    }()

    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private let categoryButton = cellButton(title: "Категория")
    private let scheduleButton = cellButton(title: "Расписание")
    private var selectedDays: [WeekDay] = []
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhiteDay
        navigationItem.title = "Новая привычка"
        
        nameField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)

        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.layer.borderColor = UIColor.systemRed.cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.cornerRadius = 12
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        createButton.setTitle("Создать", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .ypGray
        createButton.layer.cornerRadius = 12
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.isEnabled = false

        scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
        
        settingsLayout()

        emojiCollectionView.emojis = emojiItems
        emojiCollectionView.onSelectEmoji = { [weak self] _ in
            self?.updateCreateButtonState()
        }
        
        colorCollectionView.colors = colorItems
        colorCollectionView.onSelectColor = { [weak self] _ in
            self?.updateCreateButtonState()
        }
        
    }
    
    private func settingsLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([scrollView, bottomBar])
        view.addSubviews([createButton, cancelButton])
        scrollView.addSubview(contentView)
        contentView.addSubviews([
            nameField, optionsContainer,
            emojiLabel, emojiCollectionView,
            colorLabel, colorCollectionView
        ])
        optionsContainer.addSubviews([categoryButton, separate, scheduleButton])
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            nameField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
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
            
            separate.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separate.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 16),
            separate.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -16),
            
            scheduleButton.topAnchor.constraint(equalTo: separate.bottomAnchor),
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
            
            createButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            createButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            createButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -8),
            createButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),

            
        ])
    }
    
    private static func cellButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        config.baseForegroundColor = .ypBlackDay
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .ypGray
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])
        return button
    }
    
    private func updateScheduleSubtitle(with text: String?) {
        let title = "Расписание\n\(text ?? "")"
        let attribute = NSMutableAttributedString(string: title)
        if let range = title.range(of: "Расписание") {
            let ns = NSRange(range, in: title)
            attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 17, weight: .regular), range: ns)
        }
        let subtitleRange = (title as NSString).range(of: text ?? "")
        attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: subtitleRange)
        attribute.addAttribute(.foregroundColor, value: UIColor.ypGray, range: subtitleRange)
        scheduleButton.setAttributedTitle(attribute, for: .normal)
    }

    func updateCreateButtonState() {
        let nameIsEmpty = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let hasSchedule = !selectedDays.isEmpty
        let hasEmoji = (emojiCollectionView.selectedEmoji != nil)
        let hasColor = (colorCollectionView.selectedColor != nil)
        createButton.isEnabled = !nameIsEmpty && hasSchedule && hasEmoji && hasColor
        createButton.backgroundColor = createButton.isEnabled ? .ypBlackDay : .ypGray
    }
    
    @objc
    private func nameFieldChanged() {
        updateCreateButtonState()
    }

    @objc
    private func scheduleTapped() {
        let scheduleVC = ScheduleViewController()
        scheduleVC.onDaysChanged = { [weak self] days in
            guard let self else { return }
            self.selectedDays = days
            self.updateCreateButtonState()
            let subtitle: String
            if Set(days) == Set(WeekDay.allCases) {
                subtitle = "Каждый день"
            } else {
                subtitle = days
                    .sorted { $0.order < $1.order }
                    .map { $0.shortName }
                    .joined(separator: ", ")
            }
            self.updateScheduleSubtitle(with: subtitle)
        }
        present(scheduleVC, animated: true)
    }

    @objc
    private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc
    private func createTapped() {
        guard
            let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !title.isEmpty,
            let emoji = emojiCollectionView.selectedEmoji,
            let color = colorCollectionView.selectedColor,
            !selectedDays.isEmpty
        else { return }

        let tracker = Tracker(
            id: UUID(),
            title: title,
            color: color,
            emoji: emoji,
            schedule: selectedDays
        )
        
        delegate?.didCreateTracker(tracker)
        dismiss(animated: true)
        updateScheduleSubtitle(with: nil)
    }
}
