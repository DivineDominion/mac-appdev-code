//
//  CoreDataBoxRepositoryTests.swift
//  DDDViewDataExample
//
//  Created by Christian Tietze on 16.11.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

import Cocoa
import XCTest

import DDDViewDataExample

class TestIntegerIdGenerator : NSObject, GeneratesIntegerId {
    let firstAttempt: IntegerId = 1234
    let secondAttempt: IntegerId = 5678
    var callCount = 0
    
    func integerId() -> IntegerId {
        let identifier = (callCount == 0 ? firstAttempt : secondAttempt)
        
        callCount++
        
        return identifier
    }
}

class CoreDataBoxRepositoryTests: CoreDataTestCase {
    var repository: CoreDataBoxRepository?
    
    override func setUp() {
        super.setUp()
        
        repository = CoreDataBoxRepository(managedObjectContext: context)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func allBoxes() -> [ManagedBox]? {
        let request = NSFetchRequest(entityName: ManagedBox.entityName())
        return context.executeFetchRequest(request, error: nil) as? [ManagedBox]
    }

    //MARK: Adding Entities

    func testAddingBox_InsertsEntityIntoStore() {
        let title = "a title"
        let boxId = repository!.nextId()
        let box = Box(boxId: boxId, title: title)
    
        repository!.addBox(box)

        let boxes = self.allBoxes()!
        XCTAssert(boxes.count > 0, "items expected")
        
        if let managedBox = boxes.first {
            XCTAssertEqual(managedBox.title, title, "Title should be saved")
            XCTAssertEqual(managedBox.boxId(), boxId, "Box ID should be saved")
        }
    }

    //MARK: Generating IDs
    
    func testNextId_WhenGeneratedIdIsTaken_ReturnsAnotherId() {
        let testGenerator = TestIntegerIdGenerator()
        repository = CoreDataBoxRepository(managedObjectContext: context, integerIdGenerator: testGenerator)
        let existingId = BoxId(testGenerator.firstAttempt)
        ManagedBox.insertManagedBox(existingId, title: "irrelevant", inManagedObjectContext: context)
        
        let boxId = repository!.nextId()
        
        let expectedNextId = BoxId(testGenerator.secondAttempt)
        XCTAssertEqual(boxId, expectedNextId, "Should generate another ID because first one is taken")
    }
}
