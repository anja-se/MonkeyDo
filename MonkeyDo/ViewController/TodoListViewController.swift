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
    @IBOutlet weak var emptyButtonView: UIView!
    @IBOutlet weak var clearView: UIView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var items = [Item]()
    var checkedItems = [Item]()
    var insertIndex: Int {
        onHide ? items.count : items.count - checkedItems.count
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
    
    
    //MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "TodoCell", bundle: nil), forCellReuseIdentifier: "TodoCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        
        //Unfocus textfield when tapped below table
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(defocus))
        clearView.addGestureRecognizer(tap)
        
        setupBar()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldDisplayButton()
    }
    
    //MARK: - Tableview methods
    //datasource methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        let item = items[indexPath.row]
        cell.configure(with: item)
        cell.todoTextField.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    //Table view delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        item.done.toggle()
        tableView.reloadData()
        let wasDone = item.done
        saveItems()
        
        if tappedCells[item.id!] != nil {
                return
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            guard let index = self.items.firstIndex(of: item), let item = self.items.first(where: {$0.id == item.id} ) else {
                self.tappedCells.removeValue(forKey: item.id!)
                return
            }
            //case: user undid selection
            if item.done != wasDone {
                self.tappedCells.removeValue(forKey: item.id!)
                return
            }
            //case: item is still selected
            if item.done {
                self.items.removeAll { $0.id == item.id }
                if self.onHide {
                    self.checkedItems.insert(item, at: 0)
                    tableView.reloadData()
                }
                else {
                    self.items.insert(item, at: self.insertIndex)
                    self.checkedItems.insert(item, at: 0)
                    self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: self.insertIndex, section: 0))
                }
            } else {
                self.tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: self.insertIndex, section: 0))
                self.checkedItems.removeAll {
                    $0.id == item.id
                }
                self.items.removeAll { $0.id == item.id }
                self.items.insert(item, at: self.insertIndex)
                
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
        
        if onHide || (item.done && destinationIndexPath.row >= insertIndex)
            || (!item.done && destinationIndexPath.row < insertIndex) {
            let mover = items.remove(at: sourceIndexPath.row)
            items.insert(mover, at: destinationIndexPath.row)
            updateIndices()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
                tableView.moveRow(at: destinationIndexPath, to: sourceIndexPath)
            }
        }
    }
    
    //drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = items[indexPath.row]
        return [dragItem]
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
    
    // MARK: - Data manipulation methods
    func loadItems(){
        let request = Item.fetchRequest()
        request.predicate = NSPredicate(format: "parentCategory.name MATCHES %@", parentCategory!.name!)
        
        do {
            let allItems = try context.fetch(request)
            items = allItems.sorted(by: { $0.index < $1.index })
            checkedItems = items.filter{ $0.done }
        } catch {
            print("Error fetching data from context: \(error)")
        }
        if parentCategory!.hidesCompleted {
            hide()
        } else {
            tableView.reloadData()
        }
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        shouldDisplayButton()
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
    
    func updateCategory() {
        parentCategory?.hidesCompleted = onHide
        saveItems()
    }
    
    //MARK: - Bar and Menu Configuration
    func setupBar() {
        menutItem.tintColor = UIColor(named: "PinkColor")
        self.navigationItem.rightBarButtonItems = [menutItem, addButton]
        
        hideAction = UIAction(title: "Hide completed", image: UIImage(systemName: "eye.slash")) { action in
            self.hide()
            self.updateCategory()
            self.updateMenu()
        }
        showAction = UIAction(title: "Show completed", image: UIImage(systemName: "eye")) { action in
            self.show()
            self.updateCategory()
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
    
    // MARK: - Layout
    func layout() {
        emptyButtonView.layer.borderWidth = 2
        emptyButtonView.layer.borderColor = UIColor(named: "PinkColor")?.cgColor
        emptyButtonView.layer.cornerRadius = 10
    }
    
    func shouldDisplayButton() {
        //called in viewWillAppear and saveItems
        emptyButtonView.isHidden = !items.isEmpty
    }
    
    // MARK: - Add, clear, show, hide
    @IBAction func addItem() {
        var textField = UITextField()
        var allItemNames = items.map { $0.title }
        let alert = UIAlertController(title: "Add New Todo Item", message: "", preferredStyle: .alert)
        
        let addItemAction = UIAlertAction(title: "Add Item", style: .default) { (action) in
            let itemTitle = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !itemTitle.isEmpty && !allItemNames.contains(itemTitle) {
                let newItem = Item(context: self.context)
                newItem.title = itemTitle
                newItem.done = false
                newItem.id = UUID()
                newItem.index = Int16(self.insertIndex)
                newItem.parentCategory = self.parentCategory
                
                self.items.insert(newItem, at: self.insertIndex)
                self.saveItems()
                self.tableView.reloadData()
                self.updateIndices()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(addItemAction)
        alert.addAction(cancelAction)
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
