import UIKit

protocol FiltersViewControllerDelegate: AnyObject {
    func filtersViewController(_ vc: FiltersViewController, didSelect filter: TrackerFilter)
}

final class FiltersViewController: UIViewController {
    weak var delegate: FiltersViewControllerDelegate?
    var preselected: TrackerFilter = .all

    private let items: [TrackerFilter] = [.all, .today, .completed, .uncompleted]
    private var containerHeightConstraint: NSLayoutConstraint!
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 75
        return tableView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.backgroundView
        view.layer.cornerRadius = 16
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor
    
        title = NSLocalizedString("filters", comment: "")
        tableView.register(FiltersCell.self, forCellReuseIdentifier: FiltersCell.reuseIdentifier)
        tableView.isScrollEnabled = false
        
        tableView.dataSource  = self
        tableView.delegate = self
        
        configureLayout()
        updateContainerHeight()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContainerHeight()
    }

    private func updateContainerHeight() {
        let contentHeight = CGFloat(items.count) * tableView.rowHeight
        containerHeightConstraint.constant = contentHeight

        let verticalMargins: CGFloat = 24 + view.safeAreaInsets.top + view.safeAreaInsets.bottom
        preferredContentSize = CGSize(width: view.bounds.width, height: contentHeight + verticalMargins)
    }
    
    private func configureLayout() {
        view.addSubviews([containerView])
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
        ])
    }
    
    private func title(for filter: TrackerFilter) -> String {
        switch filter {
        case .all: return NSLocalizedString("all_trackers", comment: "Все трекеры")
        case .today: return NSLocalizedString("today_trackers", comment: "Трекеры на сегодня")
        case .completed: return NSLocalizedString("completed", comment: "Завершённые")
        case .uncompleted: return NSLocalizedString("uncompleted", comment: "Незавершённые")
        }
    }
}

extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FiltersCell.reuseIdentifier,
            for: indexPath
        ) as? FiltersCell else { return UITableViewCell() }
        
        let item = items[indexPath.row]
        let isChecked = (item == .completed || item == .uncompleted) && item == preselected
        let showsSeparator = indexPath.row != items.count - 1
        cell.configure(title: title(for: item), isChecked: isChecked, showsSeparator: showsSeparator)
        return cell
    }
}

extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = items[indexPath.row]
        delegate?.filtersViewController(self, didSelect: selected)
        dismiss(animated: true)
    }
}
