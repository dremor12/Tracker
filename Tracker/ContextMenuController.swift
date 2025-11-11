import UIKit

enum ContextMenuMode {
    case category
    case tracker
}

final class ContextMenuController: UIViewController {
    
    private let mode: ContextMenuMode
    private let titleText: String
    private let anchorFrameInWindow: CGRect
    private let previewView: UIView?

    var onTogglePin: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onDismissed: (() -> Void)?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let titleBubble = UIView()
    private let titleLabel = UILabel()
    private let menuCard = UIView()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let separatorView = UIView()
    private let stack = UIStackView()
    
    init(title: String, mode: ContextMenuMode, anchorFrameInWindow: CGRect, previewView: UIView? = nil) {
        self.titleText = title
        self.mode = mode
        self.anchorFrameInWindow = anchorFrameInWindow
        self.previewView = previewView
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
        
        titleBubble.backgroundColor = Colors.backgroundView
        titleBubble.layer.cornerRadius = 16
        titleBubble.clipsToBounds = true
        
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = Colors.buttonColor

        menuCard.backgroundColor = Colors.backgroundView
        menuCard.layer.cornerRadius = 13
        menuCard.clipsToBounds = true
        
        if mode == .tracker, let preview = previewView {
            preview.layer.cornerRadius = 16
            preview.layer.masksToBounds = true
            titleBubble.isHidden = true
            view.addSubview(preview)
        } else {
            view.addSubview(titleBubble)
            titleBubble.addSubview(titleLabel)
        }

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
        
        func makeButton(title: String, color: UIColor = Colors.buttonColor, action: Selector) -> UIButton {
            let b = UIButton(type: .system)
            b.configuration = config
            b.setTitle(title, for: .normal)
            b.setTitleColor(color, for: .normal)
            b.contentHorizontalAlignment = .leading
            b.titleLabel?.font = .systemFont(ofSize: 17)
            b.addTarget(self, action: action, for: .touchUpInside)
            return b
        }
        
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 0
        
        
        let edit = makeButton(title: NSLocalizedString("edit_tracker", comment: ""), action: #selector(handleEdit))
        let delete = makeButton(title: NSLocalizedString("delete_button", comment: ""), color: .ypRed, action: #selector(handleDelete))
        stack.addArrangedSubview(edit)
        stack.addSeparator()
        stack.addArrangedSubview(delete)
        
        
        view.addSubview(titleBubble)
        titleBubble.addSubview(titleLabel)
        view.addSubview(menuCard)
        menuCard.addSubview(stack)
    }
    
    private func layoutUI() {
        titleBubble.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        menuCard.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        let converted = view.convert(anchorFrameInWindow, from: nil)
        
        if let preview = previewView, mode == .tracker {
            preview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                preview.topAnchor.constraint(equalTo: view.topAnchor, constant: converted.minY),
                preview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: converted.minX),
                preview.widthAnchor.constraint(equalToConstant: converted.width),
                preview.heightAnchor.constraint(equalToConstant: converted.height),
            ])
        } else {
            NSLayoutConstraint.activate([
                titleBubble.topAnchor.constraint(equalTo: view.topAnchor, constant: converted.minY),
                titleBubble.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: converted.minX),
                titleBubble.widthAnchor.constraint(equalToConstant: converted.width),
                titleBubble.heightAnchor.constraint(equalToConstant: 75),
                titleLabel.leadingAnchor.constraint(equalTo: titleBubble.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: titleBubble.trailingAnchor, constant: -16),
                titleLabel.centerYAnchor.constraint(equalTo: titleBubble.centerYAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            menuCard.topAnchor.constraint(equalTo: (mode == .tracker ? (previewView ?? titleBubble).bottomAnchor : titleBubble.bottomAnchor), constant: 8),
            menuCard.leadingAnchor.constraint(equalTo: (mode == .tracker ? view.leadingAnchor : titleBubble.leadingAnchor),
                                                  constant: (mode == .tracker ? converted.minX : 0)),
            menuCard.widthAnchor.constraint(equalToConstant: 250),
            
            stack.topAnchor.constraint(equalTo: menuCard.topAnchor),
            stack.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: menuCard.bottomAnchor),
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
