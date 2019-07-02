//
//  TableViewCell.swift
//  listview
//
//  Created by HeejaeKim on 02/07/2019.
//  Copyright © 2019 HeejaeKim. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet var icon: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var changeRate: UILabel!
    @IBOutlet var price: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
