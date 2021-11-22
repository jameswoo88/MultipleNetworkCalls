//
//  CustomTableViewCell.swift
//  MultipleNetworkCalls
//
//  Created by James Chun on 11/11/21.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    //MARK: - Outlets
    @IBOutlet weak var classicImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
