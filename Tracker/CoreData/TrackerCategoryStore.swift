import UIKit
import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidChange(
        _ store: TrackerCategoryStore
    )
}

final class TrackerCategoryStore: NSObject {
    weak var delegate: TrackerCategoryStoreDelegate?
    private let context: NSManagedObjectContext
    
    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
        super.init()
    }
    
    convenience override init() {
        let app = UIApplication.shared.delegate as! AppDelegate
        self.init(
            context: app.persistentContainer.viewContext
        )
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(
            key: "title",
            ascending: true
        )]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()
    
    func startObserving() {
        _ = fetchedResultsController
        _ = try? fetchedResultsController
            .performFetch()
    }

    func fetchAll() throws -> [TrackerCategory] {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        let categoryCoreDataObjects = try context.fetch(fetchRequest)
        let colorMarshalling = UIColorMarshalling()

        return categoryCoreDataObjects.compactMap { categoryCoreData in
            guard let categoryTitle = categoryCoreData.title else { return nil }

            let trackerSet = (categoryCoreData.treckers as? Set<TrackerCoreData>) ?? []

            let sortedTrackersCoreData = trackerSet.sorted {
                let leftKey  = (($0.title ?? ""), ($0.id?.uuidString ?? ""))
                let rightKey = (($1.title ?? ""), ($1.id?.uuidString ?? ""))
                return leftKey < rightKey
            }

            let trackers: [Tracker] = sortedTrackersCoreData.compactMap { trackerCoreData in
                guard
                    let id = trackerCoreData.id,
                    let title = trackerCoreData.title,
                    let emoji = trackerCoreData.emoji,
                    let colorHex = trackerCoreData.colorHex
                else { return nil }

                let color = colorMarshalling.color(from: colorHex)
                let scheduleDays = days(from: trackerCoreData.scheduleMask)
                return Tracker(id: id, title: title, color: color, emoji: emoji, schedule: scheduleDays)
            }

            return TrackerCategory(title: categoryTitle, trackers: trackers)
        }
    }

    private func days(from mask: Int16) -> [WeekDay] {
        WeekDay.allCases.enumerated().compactMap { index, day in
            (mask & (1 << Int16(index))) != 0 ? day : nil
        }
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerCategoryStoreDidChange(self)
    }
}
