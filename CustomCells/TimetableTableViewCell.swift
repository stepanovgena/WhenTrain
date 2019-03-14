//
//  TimetableTableViewCell.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 14/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit

class TimetableTableViewCell: UITableViewCell {

  @IBOutlet weak var waitingTimeLabel: UILabel!
  @IBOutlet weak var arrivalTimeLabel: UILabel!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var departureTimeLabel: UILabel!
  @IBOutlet weak var threadTitleLabel: UILabel!
  
  
  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
