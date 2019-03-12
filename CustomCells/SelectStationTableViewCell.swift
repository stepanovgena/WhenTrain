//
//  SelectStationTableViewCell.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 12/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit

class SelectStationTableViewCell: UITableViewCell {
  @IBOutlet weak var stationTitle: UILabel!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
