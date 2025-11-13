import UIKit

final class StatisticsViewController: UIViewController {

    // MARK: - Dependencies
    private let recordStore: TrackerRecordStore

    // MARK: - UI
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("statistics", comment: "")
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.backgroundColor = .clear
        t.separatorStyle = .none
        t.translatesAutoresizingMaskIntoConstraints = false
        t.contentInset = .init(top: 16, left: 0, bottom: 16, right: 0)
        return t
    }()

    private let emptyStateImage = UIImageView(image: UIImage(resource: .mokoNotStats))
    private let emptyStateLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = NSLocalizedString("analitics_not_found", comment: "")
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = Colors.buttonColor
        return l
    }()

    private var completedCount: Int = 0

    init(recordStore: TrackerRecordStore) {
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor

        recordStore.delegate = self
        recordStore.startObserving()

        tableView.dataSource = self
        tableView.register(StatisticCell.self, forCellReuseIdentifier: StatisticCell.identifier)

        layout()
        reloadStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStats()
    }

    private func layout() {
        emptyStateImage.translatesAutoresizingMaskIntoConstraints = false

        view.addSubviews([headerLabel, tableView, emptyStateImage, emptyStateLabel])

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -32),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImage.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func reloadStats() {
        completedCount = (try? recordStore.totalCompletedCount()) ?? 0
        tableView.reloadData()

        let isEmpty = (completedCount == 0)
        tableView.isHidden = isEmpty
        emptyStateImage.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
    }
}

extension StatisticsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedCount == 0 ? 0 : 1
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: StatisticCell.identifier,
            for: indexPath
        ) as! StatisticCell

        cell.configure(
            number: completedCount,
            title: NSLocalizedString("trackers_completed", comment: "")
        )
        return cell
    }
}

extension StatisticsViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore) {
        reloadStats()
    }
}
