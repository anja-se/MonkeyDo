//
//  TodoListViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController, UITableViewDragDelegate, UITextFieldDelegate {
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    @IBOutlet weak var clearView: UIView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var items = [Item]()
    var checkedItems = [Item]()
    var checkedStartIndex: Int {
        items.count - checkedItems.count
    }
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
    var tappedCells: [UUID: Timer] = [:]
    var focusedTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "TodoCell", bundle: nil), forCellReuseIdentifier: "TodoCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        
        //Unfocus textfield when tapped below table
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(defocus))
        clearView.addGestureRecognizer(tap)
        
        setupBar()
    }
    
    //MARK: - Tableview datasource methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        let item = items[indexPath.row]
        cell.todoTextField.text = item.title
        cell.checked = item.done ? true : false
        if let color = parentCategory?.color {
            cell.cellView.backgroundColor = UIColor(named: color)
        }
        cell.cellView.layer.opacity = item.done ? 0.8 : 1.0
        cell.todoTextField.accessibilityIdentifier = item.id?.uuidString
        cell.todoTextField.delegate = self
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    // MARK: - Table view delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        item.done.toggle()
        let wasDone = item.done
        tableView.reloadData()
        saveItems()
        let id = item.id
        
        if tappedCells[id!] != nil {
                return
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
       
            guard let index = self.items.firstIndex(of: item), let item = self.items.first(where: {$0.id == item.id} ) else {
                self.tappedCells.removeValue(forKey: item.id!)
                return
            }
            
            if item.done != wasDone {
                self.tappedCells.removeValue(forKey: item.id!)
                return
            }

            if item.done {
                self.checkedItems.insert(item, at: 0)
                let newIndex = self.checkedStartIndex
                self.items.removeAll { $0.id == item.id }
                if !self.onHide {
                    if newIndex >= 0 {
                        self.items.insert(item, at: newIndex)
                        self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: newIndex, section: 0))
                    } else {
                        self.items.append(item)
                        self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: items.count - 1, section: 0))
                    }
                }
            } else {
                self.checkedItems.removeAll {
                    $0.id == item.id
                }
                let newIndex = self.checkedStartIndex >= 1 ? self.checkedStartIndex - 1 : 0
                self.items.removeAll { $0.id == item.id }
                self.items.insert(item, at: newIndex)
                self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: newIndex, section: 0))
            }
            self.updateIndices()
            self.tappedCells.removeValue(forKey: item.id!)
        }
        
        tappedCells[item.id!] = timer
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
        let item = items[sourceIndexPath.row]
        
        if onHide || (item.done && destinationIndexPath.row >= checkedStartIndex)
            || (!item.done && destinationIndexPath.row < checkedStartIndex) {
            let mover = items.remove(at: sourceIndexPath.row)
            items.insert(mover, at: destinationIndexPath.row)
            updateIndices()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
                tableView.moveRow(at: destinationIndexPath, to: sourceIndexPath)
            }
            
        }
    }
    
    //MARK: - Textfield delegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        focusedTextField = textField
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if  let id = textField.accessibilityIdentifier,
            let newText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            changeItem(id: id, text: newText)
        }
        view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if  let id = textField.accessibilityIdentifier,
            let newText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            changeItem(id: id, text: newText)
        }
        view.endEditing(true)
    }
    
    //MARK: - Tableview drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = items[indexPath.row]
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
            let allItems = try context.fetch(request)
            items = allItems.sorted(by: { $0.index < $1.index })
            checkedItems = items.filter{ $0.done }
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
    }
    
    func changeItem(id: String, text: String) {
        if !text.isEmpty {
            let itemToChange = items.first { $0.id?.uuidString == id}
            itemToChange?.title = text
            saveItems()
        }
        tableView.reloadData()
    }
    
    func deleteItem(at index: Int){
        
        let item = items[index]
        context.delete(items[index])
        items.remove(at: index)
        
        if item.done {
            checkedItems.removeAll { $0.id == item.id
            }
        }
        
        saveItems()
        tableView.reloadData()
        updateIndices()
    }
    
    func updateIndices(){
        var allItems: [Item] = items
        if onHide {
            allItems.append(contentsOf: checkedItems)
        }
        for i in 0..<items.count {
            items[i].index = Int16(i)
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
        var allItemNames = items.map { $0.title }
        let alert = UIAlertController(title: "Add New Todo Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            let itemTitle = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !itemTitle.isEmpty && !allItemNames.contains(itemTitle) {
                let newItem = Item(context: self.context)
                newItem.title = itemTitle
                newItem.done = false
                newItem.id = UUID()
                let newIndex = self.checkedStartIndex >= 0 ? self.checkedStartIndex : 0
                newItem.index = Int16(newIndex)
                newItem.parentCategory = self.parentCategory
                
                self.items.insert(newItem, at: newIndex)
                self.saveItems()
                self.tableView.reloadData()
                self.updateIndices()
            }
        }
        alert.addAction(action)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField.autocapitalizationType = .words
            alertTextField.autocorrectionType = .yes
            textField = alertTextField
        }
        present(alert, animated: true, completion: nil)
    }
    
    func show(){
        onHide = false
        items.append(contentsOf: checkedItems)
        tableView.reloadData()
    }
    
    func hide(){
        onHide = true
        items = items.filter{ !$0.done }
        tableView.reloadData()
    }
    
    func clear(from startIndex: Int = 0){
        if !onHide {
            items = items.filter{ !$0.done }
        }
        for item in checkedItems {
            context.delete(item)
        }
        saveItems()
        checkedItems = []
        tableView.reloadData()
    }
    
    //MARK: - Helper Methods
    @objc func defocus() {
        focusedTextField?.endEditing(true)
    }
}
