import Foundation
import CoreData

final class CategoryViewModel: NSObject {
    
    var onDataChanged: (() -> Void)?
    var onSelectionChanged: ((IndexPath?) -> Void)?

    private(set) var categories: [TrackerCategory] = [] {
        didSet { onDataChanged?() }
    }
    private(set) var selectedIndexPath: IndexPath? {
        didSet { onSelectionChanged?(selectedIndexPath) }
    }

    private let store: TrackerCategoryStore

    init(store: TrackerCategoryStore) {
        self.store = store
        super.init()
        self.store.delegate = self
    }

    func start() {
        store.startObserving()
        reload()
    }

    func rowsCount() -> Int { categories.count }

    func title(at index: Int) -> String {
        guard index >= 0 && index < categories.count else { return "" }
        return categories[index].title
    }

    func isChecked(at indexPath: IndexPath) -> Bool {
        return indexPath == selectedIndexPath
    }

    func select(at indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }

    func createCategory(title: String) {
        try? store.createCategory(title: title)
    }

    func renameCategory(originalTitle: String, to newTitle: String) {
        try? store.renameCategory(oldTitle: originalTitle, newTitle: newTitle)
    }

    func deleteCategory(title: String) {
        try? store.deleteCategory(title: title)
        if let selected = selectedIndexPath,
           selected.row < categories.count,
           categories[selected.row].title == title {
            selectedIndexPath = nil
        }
    }

    func indexPath(ofTitle title: String) -> IndexPath? {
        guard let row = categories.firstIndex(where: { $0.title == title }) else { return nil }
        return IndexPath(row: row, section: 0)
    }

    private func reload() {
        categories = (try? store.fetchAll()) ?? []
    }
}

extension CategoryViewModel: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidChange(_ store: TrackerCategoryStore) {
        reload()
    }
}
