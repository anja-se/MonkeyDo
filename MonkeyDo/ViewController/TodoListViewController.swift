//
//  TodoListViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController, UITableViewDragDelegate {
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var allItems = [Item]()
    var displayItems = [Item]()
    var parentCategory: Category? {
        didSet {
            loadItems()
            title = parentCategory?.name
        }
    }
    var onHide = false
    var menu = UIMenu()
    let menutItem = UIBarButtonItem(title: "Actions", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: UIMenu())
    var hideAction = UIAction(){_ in }
    var showAction = UIAction(){_ in }
    var clearAction = UIAction(){_ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "TodoCell", bundle: nil), forCellReuseIdentifier: "TodoCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        
        setupBar()
    }
    
    //MARK: - Tableview datasource methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        let item = displayItems[indexPath.row]
        cell.label.text = item.title
        cell.checked = item.done ? true : false
        if let color = parentCategory?.color {
            cell.cellView.backgroundColor = UIColor(named: color)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayItems.count
    }
    
    // MARK: - Table view delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        displayItems[indexPath.row].done.toggle()
        let item = displayItems[indexPath.row]
        
        if onHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.displayItems.removeAll {
                    $0.done == true && $0.index == item.index && $0.title == item.title
                }
                self.tableView.reloadData()
            }
        }
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
        let newIndex = Int(displayItems[destinationIndexPath.row].index)
        let mover = displayItems.remove(at: sourceIndexPath.row)
        displayItems.insert(mover, at: destinationIndexPath.row)
        
        if onHide {
            let fromIndex = Int(mover.index)
            let mover = allItems.remove(at: fromIndex)
            allItems.insert(mover, at: newIndex)
        } else {
            allItems = displayItems
        }
        
        updateIndices()
    }
    
    //MARK: - Tableview drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = displayItems[indexPath.row]
        return [dragItem]
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
            allItems = items.sorted(by: { $0.index < $1.index })
            displayItems = allItems
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
        
        context.delete(displayItems[index])
        if onHide {
            let mainIndex = Int(displayItems[index].index)
            print("mainIndex is: \(mainIndex)")
            allItems.remove(at: mainIndex)
        }
        displayItems.remove(at: index)
        updateIndices()
        
        saveItems()
    }
    
    func updateIndices(){
        for i in 0..<allItems.count {
            allItems[i].index = Int16(i)
        }
        saveItems()
    }
    
    //MARK: - Bar and Menu Configuration
    
    func setupBar() {
        menutItem.tintColor = UIColor(named: "PinkColor")
        self.navigationItem.rightBarButtonItems = [menutItem, addButton]
        
        hideAction = UIAction(title: "Hide completed", image: UIImage(systemName: "eye.slash")) { action in
            self.hide()
            self.updateMenu()
        }
        showAction = UIAction(title: "Show completed", image: UIImage(systemName: "eye")) { action in
            self.show()
            self.updateMenu()
        }
        clearAction = UIAction(title: "Clear completed", image: UIImage(systemName: "xmark.circle")) {_ in
            self.clear()
        }
        
        updateMenu()
        menutItem.menu = menu
    }
    
    func updateMenu(){
        let action = onHide ? showAction : hideAction
        menu = UIMenu(title: "", options: .displayInline, children: [action, clearAction])
        menutItem.menu = menu
    }
    
    
    // MARK: - Add, clear, show, hide
    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todo Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            if !textField.text!.isEmpty {
                
                let newItem = Item(context: self.context)
                newItem.title = textField.text!
                newItem.done = false
                newItem.index = Int16(self.allItems.count)
                newItem.parentCategory = self.parentCategory
                self.displayItems.append(newItem)
                self.allItems.append(newItem)
                self.saveItems()
            }
        }
        alert.addAction(action)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            alertTextField.autocapitalizationType = .sentences
            textField = alertTextField
        }
        present(alert, animated: true, completion: nil)
    }
    
    func show(){
        onHide = false
        displayItems = allItems//.sorted(by: { $0.index < $1.index })
        tableView.reloadData()
    }
    
    func hide(){
        onHide = true
        displayItems = allItems.filter{ !$0.done }
        tableView.reloadData()
    }
    
    func clear(from startIndex: Int = 0){
//        if startIndex >= allItems.count {
//            return
//        }
//
//        for i in startIndex ..< allItems.count {
//            if allItems[i].done {
//                deleteItem(at: i)
//                clear(from: i)
//            }
//        }
    }
}
