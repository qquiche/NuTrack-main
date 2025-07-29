//
//  FoodLogInfoViewController.swift
//  NuTrack
//
//  Created by Ethan Benson on 4/25/25.
//

import UIKit

class FoodLogInfoViewController: UIViewController {
    var food: LoggedFood!
    @IBOutlet weak var foodLabel: UILabel!
    @IBOutlet weak var calorieLabel: UILabel!
    
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var carbLabel: UILabel!
    @IBOutlet weak var fatLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        foodLabel.text = food.name ?? "Name Not Found"
        calorieLabel.text = "\(food.calories/Double(food.quantity) ?? 0)"
        proteinLabel.text = "\(food.protein/Double(food.quantity) ?? 0) g"
        carbLabel.text = "\(food.carbs/Double(food.quantity) ?? 0) g"
        fatLabel.text = "\(food.fats/Double(food.quantity) ?? 0) g"
        sugarLabel.text = "\(food.sugars/Double(food.quantity) ?? 0) g"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
