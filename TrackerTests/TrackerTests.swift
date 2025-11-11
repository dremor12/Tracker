import XCTest
import SnapshotTesting
@testable import Tracker
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import CoreData

final class TrackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    private func makeMainScreen() -> UIViewController {
        let container = TestCoreDataStack.makeInMemoryContainer()
        let context = container.viewContext

        let trackerStore = TrackerStore(context: context)
        let categoryStore = TrackerCategoryStore(context: context)
        let recordStore = TrackerRecordStore(context: context)

        let root = TrackersViewController(
            trackerStore: trackerStore,
            categoryStore: categoryStore,
            recordStore: recordStore
        )
        let nav = UINavigationController(rootViewController: root)
        nav.loadViewIfNeeded()
        return nav
    }

    func test_mainScreen_light() {
        let vc = makeMainScreen()

        let traits = UITraitCollection { t in
            t.userInterfaceStyle = .light
        }
        withSnapshotTesting(record: false) {
            assertSnapshot(
                of: vc,
                as: .image(traits: traits)
            )
        }
    }
    
    func test_mainScreen_dark() {
        let vc = makeMainScreen()

        let traits = UITraitCollection { t in
            t.userInterfaceStyle = .dark
        }
        withSnapshotTesting(record: false) {
            assertSnapshot(
                of: vc,
                as: .image(traits: traits)
            )
        }
    }
}
