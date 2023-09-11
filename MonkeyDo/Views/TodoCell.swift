//
//  TodoCell.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit

class TodoCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var checkView: UIView!
    @IBOutlet weak var checkImgView: UIImageView!
    @IBOutlet weak var todoTextField: UITextField!
    var checked = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.layer.cornerRadius = cellView.frame.height / 2
        cellView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        checkView.layer.cornerRadius = checkView.frame.height / 2
        checkImgView.isHidden = checked ? false : true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkImgView.isHidden = checked ? false : true
    }
    
    func configure(with item: Item) {
        todoTextField.text = item.title
        checked = item.done
        cellView.backgroundColor = UIColor(named: item.parentCategory!.color!)
        cellView.layer.opacity = item.done ? 0.8 : 1.0
        todoTextField.accessibilityIdentifier = item.id?.uuidString
    }
}
