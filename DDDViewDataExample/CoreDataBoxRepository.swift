//
//  CoreDataBoxRepository.swift
//  DDDViewDataExample
//
//  Created by Christian Tietze on 24.11.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

import Cocoa
import CoreData
import Security

public protocol GeneratesIntegerId {
    func integerId() -> IntegerId
}

struct DefaultIntegerIdGenerator: GeneratesIntegerId {
    func integerId() -> IntegerId {
        arc4random_stir()
        var urandom: UInt64
        urandom = (UInt64(arc4random()) << 32) | UInt64(arc4random())
        
        var random: IntegerId = (IntegerId) (urandom & 0x7FFFFFFFFFFFFFFF);
        
        return random
    }
}

struct IdGenerator<Id: Identifiable> {
    let integerIdGenerator: GeneratesIntegerId
    let integerIdIsTaken: (IntegerId) -> Bool
    
    func nextId() -> Id {
        return Id(unusedIntegerId())
    }

    func unusedIntegerId() -> IntegerId {
        var identifier: IntegerId
        
        do {
            identifier = integerId()
        } while integerIdIsTaken(identifier)
        
        return identifier
    }

    func integerId() -> IntegerId {
        return integerIdGenerator.integerId()
    }
}

public class CoreDataBoxRepository: NSObject, BoxRepository {
    let managedObjectContext: NSManagedObjectContext
    let integerIdGenerator: GeneratesIntegerId
    
    public convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(managedObjectContext: managedObjectContext, integerIdGenerator: DefaultIntegerIdGenerator())
    }
    
    public init(managedObjectContext: NSManagedObjectContext, integerIdGenerator: GeneratesIntegerId) {
        self.managedObjectContext = managedObjectContext
        self.integerIdGenerator = integerIdGenerator
        
        super.init()
    }
    
    public func addBox(box: Box) {
        ManagedBox.insertManagedBox(box.boxId, title: box.title, inManagedObjectContext: self.managedObjectContext)
    }
    
    public func boxWithId(boxId: BoxId) -> Box? {
        if let managedBox = managedBoxWithUniqueId(boxId.identifier) {
            return managedBox.box
        }
        
        return nil
    }
    
    public func boxes() -> [Box] {
        let fetchRequest = NSFetchRequest(entityName: ManagedBox.entityName())
        fetchRequest.includesSubentities = true
        
        var error: NSError? = nil
        let results = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        
        if results == nil {
            assert(false, "error fetching boxes")
            //TODO: handle fetch error
            return []
        }
        
        let managedBoxes: [ManagedBox] = results as [ManagedBox]
        
        return managedBoxes.map({ (managedBox: ManagedBox) -> Box in
            return managedBox.box
        })
    }
    
    public func count() -> Int {
        let fetchRequest = NSFetchRequest(entityName: ManagedBox.entityName())
        fetchRequest.includesSubentities = false
        
        var error: NSError? = nil
        let count = managedObjectContext.countForFetchRequest(fetchRequest, error: &error)
        
        if count == NSNotFound {
            assert(false, "error fetching count")
            //FIXME: handle error
            return NSNotFound
        }
        
        return count
    }
    
    
    //MARK: Box ID Generation
    
    public func nextId() -> BoxId {
        let generator = IdGenerator<BoxId>(integerIdGenerator: integerIdGenerator, integerIdIsTaken: hasManagedBoxWithUniqueId)
        return generator.nextId()
    }
    
    func hasManagedBoxWithUniqueId(identifier: IntegerId) -> Bool {
        return self.managedBoxWithUniqueId(identifier) != nil
    }
    
    func managedBoxWithUniqueId(identifier: IntegerId) -> ManagedBox? {
        let managedObjectModel = managedObjectContext.persistentStoreCoordinator!.managedObjectModel
        let templateName = "ManagedBoxWithUniqueId"
        let fetchRequest = managedObjectModel.fetchRequestFromTemplateWithName(templateName, substitutionVariables: ["IDENTIFIER": NSNumber(longLong: identifier)])
        
        assert(fetchRequest != nil, "Fetch request named 'ManagedBoxWithUniqueId' is required")
        
        var error: NSError? = nil
        let result = managedObjectContext.executeFetchRequest(fetchRequest!, error:&error);
        
        if result == nil {
            assert(false, "error fetching box with id")
            //FIXME: handle error: send event to delete project from view and say that changes couldn't be saved
            return nil
        }
        
        if result!.count == 0 {
            return nil
        }
        
        return result![0] as? ManagedBox
    }
    
    
    //MARK: Item ID Generation
    
    public func nextItemId() -> ItemId {
        let generator = IdGenerator<ItemId>(integerIdGenerator: integerIdGenerator, integerIdIsTaken: hasManagedItemWithUniqueId)
        return generator.nextId()
    }
    
    func hasManagedItemWithUniqueId(identifier: IntegerId) -> Bool {
        let managedObjectModel = managedObjectContext.persistentStoreCoordinator!.managedObjectModel
        let templateName = "ManagedItemWithUniqueId"
        let fetchRequest = managedObjectModel.fetchRequestFromTemplateWithName(templateName, substitutionVariables: ["IDENTIFIER": NSNumber(longLong: identifier)])
        
        assert(fetchRequest != nil, "Fetch request named 'ManagedItemWithUniqueId' is required")
        
        var error: NSError? = nil
        let count = managedObjectContext.countForFetchRequest(fetchRequest!, error: &error)
        
        if count == NSNotFound {
            assert(false, "error fetch item with id")
            //FIXME: handle error: send event to delete project from view and say that changes couldn't be saved
            return false
        }
        
        return count > 0
    }
}