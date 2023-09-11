//
//  CreateViewController.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 15.08.23.
//

import UIKit

class CreateViewController: UIViewController {

    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var createButtonView: UIView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var newCategory: Category?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Layout
        createButtonView.layer.borderWidth = 2
        createButtonView.layer.borderColor = UIColor(named: "PinkColor")?.cgColor
        createButtonView.layer.cornerRadius = 10
        navigationItem.hidesBackButton = true
    }
    
    @IBAction func createButtonClicked(_ sender: UIButton) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add new list", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add list", style: .default){ _ in
            if !textField.text!.isEmpty {
                let newCategory = Category(context: self.context)
                newCategory.name = textField.text!
                let color = Color.getColor()
                newCategory.color = color
                newCategory.index = 0
                self.saveCategory()
                self.navigationController?.popViewController(animated: false)
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
    
    func saveCategory(){
        do {
            try context.save()
        } catch {
            print("Error saving category: \(error)")
        }
    }
}
