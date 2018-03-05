//
//  CoreDataPOCTests.swift
//  CoreDataPOCTests
//
//  Created by Jamy C on 05/03/2018.
//  Copyright © 2018 Jamy C. All rights reserved.
//

import XCTest
import CoreData

@testable import CoreDataPOC

class CoreDataPOCTests: XCTestCase {
    
    func testQueryGenerationsIssue() {
        setUpPersistentContainer { (container) in
            let mainContext = container.viewContext
            NoteDAO.deleteAll(context: mainContext)
            NoteDAO.seed(context: mainContext)
            
            let note = NoteDAO.getAll(context: mainContext).first!
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 0) // Notes are initialized with value = 0, so this obviously should be 0
            
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            XCTAssertEqual(note.value, 0) // Still 0 because the NSQueryGenerationToken is not updated yet
            
            mainContext.pinGeneration() // Quick extension to use setQueryGenerationFrom(.current)
            XCTAssertEqual(note.value, 0) // Still 0 because we have not refreshed our context yet
            
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 2) // After refreshing we see the expected value 2
            
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            XCTAssertEqual(note.value, 2)
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 4) // Value == 4 after 'pinning' and refreshing
            
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            NoteDAO.bumpValue(of: note, in: container.newBackgroundContext())
            XCTAssertEqual(note.value, 4)
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 6) // Value == 6 after 'pinning' and refreshing
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            
            /*
             Nothing was changed in the meantime so I expect the value to be 6 on line 62, it is however 5 (??)
             Removing the XCTAssertEqual at line 62 somehow makes the test pass.
             */
            XCTAssertEqual(note.value, 6)
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 6) // Value == 3, why?
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 6) // Value == 1, why?
            
            mainContext.pinGeneration()
            mainContext.refreshAllObjects()
            XCTAssertEqual(note.value, 6) // Value == 6 again
        }
    }
    
    func setUpPersistentContainer(completion: @escaping (NSPersistentContainer) -> ()) {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "TestContainer", managedObjectModel: managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            completion(container)
        })
    }
}

extension NSManagedObjectContext {
    func pinGeneration(to token: NSQueryGenerationToken? = .current) {
        try! self.setQueryGenerationFrom(token)
    }
}
