import UIKit

final class TrackersViewController: UIViewController {
    
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var selectedDate: Date = Date()

    private let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.translatesAutoresizingMaskIntoConstraints = false
        search.placeholder = "Поиск"
        search.searchTextField.font = .systemFont(ofSize: 17, weight: .regular)
        search.searchBarStyle = .minimal
        return search
    }()
    
    private let emptyStateImage = UIImageView(image: UIImage(named: "moko_star"))
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let shortData: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yy"
        return df
    }()
    
    private let labelMain: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        configureLayout()
    }
    
    
    private func configureNavigationBar() {
        
        let configAddButton = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: configAddButton), for: .normal)
        addButton.tintColor = .black
        addButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 12)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)
        
        let dateButton = UIButton(type: .system)
        dateButton.setTitle(shortData.string(from: Date()), for: .normal)
        dateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        dateButton.backgroundColor = .systemGray6
        dateButton.layer.cornerRadius = 8
        dateButton.tintColor = .black
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        dateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: dateButton)
    }
    
    
    private func configureLayout() {
        
        emptyStateImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([searchBar, labelMain, emptyStateImage, emptyStateLabel])
        
        NSLayoutConstraint.activate([
            labelMain.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            labelMain.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            labelMain.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: labelMain.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            
            emptyStateImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -32),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImage.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    
    @objc private func addButtonTapped() {
        print("Add tapped")
    }
    
    @objc private func dateButtonTapped() {
        print("Date tapped")
    }
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        if let i = categories.firstIndex(where: { $0.title == categoryTitle }) {
            var updated = categories[i]
            updated = TrackerCategory(title: updated.title, trackers: updated.trackers + [tracker])
            var newCategories = categories
            newCategories[i] = updated
            categories = newCategories
        } else {
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            categories = categories + [newCategory]
        }
    }
    
    func toggleTrackerCompletion(_ tracker: Tracker) {
        if let i = completedTrackers.firstIndex(where: {
            $0.trackerID == tracker.id &&
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }) {
            var updated = completedTrackers
            updated.remove(at: i)
            completedTrackers = updated
        } else {
            let record = TrackerRecord(trackerID: tracker.id,  date: selectedDate)
            completedTrackers = completedTrackers + [record]
        }
    }
}

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
    }
}
