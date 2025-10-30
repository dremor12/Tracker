import UIKit

final class CategoryViewController: UIViewController {
    
    var onCategorySelected: ((String) -> Void)?
    
    private let viewModel: CategoryViewModel
    
    init(viewModel: CategoryViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var containerHeightConstraint: NSLayoutConstraint!
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 75
        return tableView
    }()
    
    private let emptyStateImage = UIImageView(image: UIImage(resource: .mokoStar))
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        config.title = "Добавить категорию"
        config.baseBackgroundColor = .ypBlackDay
        config.baseForegroundColor = .ypWhiteDay
        config.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 32, bottom: 19, trailing: 32)
        config.background.cornerRadius = 16
        
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ypBackgroundDay
        view.layer.cornerRadius = 16
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhiteDay
        
        title = "Категория"
        
        configureLayout()
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.delaysContentTouches = false
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(longPress)
        
        bindViewModel()
        viewModel.start()
        updateContainerAndEmptyState()
    }
    
    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        let point = recognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        let title = viewModel.title(at: indexPath.row)

        let cellRect = tableView.rectForRow(at: indexPath)
        let cellRectInTable = tableView.convert(cellRect, to: view)
        let cellRectInWindow = view.convert(cellRectInTable, to: nil)

        let menu = CategoryContextMenuController(categoryTitle: title, anchorFrameInWindow: cellRectInWindow)

        menu.onEdit = { [weak self] in
            guard let self else { return }
            let vc = CreateCategoryViewController(mode: .edit(originalTitle: title))
            vc.onDidRename = { [weak self] oldTitle, newTitle in
                self?.viewModel.renameCategory(originalTitle: oldTitle, to: newTitle)
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            self.present(nav, animated: true)
        }

        menu.onDelete = { [weak self] in
            guard let self else { return }
            self.presentDeleteConfirmation(for: title,
                                           sourceRect: tableView.rectForRow(at: indexPath),
                                           in: tableView)
        }

        present(menu, animated: false)
    }

    
    private func configureLayout() {
        emptyStateImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([containerView, emptyStateImage, emptyStateLabel, createButton])
        containerView.addSubview(tableView)
        
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        containerHeightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            emptyStateImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -32),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImage.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(lessThanOrEqualToConstant: 60)
        ])
    }
    
    
    private func bindViewModel() {
        viewModel.onDataChanged = { [weak self] in
            guard let self else { return }
            self.updateContainerAndEmptyState()
            self.tableView.reloadData()
        }
        viewModel.onSelectionChanged = { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    private func updateContainerAndEmptyState() {
        let isEmpty = viewModel.rowsCount() == 0
        emptyStateImage.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        containerView.isHidden = isEmpty
        tableView.isHidden = isEmpty
        
        let rowsToShow = min(viewModel.rowsCount(), 6)
        containerHeightConstraint.constant = CGFloat(rowsToShow) * 75
        tableView.isScrollEnabled = viewModel.rowsCount() > 6
        view.layoutIfNeeded()
    }
    
    @objc
    private func createButtonTapped() {
        let createVC = CreateCategoryViewController()
        createVC.onDidCreate = { [weak self] title in
            self?.viewModel.createCategory(title: title)
        }
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    private func presentDeleteConfirmation(for title: String, sourceRect: CGRect, in sourceView: UIView) {
        let alert = UIAlertController(title: nil,
                                      message: "Эта категория точно не нужна?",
                                      preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(title: title)
        }
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowsCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as! CategoryCell

        let title = viewModel.title(at: indexPath.row)
        let isChecked = viewModel.isChecked(at: indexPath)
        let isLast = indexPath.row == viewModel.rowsCount() - 1
        cell.configure(title: title, isChecked: isChecked, showsSeparator: !isLast)
        return cell
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.select(at: indexPath)
        onCategorySelected?(viewModel.title(at: indexPath.row))
        dismiss(animated: true)
    }
}
