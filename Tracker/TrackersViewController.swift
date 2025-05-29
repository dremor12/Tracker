import UIKit

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
    }
}

final class TrackersViewController: UIViewController {
    
    private let labelTrackers: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor.black
        label.text = "Трекеры"
        return label
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = "Что будем отслеживать?"
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Поиск"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        return searchBar
    }()
    
    private let buttonAddTracker: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .black
        button.addTarget(nil, action: #selector(didTabAdd), for: .touchUpInside)
        return button
    }()
    
    private let imagePlaceholder: UIImageView = {
        let image = UIImageView(image: UIImage(named: "mock_star"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        return image
    } ()
    
    private let dataButton: UIButton = {
        let button = UIButton(type: .custom)
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        let formattedDate = formatter.string(from: currentDate)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(formattedDate, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.backgroundColor = .ypBackgroundDay
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubview()
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupSubview() {
        view.addSubviews([buttonAddTracker, dataButton, labelTrackers, searchBar, emptyLabel, imagePlaceholder])
        
        NSLayoutConstraint.activate([
            buttonAddTracker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            buttonAddTracker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            dataButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dataButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            labelTrackers.topAnchor.constraint(equalTo: buttonAddTracker.bottomAnchor, constant: 8),
            labelTrackers.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            labelTrackers.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: labelTrackers.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            imagePlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePlaceholder.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: imagePlaceholder.bottomAnchor, constant: 8)
        ])
    }
    
    @objc
    private func didTabAdd() {
        // TODO
    }
    
    @objc
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
