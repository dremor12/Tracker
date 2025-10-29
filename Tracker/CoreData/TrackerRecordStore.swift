import UIKit
import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore)
}

final class TrackerRecordStore: NSObject {
    weak var delegate: TrackerRecordStoreDelegate?
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context;
        super.init()
    }

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
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

    func add(_ record: TrackerRecord) throws {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", record.trackerId as CVarArg)

        guard let trackerCoreData = try context.fetch(fetchRequest).first else { return }

        let trackerRecordCoreData = TrackerRecordCoreData(context: context)
        trackerRecordCoreData.date = startOfDay(record.date)
        trackerRecordCoreData.tracker = trackerCoreData

        try context.save()
    }

    func delete(_ record: TrackerRecord) throws {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            record.trackerId as CVarArg,
            startOfDay(record.date) as CVarArg
        )

        if let trackerRecordCoreData = try context.fetch(fetchRequest).first {
            context.delete(trackerRecordCoreData)
            try context.save()
        }
    }

    func fetchAll() throws -> [TrackerRecord] {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let trackerRecordCoreDataObjects = try context.fetch(fetchRequest)

        return trackerRecordCoreDataObjects.compactMap { trackerRecordCoreData in
            guard
                let date = trackerRecordCoreData.date,
                let trackerId = trackerRecordCoreData.tracker?.id
            else {
                return nil
            }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidChange(self)
    }
}
