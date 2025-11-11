import UIKit

final class StatisticCell: UITableViewCell {
    
    private let gradientBorder = GradientBorderView()
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    
    static let identifier = "StatisticCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        numberLabel.font = .boldSystemFont(ofSize: 32)
        numberLabel.textColor = .label
        
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .label
        
        contentView.addSubview(gradientBorder)
        gradientBorder.addSubview(numberLabel)
        gradientBorder.addSubview(titleLabel)
        
        gradientBorder.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gradientBorder.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            gradientBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            gradientBorder.heightAnchor.constraint(equalToConstant: 90),
            
            numberLabel.topAnchor.constraint(equalTo: gradientBorder.topAnchor, constant: 12),
            numberLabel.leadingAnchor.constraint(equalTo: gradientBorder.leadingAnchor, constant: 12),
            
            titleLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: gradientBorder.leadingAnchor, constant: 12)
        ])
    }
    
    func configure(number: Int, title: String) {
        numberLabel.text = "\(number)"
        titleLabel.text = title
    }
}
