//
//  EditCategoryCell.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 29.08.23.
//

import UIKit

class EditCategoryCell: UITableViewCell {
    
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var purpleButton: UIButton!
    @IBOutlet weak var pinkButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var mintButton: UIButton!
    
    var allButtons: [UIView] {[blueButton, pinkButton, yellowButton, purpleButton, mintButton]}
    let colors = ["BlueColor", "PinkColor", "YellowColor", "PurpleColor", "MintColor"]
    var category: Category?
    var delegate: ColorDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func layout(){
        for view in allButtons {
            view.layer.cornerRadius = view.frame.height / 2
            view.layer.borderColor = UIColor(white: 0, alpha: 0.5).cgColor
            view.layer.borderWidth = 3
        }
    }

    func configure(category: Category) {
        self.category = category
        categoryTextField.text = category.name
        if let color = category.color {
            highlightButton(color: color)
        }
        categoryTextField.accessibilityIdentifier = String(category.index)
    }

    func highlightButton(color: String) {
        for button in allButtons {
            if button.accessibilityLabel == color {
                button.layer.borderColor = UIColor.white.cgColor
            } else {
                button.layer.borderColor = UIColor(white: 0, alpha: 0.5).cgColor
            }
        }
    }
    
    @IBAction func colorButtonPressed(_ sender: UIButton) {
    
        if let color = sender.accessibilityLabel, let category {
            highlightButton(color: color)
            delegate?.changeColor(index: Int(category.index), color: color)
        }
    }
}

protocol ColorDelegate {
    func changeColor(index: Int, color: String)
}
