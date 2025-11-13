import UIKit

final class CreateCategoryViewController: UIViewController {
    
    enum Mode {
        case create
        case edit(originalTitle: String)
    }

    private let mode: Mode
    
    var onDidCreate: ((String) -> Void)?
    var onDidRename: ((String, String) -> Void)?
    
    init(mode: Mode = .create) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private let nameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("enter_name_category", comment: "")
        textField.backgroundColor =  Colors.backgroundView
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
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 32, bottom: 19, trailing: 32)
        
        button.setTitle(NSLocalizedString("ready", comment: ""), for: .normal)
        button.setTitleColor(Colors.buttonTextColor, for: .normal)
        button.setTitleColor(.ypWhiteDay, for: .disabled)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.configuration = config
        button.backgroundColor = .ypGray
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor
        
        switch mode {
        case .create:
            navigationItem.title = NSLocalizedString("new_category", comment: "")
        case .edit(let originalTitle):
            navigationItem.title = NSLocalizedString("edit_category", comment: "")
            nameField.text = originalTitle
            createButton.isEnabled = true
            createButton.backgroundColor = Colors.buttonColor
        }
        
        nameField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)
        createButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        configureLayout()
    }
    
    private func configureLayout() {
        
        view.addSubviews([nameField, createButton])
        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 75),
            
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(lessThanOrEqualToConstant: 60)
        ])
    }
    
    @objc
    private func nameFieldChanged() {
        let nameIsEmpty = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        createButton.isEnabled = !nameIsEmpty
        createButton.backgroundColor = createButton.isEnabled ? Colors.buttonColor : .ypGray
    }
    
    @objc
    private func primaryTapped() {
        let newTitle = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !newTitle.isEmpty else { return }
        
        switch mode {
        case .create:
            onDidCreate?(newTitle)
            
        case .edit(let originalTitle):
            onDidRename?(originalTitle, newTitle)
        }
        
        dismiss(animated: true)
    }
    
}
