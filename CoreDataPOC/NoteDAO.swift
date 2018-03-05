//
//  DAO.swift
//  CoreDataPOC
//
//  Created by Jamy C on 05/03/2018.
//  Copyright © 2018 Jamy C. All rights reserved.
//

import CoreData

extension Note {
    convenience init(created: Date, value: Int, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.value = Int32(value)
        self.created = created
    }
}

class NoteDAO {
    static func deleteAll(context: NSManagedObjectContext) {
        getAll(context: context).forEach { (note) in
            context.delete(note)
        }
        try! context.save()
    }
    
    static func getAll(context: NSManagedObjectContext) -> [Note] {
        let fr: NSFetchRequest = Note.fetchRequest()
        return try! context.fetch(fr)
    }
    
    static func bumpValue(of note: Note?, in context: NSManagedObjectContext?) {
        guard let note = note, let context = context else { return }
        
        context.performAndWait {
            // Grab the note object in the proper context
            let contextNote = context.object(with: note.objectID) as! Note
            
            contextNote.value = contextNote.value + 1
            try! context.save()
        }
    }
    
    static func seed(context: NSManagedObjectContext) {
        let date = Date()
        let value = 0
        
        // Create a few notes
        for _ in 0...4 {
            let _ = Note(created: date, value: value, context: context)
        }
        
        try! context.save()
    }
}
