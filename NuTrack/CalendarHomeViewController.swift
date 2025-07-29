//
//  CalendarHomeViewController.swift
//  NuTrack
//
//  Created by Ethan Benson on 4/4/25.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


class CalendarHomeViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var caloriesProgress: UIProgressView!
    @IBOutlet weak var proteinProgress: UIProgressView!
    @IBOutlet weak var carbsProgress: UIProgressView!
    @IBOutlet weak var sugarsProgress: UIProgressView!
    @IBOutlet weak var fatsProgress: UIProgressView!
    
    @IBOutlet weak var nutritionStack: UIStackView!
    
    @IBOutlet weak var proteinlabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    @IBOutlet weak var fatsLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    var nutritionGoals: Personal?
    var nutritionIntake: Nutrition?

    override func viewDidLoad() {
            super.viewDidLoad()
            let date = datePicker.date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateKey = formatter.string(from: date)
            setupDatePicker()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FoodLogSegue",
           let destinationVC = segue.destination as? FoodLogTableViewController {
            destinationVC.selectedDate = self.datePicker.date
        }
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let date = datePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        loadInitialData()
        refreshData()
    }
    
    private func setupDatePicker() {
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }
    
    private func loadInitialData() {
        getPersonalData { [weak self] goals in
            self?.nutritionGoals = goals
            self?.refreshData()
        }
    }
    
    func refreshData() {
        getLogData(for: datePicker.date) { [weak self] log in
            self?.nutritionIntake = log
            self?.updateProgressBars()
        }
    }
        
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let date = datePicker.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        refreshData()
    }
  
        
        private func getPersonalData(completion: @escaping (Personal?) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion(nil)
                return
            }
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .getDocument { snapshot, error in
                    if let error = error {
                        print("Error fetching goals: \(error)")
                        completion(nil)
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    
                    do {
                        let goals = try snapshot.data(as: Personal.self)
                        completion(goals)
                    } catch {
                        print("Error decoding goals: \(error)")
                        completion(nil)
                    }
                }
        }
        
        private func getLogData(for date: Date, completion: @escaping (Nutrition?) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion(nil)
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateKey = formatter.string(from: date)
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .collection("logs")
                .document(dateKey)
                .getDocument { snapshot, error in
                    if let error = error {
                        print("Error fetching log: \(error)")
                        completion(nil)
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    
                    do {
                        let log = try snapshot.data(as: Nutrition.self)
                        completion(log)
                    } catch {
                        print("Error decoding log: \(error)")
                        completion(nil)
                    }
                }
        }
        
        func updateProgressBars() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let goals = self.nutritionGoals ?? Personal.defaultGoals()
                let intake = self.nutritionIntake ?? Nutrition.empty()
                
                let caloriePercentage = self.safeDivision(intake.calories, goals.calorieGoal)
                let proteinPercentage = self.safeDivision(intake.protein, goals.proteinGoal)
                let carbPercentage = self.safeDivision(intake.carbs, goals.carbGoal)
                let sugarPercentage = self.safeDivision(intake.sugars, goals.sugarGoal)
                let fatPercentage = self.safeDivision(intake.fats, goals.fatGoal)
                
                UIView.animate(withDuration: 0.7) {
                    self.caloriesProgress.progress = caloriePercentage
                    self.proteinProgress.progress = proteinPercentage
                    self.carbsProgress.progress = carbPercentage
                    self.sugarsProgress.progress = sugarPercentage
                    self.fatsProgress.progress = fatPercentage
                    
                    
                    self.caloriesLabel.text = "Calories: \(Int(intake.calories))/\(Int(goals.calorieGoal)) cals"
                    self.proteinlabel.text = "Protein: \(Int(intake.protein))/\(Int(goals.proteinGoal)) g"
                    self.carbsLabel.text = "Carbs: \(Int(intake.carbs))/\(Int(goals.carbGoal)) g"
                    self.sugarLabel.text = "Sugars: \(Int(intake.sugars))/\(Int(goals.sugarGoal)) g"
                    self.fatsLabel.text = "Fats: \(Int(intake.fats))/\(Int(goals.fatGoal)) g"

                }
            }
        }
        
    private func safeDivision(_ numerator: Double, _ denominator: Float) -> Float {
        guard denominator > 0 else { return 0.0 }
        return Float(numerator) / denominator
    }
        
    struct Nutrition: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let sugars: Double
        let fats: Double
        
        static func empty() -> Nutrition {
            return Nutrition(calories: 0, protein: 0, carbs: 0, sugars: 0, fats: 0)
        }
    }
        
        struct Personal: Codable {
            let name: String
            let intakeGoals: [String: Float]
            
            var calorieGoal: Float {
                return intakeGoals["calories"] ?? 2000
            }
            var proteinGoal: Float {
                return intakeGoals["protein"] ?? 50
            }
            var carbGoal: Float {
                return intakeGoals["carbs"] ?? 300
            }
            var sugarGoal: Float {
                return intakeGoals["sugars"] ?? 50
            }
            var fatGoal: Float {
                return intakeGoals["fats"] ?? 70
            }
            static func defaultGoals() -> Personal {
                return Personal(
                    name: "Default",
                    intakeGoals: [
                        "calories": 2000,
                        "protein": 50,
                        "carbs": 300,
                        "sugars": 50,
                        "fats": 70
                    ]
                )
            }
        }
    }

var dateKey: String = ""
