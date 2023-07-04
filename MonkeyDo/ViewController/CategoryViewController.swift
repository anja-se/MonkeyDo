//
//  CategroyViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit
import CoreData

class CategoryViewController: UITableViewController, UITableViewDragDelegate {
    
    var categories = [Category]()
    let colors = ["BlueColor", "PinkColor", "YellowColor", "PurpleColor", "MintColor"]
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        tableView.register(UINib(nibName: "CategoryCell", bundle: nil), forCellReuseIdentifier: "CategoryCell")
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        //for debug
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    // MARK: - Tableview datasource methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        cell.label.text = categories[indexPath.row].name
        if let color = categories[indexPath.row].color {
            cell.numView.backgroundColor = UIColor(named: color)
        }
        let numItems = categories[indexPath.row].items?.count ?? 0
        cell.numLabel.text = String(numItems)

        return cell
    }
    
    
    // MARK: - Table view delegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "GoToList", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.parentCategory = categories[indexPath.row]
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
    
    //MARK: - Tableview drag delegate methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = categories[indexPath.row]
        return [dragItem]
    }
    
    // MARK: - Add new categories
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add new category", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add category", style: .default){ _ in
            if !textField.text!.isEmpty {
                let newCategory = Category(context: self.context)
                newCategory.name = textField.text!
                let color = self.getColor()
                newCategory.color = color
                newCategory.index = Int16(self.categories.count)
                self.categories.append(newCategory)
                self.saveCategories()
            }
        }
        alert.addAction(action)
        alert.addTextField{ (alertTextField) in
            alertTextField.placeholder = "Add new Category"
            textField = alertTextField
        }
        present(alert, animated: true)
    }
    
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
    }
    
    func deleteCategory(at index: Int){
        context.delete(categories[index])
        categories.remove(at: index)
        saveCategories()
    }
}
