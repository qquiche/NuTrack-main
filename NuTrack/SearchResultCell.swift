//
//  SearchResultCell.swift
//  NuTrack
//
//  Created by Zuhair Merali on 3/9/25.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var foodImageView: UIImageView!
    
    let caloriesLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 1
            return label
        }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        foodNameLabel.numberOfLines = 0
        foodNameLabel.lineBreakMode = .byWordWrapping
        
        contentView.addSubview(caloriesLabel)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
                ])
                
                foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    foodNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                    foodNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                    foodNameLabel.trailingAnchor.constraint(equalTo: foodImageView.leadingAnchor, constant: -50),
                    foodNameLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -50)
                ])
        
        NSLayoutConstraint.activate([
                    caloriesLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    caloriesLabel.trailingAnchor.constraint(equalTo: foodImageView.leadingAnchor, constant: -8),
                    caloriesLabel.widthAnchor.constraint(equalToConstant: 50)
                ])

        
        foodImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                foodImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
                foodImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
                foodImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
                foodImageView.widthAnchor.constraint(equalToConstant: 120),
                foodImageView.heightAnchor.constraint(equalToConstant: 100)
            ])
    }
    
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
