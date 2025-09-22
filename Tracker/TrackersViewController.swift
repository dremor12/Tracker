import UIKit

final class TrackersViewController: UIViewController, CreateTrackerDelegate {
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 160, height: 90)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TrackerCell.self,
            forCellWithReuseIdentifier: TrackerCell.reuseIdentifier
        )
        collectionView.register(
            CategoryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CategoryHeaderView.reuseIdentifier
        )
        return collectionView
    }()
    
    private var categories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    private var visibleCategories: [TrackerCategory] = []
    private var selectedDate: Date = Date()
    private let datePicker = UIDatePicker()
    private let emptyStateImage = UIImageView(image: UIImage(resource: .mokoStar))
    private let searchController = UISearchController(searchResultsController: nil)

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        definesPresentationContext = true
        
        configureNavigationBar()
        configureSearchController()
        configureLayout()
        updateVisibleCategoriesAndUI()
    }
    
    func didCreateTracker(_ tracker: Tracker) {
        addTracker(tracker, to: "Без категории")
        updateVisibleCategoriesAndUI()
        scrollListToTopIfNeeded()
    }
    
    private func configureSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        searchController.searchBar.searchTextField.font = .systemFont(ofSize: 17, weight: .regular)
        searchController.searchBar.layer.cornerRadius = 10
        
        searchController.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureNavigationBar() {
        let addButton = UIButton(type: .system)
        var plusConfig = UIButton.Configuration.plain()
        plusConfig.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))
        plusConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        addButton.configuration = plusConfig
        addButton.tintColor = .ypBlackDay
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .ypBlackDay
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.date = selectedDate
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }

    private func configureLayout() {
        emptyStateImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([collectionView, emptyStateImage, emptyStateLabel])
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -32),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImage.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func scrollListToTopIfNeeded() {
        let top = -collectionView.adjustedContentInset.top
        if collectionView.contentOffset.y > top {
            collectionView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
        }
    }
    
    @objc
    private func addButtonTapped() {
        let createVC = CreateTrackerViewController()
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    
    @objc
    private func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        updateVisibleCategoriesAndUI()
    }
    
    private func updateVisibleCategoriesAndUI() {
        visibleCategories = filterVisibleCategories(for: selectedDate)
        collectionView.reloadData()
        updateEmptyState()
        scrollListToTopIfNeeded()
    }
    
    private func addTracker(_ tracker: Tracker, to categoryTitle: String) {
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
    
    private func toggleTrackerCompletion(_ tracker: Tracker) {
        let record = TrackerRecord(trackerId: tracker.id, date: selectedDate)
        if completedTrackers.contains(record) {
            completedTrackers.remove(record)
        } else {
            completedTrackers.insert(record)
        }
    }

    
    private func updateEmptyState() {
        let hasVisibleTrackers = !visibleCategories.isEmpty
        emptyStateImage.isHidden = hasVisibleTrackers
        emptyStateLabel.isHidden = hasVisibleTrackers
    }
    
    private func filterVisibleCategories(for date: Date) -> [TrackerCategory] {
        let weekdayInt = Calendar.current.component(.weekday, from: date)
        guard let selectedWeekday = WeekDay.from(calendarWeekday: weekdayInt) else { return [] }
        return categories.compactMap { category in
            let trackersForDay = category.trackers.filter { $0.schedule.contains(selectedWeekday) }
            guard !trackersForDay.isEmpty else { return nil }
            return TrackerCategory(title: category.title, trackers: trackersForDay)
        }
    }
}

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
    }
}


extension TrackersViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        let top = -collectionView.adjustedContentInset.top
        if collectionView.contentOffset.y > top {
            collectionView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        let scrollToTop = { [weak self] in
            guard let self = self else { return }
            let top = -self.collectionView.adjustedContentInset.top
            self.collectionView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
            self.navigationController?.navigationBar.setNeedsLayout()
            self.navigationController?.navigationBar.layoutIfNeeded()
        }
        
        if let coordinator = navigationController?.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                scrollToTop()
            }, completion: { _ in
                scrollToTop()
            })
        } else {
            DispatchQueue.main.async { scrollToTop() }
        }
    }
}

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrackerCell.reuseIdentifier,
                for: indexPath
            ) as? TrackerCell
        else { return UICollectionViewCell() }

        let tracker   = visibleCategories[indexPath.section].trackers[indexPath.item]
        let todayRecord  = TrackerRecord(trackerId: tracker.id, date: selectedDate)
        let isCompleted    = completedTrackers.contains(todayRecord)
        let completedCount = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure(with: tracker, isCompleted: isCompleted, count: completedCount)
        
        cell.onToggle = { [weak self] in
            guard let self else { return }
            let record = TrackerRecord(trackerId: tracker.id, date: self.selectedDate)
            if Calendar.current.compare(
                self.selectedDate,
                to: Date(),
                toGranularity: .day
            ) == .orderedDescending { return }

            if self.completedTrackers.contains(record) {
                self.completedTrackers.remove(record)
            } else {
                self.completedTrackers.insert(record)
            }
            self.updateVisibleCategoriesAndUI()
        }
        return cell
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = 16
        let interItemSpacing: CGFloat = 8
        let availableWidth = collectionView.bounds.width - inset * 2 - interItemSpacing
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 148)
    }

    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CategoryHeaderView.reuseIdentifier,
                for: indexPath
              ) as? CategoryHeaderView
        else { return UICollectionReusableView() }
        
        let category = visibleCategories[indexPath.section]
        header.configure(with: category.title)
        return header
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 32)
    }
}
