import CoreData

enum TestCoreDataStack {
    static func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Tracker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            precondition(error == nil, "Failed to load in-memory store: \(String(describing: error))")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }
}
