//
//  AppDelegate.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
//        let request = Item.fetchRequest()
//        let context = persistentContainer.viewContext
//
//        do {
//            var allItems = try context.fetch(request)
//            for item in allItems {
//                if item.parentCategory == nil {
//                    print("Item called \"\(item.title!)\" is nil")
//                    context.delete(item)
//                }
//            }
//            try context.save()
//
//        } catch {
//            print("Error fetching data from context: \(error)")
//        }
        
        
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

