//
//  CategoryCell.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 30.06.23.
//

import UIKit

class CategoryCell: UITableViewCell {
    
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var numView: UIView!
    @IBOutlet weak var numLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.layer.cornerRadius = cellView.frame.height / 2
        cellView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        numView.layer.cornerRadius = numView.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
