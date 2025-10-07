import UIKit
import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidChange(_ store: TrackerStore)
}

final class TrackerStore: NSObject {
    weak var delegate: TrackerStoreDelegate?
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }
    
    convenience override init() {
        let app = UIApplication.shared.delegate as! AppDelegate
        self.init(context: app.persistentContainer.viewContext)
    }

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
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
        _ = try? fetchedResultsController.performFetch()
    }

    func create(_ tracker: Tracker, in categoryTitle: String) throws {
        let categoryCoreData = try fetchOrCreateCategory(with: categoryTitle)

        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.title = tracker.title
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.colorHex = UIColorMarshalling().hexString(from: tracker.color)
        trackerCoreData.scheduleMask = daysMask(from: tracker.schedule)
        trackerCoreData.category = categoryCoreData

        try context.save()
    }


    func fetchAll() throws -> [Tracker] {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        let trackerCoreDataObjects = try context.fetch(fetchRequest)

        return trackerCoreDataObjects.compactMap { trackerCoreData in
            guard
                let id = trackerCoreData.id,
                let title = trackerCoreData.title,
                let emoji = trackerCoreData.emoji,
                let colorHex = trackerCoreData.colorHex
            else { return nil }

            let color = UIColorMarshalling().color(from: colorHex)
            let scheduleDays = days(from: trackerCoreData.scheduleMask)
            return Tracker(id: id, title: title, color: color, emoji: emoji, schedule: scheduleDays)
        }
    }


    private func fetchOrCreateCategory(with title: String) throws -> TrackerCategoryCoreData {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        fetchRequest.fetchLimit = 1

        if let existing = try context.fetch(fetchRequest).first { return existing }

        let created = TrackerCategoryCoreData(context: context)
        created.title = title
        return created
    }


    private func daysMask(from days: [WeekDay]) -> Int16 {
        var resultMask: Int16 = 0
        for (index, day) in WeekDay.allCases.enumerated() {
            if days.contains(day) { resultMask |= (1 << Int16(index)) }
        }
        return resultMask
    }

    private func days(from mask: Int16) -> [WeekDay] {
        WeekDay.allCases.enumerated().compactMap { index, day in
            (mask & (1 << Int16(index))) != 0 ? day : nil
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidChange(self)
    }
}
