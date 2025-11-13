import UIKit

final class ScheduleViewController: UIViewController {
    
    private let days: [WeekDay] = WeekDay.allCases.sorted { $0.order < $1.order }
    
    private var selectedDays: Set<WeekDay>
    
    var onDaysChanged: (([WeekDay]) -> Void)?
    
    init(initialSelectedDays: [WeekDay] = []) {
        self.selectedDays = Set(initialSelectedDays)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.backgroundView
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("ready", comment: ""), for: .normal)
        button.backgroundColor = Colors.buttonColor
        button.setTitleColor(Colors.buttonTextColor, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("shedule", comment: "")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.viewBackgroundColor
        
        title = NSLocalizedString("shedule", comment: "")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: ScheduleCell.reuseIdentifier)
        configurationLayout()
        
        
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
    }
    
    private func configurationLayout() {
        view.addSubviews([containerView, doneButton])
        containerView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -47),
            
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc
    private func switchChanged(_ sender: UISwitch) {
        let day = days[sender.tag]
        if sender.isOn {
            selectedDays.insert(day)
        } else {
            selectedDays.remove(day)
        }
    }

    @objc
    private func doneTapped() {
        let sorted = selectedDays.sorted { $0.order < $1.order }
        onDaysChanged?(sorted)
        dismiss(animated: true)
    }
}

extension ScheduleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleCell.reuseIdentifier, for: indexPath) as! ScheduleCell
        let day = days[indexPath.row]
        let isLast = indexPath.row == days.count - 1

        cell.configure(with: day, isOn: selectedDays.contains(day), isLast: isLast)

        cell.toggleSwitch.tag = indexPath.row
        cell.toggleSwitch.removeTarget(nil, action: nil, for: .allEvents)
        cell.toggleSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        return cell
    }
}
