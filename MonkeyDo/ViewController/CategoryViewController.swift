//
//  CategroyViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

class CategoryViewController: UITableViewController, UITableViewDragDelegate, UITextFieldDelegate, ColorDelegate {
    @IBOutlet weak var clearView: UIView!
    
    var categories = [Category]()
    let colors = ["BlueColor", "PinkColor", "YellowColor", "PurpleColor", "MintColor"]
    var onEdit = false
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var focusedTextField: UITextField?

    
    //MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "CategoryCell", bundle: nil), forCellReuseIdentifier: "CategoryCell")
        tableView.register(UINib(nibName: "EditCategoryCell", bundle: nil), forCellReuseIdentifier: "EditCategoryCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        
        //Unfocus textfield when tapped below table
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(defocus))
        clearView.addGestureRecognizer(tap)
                
        //for debug:
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadCategories()
        if categories.isEmpty {
            performSegue(withIdentifier: "GoToCreateView", sender: self)
        }
        tableView.reloadData()
    }
    
    // MARK: - Tableview methods
    // datasource methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = CategoryCell()
        if !onEdit {
            cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            cell.label.text = categories[indexPath.row].name
            if let color = categories[indexPath.row].color {
                cell.numView.backgroundColor = UIColor(named: color)
            }
            let numItems = categories[indexPath.row].items?.count ?? 0
            cell.numLabel.text = String(numItems)
        }
        else {
            let editCell = tableView.dequeueReusableCell(withIdentifier: "EditCategoryCell", for: indexPath) as! EditCategoryCell
            editCell.configure(category: categories[indexPath.row])
            editCell.delegate = self
            editCell.categoryTextField.delegate = self
            return editCell
        }
        return cell
    }
    
    // tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !onEdit {
            performSegue(withIdentifier: "GoToList", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "delete") { [weak self] (action, view, completionHandler) in
            self?.deleteCategory(at: indexPath.row)
            completionHandler(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = categories.remove(at: sourceIndexPath.row)
        categories.insert(mover, at: destinationIndexPath.row)
        
        for i in 0..<categories.count {
            categories[i].index = Int16(i)
        }
        saveCategories()
    }
    
    //drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = categories[indexPath.row]
        return [dragItem]
    }
    
    //MARK: - Textfield delegate methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        focusedTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldDidEndEditing(textField)
        focusedTextField = nil
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if  let id = textField.accessibilityIdentifier,
            let index = Int(id),
            let newText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            changeCategory(index: index, text: newText)
        }
        view.endEditing(true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToList" {
            let destinationVC = segue.destination as! TodoListViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.parentCategory = categories[indexPath.row]
            }
        }
    }
    
    //MARK: - Button Function
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let listNames = categories.map { $0.name }
        let alert = UIAlertController(title: "Add new list", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add list", style: .default){ _ in
            let newListName = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !newListName.isEmpty && !listNames.contains(newListName){
                let newCategory = Category(context: self.context)
                newCategory.name = newListName
                let color = self.getColor()
                newCategory.color = color
                newCategory.index = Int16(self.categories.count)
                self.categories.append(newCategory)
                self.saveCategories()
            }
        }
        alert.addAction(action)
        alert.addTextField{ (alertTextField) in
            alertTextField.placeholder = "list name"
            alertTextField.autocapitalizationType = .sentences
            textField = alertTextField
        }
        present(alert, animated: true)
    }
    
    @IBAction func editButtonClicked(_ sender: UIBarButtonItem) {
        onEdit.toggle()
        tableView.reloadData()
    }
    
    
    //MARK: - Data manipulation methods
    
    func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()){
        do {
            let categories = try context.fetch(request)
            self.categories = categories.sorted(by: { $0.index < $1.index })
        } catch {
            print("Error fetching data from context: \(error)")
        }
        tableView.reloadData()
    }
    
    func saveCategories(){
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
        tableView.reloadData()
        
        if categories.isEmpty {
            performSegue(withIdentifier: "GoToCreateView", sender: self)
        }
    }
    
    func changeCategory(index: Int, text: String){
        categories[index].name = text
        saveCategories()
    }
    
    func changeColor(index: Int, color: String){
        categories[index].color = color
        saveCategories()
    }
    
    func deleteCategory(at index: Int){
        context.delete(categories[index])
        categories.remove(at: index)
        saveCategories()
    }
    
    //MARK: - Helper methods
    func getColor() -> String {
        let range = categories.isEmpty ? 0...4 : 0...3
        let randomIndex = Int.random(in: range)
        
        if categories.isEmpty {
            return colors[randomIndex]
        } else {
            let colors = self.colors.filter { color in
                color != categories.last?.color
            }
            return colors[randomIndex]
        }
    }
    
    @objc func defocus() {
        focusedTextField?.endEditing(true)
        if onEdit {
            onEdit.toggle()
            tableView.reloadData()
        }
    }
}
