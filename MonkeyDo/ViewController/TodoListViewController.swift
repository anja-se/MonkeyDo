//
//  TodoListViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController, UITableViewDragDelegate {

    var items = [Item]()
    var parentCategory: Category? {
        didSet {
            loadItems()
            title = parentCategory?.name
        }
    }
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
   
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "TodoCell", bundle: nil), forCellReuseIdentifier: "TodoCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
    }
    
    //MARK: - Tableview datasource methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        let item = items[indexPath.row]
        cell.label.text = item.title
        cell.checked = item.done ? true : false
        if let color = parentCategory?.color {
            cell.cellView.backgroundColor = UIColor(named: color)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    // MARK: - Table view delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].done.toggle()
        saveItems()
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "delete") { [weak self] (action, view, completionHandler) in
            self?.deleteItem(at: indexPath.row)
            completionHandler(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = items.remove(at: sourceIndexPath.row)
        items.insert(mover, at: destinationIndexPath.row)
        
        for i in 0..<items.count {
            items[i].index = Int16(i)
        }
        saveItems()
    }
    
    //MARK: - Tableview drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = items[indexPath.row]
        return [dragItem]
    }
    
    // MARK: - Add new items
    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todo Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            if !textField.text!.isEmpty {
                
                let newItem = Item(context: self.context)
                newItem.title = textField.text!
                newItem.done = false
                newItem.index = Int16(self.items.count)
                newItem.parentCategory = self.parentCategory
                self.items.append(newItem)
                self.saveItems()
            }
        }
        alert.addAction(action)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Data manipulation methods
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil){
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", parentCategory!.name!)
        
        if let additionalPredicate = predicate {
            let compoundedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
            request.predicate = compoundedPredicate
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            let items = try context.fetch(request)
            self.items = items.sorted(by: { $0.index < $1.index })
        } catch {
            print("Error fetching data from context: \(error)")
        }
        tableView.reloadData()
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        
        self.tableView.reloadData()
    }
    
    func deleteItem(at index: Int){
        context.delete(items[index])
        items.remove(at: index)
        saveItems()
    }
}
