import UIKit

final class GradientBorderView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientBorder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientBorder()
    }
    
    private func setupGradientBorder() {
        backgroundColor = Colors.viewBackgroundColor
        layer.cornerRadius = 16
        layer.masksToBounds = true

        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)

        
        gradientLayer.colors = [
            UIColor.systemGreen.cgColor, // 0.00  низ
            UIColor.systemRed.cgColor,   // 0.14  старт красного (левая)
            UIColor.systemRed.cgColor,   // 0.36  конец красного
            UIColor.systemGreen.cgColor, // 0.50  верх
            UIColor.systemBlue.cgColor,  // 0.64  старт синего (правая)
            UIColor.systemBlue.cgColor,  // 0.86  конец синего
            UIColor.systemGreen.cgColor  // 1.00  низ
        ]
        gradientLayer.locations = [0.00, 0.14, 0.36, 0.50, 0.64, 0.86, 1.00] as [NSNumber]
        layer.addSublayer(gradientLayer)

        shapeLayer.lineWidth = 1
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = shapeLayer
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 16)
        shapeLayer.path = path.cgPath
    }
}
