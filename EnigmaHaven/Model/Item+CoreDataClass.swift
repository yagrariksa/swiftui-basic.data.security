//
//  Item+CoreDataClass.swift
//  EnigmaHaven
//
//  Created by Daffa Yagrariksa on 11/09/23.
//
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject {
    static func create(
        _ viewContext: NSManagedObjectContext,
        _ title: String,
        _ data: String?,
        _ hide: Bool = false
    ) throws {
        let newItem = Item(context: viewContext)
        
        newItem.title = title
        newItem.data = data
        newItem.timestamp = Date()
        newItem.hide = hide
        
        do {
            try viewContext.save()
            print("🟢SUCCESS: create Item")
        } catch {
            print("🔴ERROR: create Item: \(String(describing: error))")
            throw ItemError.FailCreateItem
        }
    }
}

enum ItemError: Error {
    case FailCreateItem
}
