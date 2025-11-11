import UIKit

final class TrackersViewController: UIViewController, CreateTrackerDelegate {
    
    private enum Defaults {
        static let filterKey = "trackerCurrentFilter"
    }
    
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
    private let emptyStateImage = UIImageView(image: UIImage(resource: .mokoStar))
    private var searchQuery: String = ""
    private let analytics = AnalyticsService()
    
    private var currentFilter: TrackerFilter = {
        if let raw = UserDefaults.standard.string(forKey: Defaults.filterKey),
           let saved = TrackerFilter(rawValue: raw) {
            return saved
        }
        return .all
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("what_to_track", comment: "")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = Colors.buttonColor
        return label
    }()
    
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("trackers", comment: "")
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let searchField: UISearchTextField = {
        let f = UISearchTextField()
        f.placeholder = NSLocalizedString("search", comment: "")
        f.font = .systemFont(ofSize: 17, weight: .regular)
        f.translatesAutoresizingMaskIntoConstraints = false
        f.clearButtonMode = .whileEditing
        return f
    }()
    
    private lazy var filterButton: UIButton = {
        let b = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        config.baseBackgroundColor = .ypBlue
        config.baseForegroundColor = .ypWhiteDay
        config.title = NSLocalizedString("filters", comment: "Фильтры")
        config.background.cornerRadius = 16
        b.configuration = config
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("cancel_button", comment: ""), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(cancelSearchTapped), for: .touchUpInside)
        b.isHidden = true
        return b
    }()
    
    private var searchTrailingToSuperview: NSLayoutConstraint!
    private var searchTrailingToCancel: NSLayoutConstraint!
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yy"
        df.locale = .current
        return df
    }()

    private lazy var datePillButton: UIButton = {
        let b = UIButton(type: .system)

        var cfg = UIButton.Configuration.filled()
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cfg.baseBackgroundColor = UIColor(resource: .ypLightGray)
        cfg.baseForegroundColor = .ypBlackDay
        cfg.background.cornerRadius = 8

        var title = AttributedString(dateFormatter.string(from: selectedDate))
        title.font = .systemFont(ofSize: 17, weight: .regular)
        cfg.attributedTitle = title

        b.configuration = cfg
        return b
    }()

    private lazy var hiddenCompactPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .compact
        p.locale = .current
        p.date = selectedDate
        p.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        p.alpha = 0.02
        p.isUserInteractionEnabled = true
        return p
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        searchField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        searchField.delegate = self
        
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
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        report("open")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        report("close")
    }
    
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        try? trackerStore.create(tracker, in: categoryTitle)
    }
    
    private func configureStaticHeaderAndSearch() {
        view.addSubviews([headerLabel, searchField, cancelButton])
        
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        searchField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        searchTrailingToSuperview = searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        searchTrailingToCancel = searchField.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8)
        searchTrailingToCancel.isActive = false
        searchTrailingToSuperview.isActive = true
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            searchField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 7),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.heightAnchor.constraint(equalToConstant: 36),
            
            cancelButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        searchField.addTarget(self, action: #selector(searchEditingDidBegin), for: .editingDidBegin)
        searchField.addTarget(self, action: #selector(searchEditingDidEnd), for: .editingDidEnd)
        
        updateCancelVisibility(animated: false)
    }
    
    private func configureNavigationBar() {
        let addButton = UIButton(type: .system)
        var plusConfig = UIButton.Configuration.plain()
        plusConfig.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))
        plusConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        addButton.configuration = plusConfig
        addButton.tintColor = Colors.buttonColor
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)
        
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(datePillButton)
        container.addSubview(hiddenCompactPicker)

        datePillButton.translatesAutoresizingMaskIntoConstraints = false
        hiddenCompactPicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            datePillButton.topAnchor.constraint(equalTo: container.topAnchor),
            datePillButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            datePillButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            datePillButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            container.widthAnchor.constraint(equalTo: datePillButton.widthAnchor),
            container.heightAnchor.constraint(equalTo: datePillButton.heightAnchor),

            hiddenCompactPicker.topAnchor.constraint(equalTo: container.topAnchor),
            hiddenCompactPicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hiddenCompactPicker.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hiddenCompactPicker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        datePillButton.setContentHuggingPriority(.required, for: .horizontal)
        datePillButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.setContentCompressionResistancePriority(.required, for: .horizontal)

        hiddenCompactPicker.alpha = 0.02
        hiddenCompactPicker.isUserInteractionEnabled = true
        container.bringSubviewToFront(hiddenCompactPicker)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }
    
    private func configureLayout() {
        emptyStateImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubviews([collectionView, emptyStateImage, emptyStateLabel, filterButton])
        
        let bottomInset: CGFloat = 50
        collectionView.contentInset.bottom = bottomInset
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .always
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            
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
    private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        let point = gr.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        
        let cell = collectionView.cellForItem(at: indexPath) as! TrackerCell
        let frameInWindow = cell.cardView.convert(cell.cardView.bounds, to: nil)
        
        let snapshot = cell.cardView.snapshotView(afterScreenUpdates: false)
        ?? cell.cardView.resizableSnapshotView(from: cell.cardView.bounds,
                                               afterScreenUpdates: false,
                                               withCapInsets: .zero)!
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let categoryTitle = visibleCategories[indexPath.section].title
        let completedCount = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        let menu = ContextMenuController(
            title: "",
            mode: .tracker,
            anchorFrameInWindow: frameInWindow,
            previewView: snapshot
        )
        
        menu.onEdit = { [weak self] in
            guard let self else { return }
            self.report("click", item: "edit")
            let editVC = TrackerEditViewController(
                tracker: tracker,
                categoryTitle: categoryTitle,
                completedCount: completedCount,
                categoryStore: self.trackerCategoryStore
            )
            editVC.delegate = self
            let nav = UINavigationController(rootViewController: editVC)
            nav.modalPresentationStyle = .pageSheet
            self.present(nav, animated: true)
        }
        
        menu.onDelete = { [weak self] in
            self?.report("click", item: "delete")
            self?.presentDeleteConfirmation(for: tracker)
        }
        
        present(menu, animated: false)
    }
    
    
    @objc
    private func addButtonTapped() {
        report("click", item: "add_track")
        let createVC = CreateTrackerViewController(categoryStore: trackerCategoryStore)
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    @objc
    private func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        datePillButton.setTitle(dateFormatter.string(from: sender.date), for: .normal)
        updateVisibleCategoriesAndUI()
    }
    
    private func updateVisibleCategoriesAndUI() {
        visibleCategories = filterVisibleCategories(for: selectedDate, query: searchQuery, filter: currentFilter)
        collectionView.reloadData()
        updateEmptyState()
        updateFilterButtonVisibility()
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
    
    private func updateEmptyState() {
        let hasVisibleTrackers = !visibleCategories.isEmpty
        emptyStateImage.isHidden = hasVisibleTrackers
        emptyStateLabel.isHidden = hasVisibleTrackers
        
        guard !hasVisibleTrackers else { return }
        
        let hasQuery = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasQuery {
            emptyStateImage.image = UIImage(resource: .mokoError)
            emptyStateLabel.text = NSLocalizedString("nothing_found", comment: "")
        } else {
            emptyStateImage.image = UIImage(resource: .mokoStar)
            emptyStateLabel.text = NSLocalizedString("what_to_track", comment: "")
        }
    }
    
    
    private func filterVisibleCategories(for date: Date,
                                         query: String,
                                         filter: TrackerFilter) -> [TrackerCategory] {
        let weekdayInt = Calendar.current.component(.weekday, from: date)
        guard let selectedWeekday = WeekDay.from(calendarWeekday: weekdayInt) else { return [] }
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasQuery = !trimmed.isEmpty
        let dayStart = Calendar.current.startOfDay(for: date)
        
        return categories.compactMap { category in
            let trackersForDay = category.trackers.filter { tracker in
                guard tracker.schedule.contains(selectedWeekday) else { return false }
                
                if hasQuery, !tracker.title.lowercased().contains(trimmed) { return false }
                
                switch filter {
                case .all, .today:
                    return true
                case .completed:
                    return completedTrackers.contains(TrackerRecord(trackerId: tracker.id, date: dayStart))
                case .uncompleted:
                    return !completedTrackers.contains(TrackerRecord(trackerId: tracker.id, date: dayStart))
                }
            }
            guard !trackersForDay.isEmpty else { return nil }
            return TrackerCategory(title: category.title, trackers: trackersForDay)
        }
    }
    
    @objc
    private func searchTextChanged(_ sender: UISearchTextField) {
        searchQuery = sender.text ?? ""
        updateVisibleCategoriesAndUI()
        updateCancelVisibility()
    }
    
    @objc
    private func filterButtonTapped() {
        report("click", item: "filter")
        let vc = FiltersViewController()
        vc.modalPresentationStyle = .formSheet
        vc.preselected = currentFilter
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    
    private func applyVisualSignalForFilter() {
        let isActive = (currentFilter == .completed || currentFilter == .uncompleted)
        var config = filterButton.configuration
        config?.baseForegroundColor = isActive ? .ypRed : .ypWhiteDay
        filterButton.configuration = config
    }
    
    private func updateFilterButtonVisibility() {
        let weekdayInt = Calendar.current.component(.weekday, from: selectedDate)
        let selectedWeekday = WeekDay.from(calendarWeekday: weekdayInt)
        let hasAnyForDay = categories.contains { c in
            c.trackers.contains { t in t.schedule.contains(selectedWeekday!) }
        }
        filterButton.isHidden = !hasAnyForDay
    }
    
    private func presentDeleteConfirmation(for tracker: Tracker) {
        let message = NSLocalizedString("delete_tracker_confirm", comment: "")
        
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .actionSheet)
        
        let delete = UIAlertAction(
            title: NSLocalizedString("delete_button", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            guard let self else { return }
            try? self.trackerStore.delete(tracker)
            self.categories = (try? self.trackerCategoryStore.fetchAll()) ?? []
            self.completedTrackers = Set((try? self.trackerRecordStore.fetchAll()) ?? [])
            self.updateVisibleCategoriesAndUI()
        }
        
        let cancel = UIAlertAction(
            title: NSLocalizedString("cancel_button", comment: ""),
            style: .cancel,
            handler: nil
        )
        
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    @objc
    private func searchEditingDidBegin() { updateCancelVisibility() }
    
    @objc
    private func searchEditingDidEnd() { updateCancelVisibility() }
    
    private func updateCancelVisibility(animated: Bool = true) {
        let shouldShow = searchField.isFirstResponder || !(searchField.text ?? "").isEmpty
        
        if cancelButton.isHidden == !shouldShow { return }
        
        searchTrailingToSuperview.isActive = !shouldShow
        searchTrailingToCancel.isActive = shouldShow
        
        if shouldShow {
            cancelButton.isHidden = false
            cancelButton.alpha = 0
        }
        
        let animations = {
            self.cancelButton.alpha = shouldShow ? 1 : 0
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: animations) { _ in
                if !shouldShow { self.cancelButton.isHidden = true }
            }
        } else {
            animations()
            cancelButton.isHidden = !shouldShow
        }
    }
    
    
    @objc
    private func cancelSearchTapped() {
        searchField.text = ""
        searchQuery = ""
        searchField.resignFirstResponder()
        updateVisibleCategoriesAndUI()
        updateCancelVisibility()
    }
    
    private func report(_ event: String, item: String? = nil) {
        var params: [AnyHashable: Any] = [
            "event": event,
            "screen": "Main"
        ]
        if let item { params["item"] = item }
        analytics.report(event: "ui_event", params: params)
        print("[ANALYTICS] \(params)")
    }
}

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
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
            self.report("click", item: "track")
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

extension TrackersViewController: FiltersViewControllerDelegate {
    func filtersViewController(_ vc: FiltersViewController, didSelect filter: TrackerFilter) {
        currentFilter = filter
        UserDefaults.standard.set(filter.rawValue, forKey: Defaults.filterKey)
        
        if filter == .today {
            selectedDate = Date()
            hiddenCompactPicker.date = selectedDate
            datePillButton.setTitle(dateFormatter.string(from: selectedDate), for: .normal)
        }
        applyVisualSignalForFilter()
        updateVisibleCategoriesAndUI()
    }
}

extension TrackersViewController: TrackerEditViewControllerDelegate {
    func trackerEditViewController(
        _ vc: TrackerEditViewController,
        didSave tracker: Tracker,
        toCategoryTitle categoryTitle: String
    ) {
        try? trackerStore.update(tracker, toCategoryTitle: categoryTitle)
        categories = (try? trackerCategoryStore.fetchAll()) ?? []
        completedTrackers = Set((try? trackerRecordStore.fetchAll()) ?? [])
        updateVisibleCategoriesAndUI()
    }
}

extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchQuery = ""
        updateVisibleCategoriesAndUI()
        return true
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
