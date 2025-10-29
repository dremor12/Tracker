import UIKit
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        
        let window = UIWindow(windowScene: windowScene)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext


        let trackerStore = TrackerStore(context: context)
        let recordStore = TrackerRecordStore(context: context)
        let categoryStore = TrackerCategoryStore(context: context)
        
        let root: UIViewController
        if OnboardingViewController.hasSeenOnboarding() {
            root = TabBarViewController(
                trackerStore: trackerStore,
                categoryStore: categoryStore,
                recordStore: recordStore
            )
        } else {
            root = OnboardingViewController()
        }

        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window
    }
}
