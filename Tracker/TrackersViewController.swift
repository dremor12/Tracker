import UIKit

final class TrackersViewController: UIViewController, CreateTrackerDelegate {

    private let trackerStore: TrackerStore
    private let trackerCategoryStore: TrackerCategoryStore
    private let trackerRecordStore: TrackerRecordStore
    
    init(trackerStore: TrackerStore,
         categoryStore: TrackerCategoryStore,
         recordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.trackerCategoryStore = categoryStore
        self.trackerRecordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 9
        layout.itemSize = CGSize(width: 167, height: 90)

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


    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Трекеры"
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let searchField: UISearchTextField = {
        let f = UISearchTextField()
        f.placeholder = "Поиск"
        f.font = .systemFont(ofSize: 17, weight: .regular)
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        definesPresentationContext = true
        
        trackerStore.delegate = self
        trackerCategoryStore.delegate = self
        trackerRecordStore.delegate = self
        
        trackerStore.startObserving()
        trackerCategoryStore.startObserving()
        trackerRecordStore.startObserving()

        configureNavigationBar()
        configureStaticHeaderAndSearch()
        configureLayout()
    
        categories = (try? trackerCategoryStore.fetchAll()) ?? []
        completedTrackers = Set((try? trackerRecordStore.fetchAll()) ?? [])
        updateVisibleCategoriesAndUI()
    }
    
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        try? trackerStore.create(tracker, in: categoryTitle)
    }
    
    private func configureStaticHeaderAndSearch() {
        view.addSubviews([headerLabel, searchField])

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            searchField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 7),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 36)
        ])
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
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
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
        let createVC = CreateTrackerViewController(categoryStore: trackerCategoryStore)
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
        let startOfSelectedDay = Calendar.current.startOfDay(for: selectedDate)
        let todayRecord = TrackerRecord(trackerId: tracker.id, date: startOfSelectedDay)
        let isCompleted = completedTrackers.contains(todayRecord)
        let completedCount = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure(with: tracker, isCompleted: isCompleted, count: completedCount)
        
        cell.onToggle = { [weak self] in
            guard let self else { return }
            guard
                Calendar.current.compare(
                    self.selectedDate, to: Date(),
                    toGranularity: .day
                ) != .orderedDescending
            else { return }
            
            let day = Calendar.current.startOfDay(for: self.selectedDate)
            let record = TrackerRecord(trackerId: tracker.id, date: day)
    
            if self.completedTrackers.contains(record) {
                try? self.trackerRecordStore.delete(record)
            } else {
                try? self.trackerRecordStore.add(record)
            }
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
        guard let flow = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 167, height: 148)
        }
        let columns: CGFloat = 2
        let totalSpacing = flow.minimumInteritemSpacing * (columns - 1)
        let sectionInsets = flow.sectionInset.left + flow.sectionInset.right
        let availableWidth = collectionView.bounds.width - totalSpacing - sectionInsets
        let width = floor(availableWidth / columns)
        return CGSize(width: width, height: 148)
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

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreDidChange(_ store: TrackerStore) {
        categories = (try? trackerCategoryStore.fetchAll()) ?? []
        completedTrackers = Set((try? trackerRecordStore.fetchAll()) ?? [])
        updateVisibleCategoriesAndUI()
    }
}


extension TrackersViewController: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidChange(_ store: TrackerCategoryStore) {
        categories = (try? store.fetchAll()) ?? []
        updateVisibleCategoriesAndUI()
    }
}


extension TrackersViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore) {
        completedTrackers = Set((try? store.fetchAll()) ?? [])
        updateVisibleCategoriesAndUI()
    }
}
