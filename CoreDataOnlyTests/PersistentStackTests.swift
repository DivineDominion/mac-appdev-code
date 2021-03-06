import Cocoa
import XCTest

@testable import CoreDataOnly

class TestPersistentStack: PersistentStack {
    override func defaultStoreOptions() -> [String: AnyObject] {
        // Prevent iCloud usage (if set up in default options)
        return [String: AnyObject]()
    }
}

class PersistentStackTests: XCTestCase {
    let storeURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.sqlite")
    lazy var persistentStack: TestPersistentStack = {
        let modelURL = Bundle.main.url(forResource: kDefaultModelName, withExtension: "momd")
        return TestPersistentStack(storeURL: self.storeURL, modelURL: modelURL!)
    }()
    
    override func tearDown() {
        do {
            try FileManager.default.removeItem(at: storeURL)
        } catch {
            XCTFail("couldn't clean up test database file")
        }
        
        super.tearDown()
    }
    
    func testInitializer() {
        XCTAssertNotNil(self.persistentStack, "Should have a persistent stack")
    }
    
    func testManagedObjectContextSetUp() {
        XCTAssertNotNil(self.persistentStack.managedObjectContext, "Should have a managed object context")
        XCTAssertNotNil(self.persistentStack.managedObjectContext?.persistentStoreCoordinator, "Should have a persistent store coordinator")
        let store = self.persistentStack.managedObjectContext?.persistentStoreCoordinator?.persistentStores[0]
        XCTAssertNotNil(store, "Should have a persistent store")
        if let store = store {
            XCTAssertEqual(store.type, NSSQLiteStoreType, "Should be a sqlite store")
        }
        XCTAssertNotNil(self.persistentStack.managedObjectContext?.undoManager, "Should have an undo manager")
    }
}
