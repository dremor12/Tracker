import UIKit

final class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
        addHairline()
    }
    
    private func configureTabs() {
        
        let trackersViewController = TrackersViewController()
        let trackersNavigtion = UINavigationController(rootViewController: trackersViewController)
        trackersNavigtion.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        let statsViewController = StatisticsViewController()
        let statsNavigation = UINavigationController(rootViewController: statsViewController)
        statsNavigation.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: nil
        )
        
        viewControllers = [trackersNavigtion, statsNavigation]
    }
    
    private func addHairline() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .gray
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
