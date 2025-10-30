import UIKit

final class CategoryContextMenuController: UIViewController {

    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onDismissed: (() -> Void)?

    private let categoryTitle: String
    private let anchorFrameInWindow: CGRect

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let titleBubble = UIView()
    private let titleLabel = UILabel()
    private let menuCard = UIView()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let separatorView = UIView()

    init(categoryTitle: String, anchorFrameInWindow: CGRect) {
        self.categoryTitle = categoryTitle
        self.anchorFrameInWindow = anchorFrameInWindow
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        layoutUI()
        addDismissGesture()
    }

    private func configureUI() {
        view.backgroundColor = .clear

        blurView.alpha = 0
        view.addSubview(blurView)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        titleBubble.backgroundColor = .ypBackgroundDay
        titleBubble.layer.cornerRadius = 16
        titleBubble.clipsToBounds = true

        titleLabel.text = categoryTitle
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .ypBlackDay
        
        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.1)

        menuCard.backgroundColor = .ypBackgroundDay
        menuCard.layer.cornerRadius = 13
        menuCard.clipsToBounds = true
        
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)

        editButton.setTitle("Редактировать", for: .normal)
        editButton.contentHorizontalAlignment = .leading
        editButton.setTitleColor(.ypBlackDay, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 17)
        editButton.configuration = config
        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)

        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.setTitleColor(.ypRed, for: .normal)
        deleteButton.contentHorizontalAlignment = .leading
        deleteButton.titleLabel?.font = .systemFont(ofSize: 17)
        deleteButton.configuration = config
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)

        view.addSubview(titleBubble)
        titleBubble.addSubview(titleLabel)
        view.addSubview(menuCard)
        menuCard.addSubviews([editButton, separatorView, deleteButton])
    }

    private func layoutUI() {
        titleBubble.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        menuCard.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        let converted = view.convert(anchorFrameInWindow, from: nil)

        NSLayoutConstraint.activate([
            titleBubble.topAnchor.constraint(equalTo: view.topAnchor, constant: converted.minY),
            titleBubble.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: converted.minX),
            titleBubble.widthAnchor.constraint(equalToConstant: converted.width),
            titleBubble.heightAnchor.constraint(equalToConstant: 75),

            titleLabel.leadingAnchor.constraint(equalTo: titleBubble.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: titleBubble.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: titleBubble.centerYAnchor),

            menuCard.topAnchor.constraint(equalTo: titleBubble.bottomAnchor, constant: 8),
            menuCard.leadingAnchor.constraint(equalTo: titleBubble.leadingAnchor),
            menuCard.trailingAnchor.constraint(equalTo: titleBubble.trailingAnchor, constant: -109),
            menuCard.widthAnchor.constraint(lessThanOrEqualToConstant: 250),

            editButton.topAnchor.constraint(equalTo: menuCard.topAnchor),
            editButton.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
            editButton.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
            
            separatorView.topAnchor.constraint(equalTo: editButton.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            deleteButton.topAnchor.constraint(equalTo: editButton.bottomAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: menuCard.bottomAnchor),
        ])
    }

    private func addDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    private func animateIn() {
        titleBubble.alpha = 0
        menuCard.alpha = 0
        titleBubble.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        menuCard.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.2) {
            self.blurView.alpha = 1
            self.titleBubble.alpha = 1
            self.menuCard.alpha = 1
            self.titleBubble.transform = .identity
            self.menuCard.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, animations: {
            self.blurView.alpha = 0
            self.titleBubble.alpha = 0
            self.menuCard.alpha = 0
        }, completion: { _ in completion() })
    }

    @objc private func handleBackgroundTap() {
        animateOut { [weak self] in
            self?.dismiss(animated: false) { self?.onDismissed?() }
        }
    }

    @objc private func handleEdit() {
        animateOut { [weak self] in
            guard let self else { return }
            self.dismiss(animated: false) { self.onEdit?() }
        }
    }

    @objc private func handleDelete() {
        animateOut { [weak self] in
            guard let self else { return }
            self.dismiss(animated: false) { self.onDelete?() }
        }
    }
}
