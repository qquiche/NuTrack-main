//
//  BarcodeNutritionFactsViewController.swift
//  NuTrack
//
//  Created by Anthony Rojas on 3/7/25.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import AudioToolbox

class BarcodeNutritionFactsViewController: UIViewController {
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var addToLogButton: UIButton!
    
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var calorieLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var carbLabel: UILabel!
    @IBOutlet weak var totalFatLabel: UILabel!
    @IBOutlet weak var satFatLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    @IBOutlet weak var fiberLabel: UILabel!
    @IBOutlet weak var sodiumLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    
    
    private let allergyService = AllergyDetectionService()
    
    
    var quantity: Int = 1
    var barcode: String!
    var food: Food!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        foodNameLabel.text = food.food_name ?? "Name Not Found"
        calorieLabel.text = "\(food.nf_calories ?? 0)"
        proteinLabel.text = "\(food.nf_protein ?? 0) g"
        carbLabel.text = "\(food.nf_total_carbohydrate ?? 0) g"
        totalFatLabel.text = "\(food.nf_total_fat ?? 0) g"
        satFatLabel.text = "\(food.nf_saturated_fat ?? 0) g"
        sugarLabel.text = "\(food.nf_sugars ?? 0) g"
        fiberLabel.text = "\(food.nf_dietary_fiber ?? 0) g"
        sodiumLabel.text = "\(food.nf_sodium ?? 0) mg"
        ingredientsLabel.text = "\(food.nf_ingredient_statement ?? "Not Available")"
        ingredientsLabel.lineBreakMode = .byWordWrapping
        
        
        quantityStepper.value = 1
        quantityStepper.minimumValue = 1
        quantityStepper.maximumValue = 10
        quantityStepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        
        quantityLabel.text = "QTY: 1"
        addToLogButton.setTitle("Add to Log", for: .normal)
        addToLogButton.addTarget(self, action: #selector(addToLogTapped), for: .touchUpInside)
        checkForAllergyConflicts()
    }
    
    @objc func stepperValueChanged(_ sender: UIStepper) {
        quantity = Int(sender.value)
        quantityLabel.text = "QTY: \(quantity)"
    }
    
    private func checkForAllergyConflicts() {
        guard let foodName = food.food_name, !foodName.isEmpty else { return }
        
        // Get the current user
        guard let user = Auth.auth().currentUser else { return }
        
        // Get user's allergy settings from Firestore
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user allergies: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists, let allergies = document.data()?["allergies"] as? [String: Int] {
                // Check for conflicts between user allergies and food
                self.allergyService.checkAllergyConflicts(foodName: foodName, userAllergies: allergies) { conflicts, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error checking allergies: \(error.localizedDescription)")
                            return
                        }
                        
                        if let conflicts = conflicts, !conflicts.isEmpty {
                            // Show allergy warning
                            self.showAllergyWarning(allergens: conflicts)
                        }
                    }
                }
            }
        }
    }
    
    // Add this method to show the allergy warning
    private func showAllergyWarning(allergens: [String]) {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        let formattedAllergens = allergens.map { $0.capitalized }.joined(separator: ", ")
        let alert = UIAlertController(
            title: "⚠️ Allergy Warning",
            message: "This food may contain \(formattedAllergens), which you've indicated you're allergic to.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    @objc func addToLogTapped() {
        // Make sure we have food data
        guard let food = food else {
            showAlert(title: "Error", message: "No food data")
            return
        }
        
        // Get the selected date from the date picker
        let selectedDate = datePicker.date
        
        // Format the date as a string key (yyyy-MM-dd) for Firebase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: selectedDate)
        
        // Calculate nutrition values based on quantity and round to 2 decimal places
        let calories = round((food.nf_calories ?? 0) * Double(quantity) * 100) / 100
        let protein = round((food.nf_protein ?? 0) * Double(quantity) * 100) / 100
        let carbs = round((food.nf_total_carbohydrate ?? 0) * Double(quantity) * 100) / 100
        let sugars = round((food.nf_sugars ?? 0) * Double(quantity) * 100) / 100
        let fats = round((food.nf_total_fat ?? 0) * Double(quantity) * 100) / 100
        
        
        // Call the method to add the food to the log
        addFoodToLog(dateKey: dateKey, calories: calories, protein: protein, carbs: carbs, sugars: sugars, fats: fats)
    }
    
    
    // Method to add the food to the Firebase log
    func addFoodToLog(dateKey: String, calories: Double, protein: Double, carbs: Double, sugars: Double, fats: Double) {
        // Make sure the user is logged in
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "You must be logged in to add foods to your log")
            return
        }
        
        // Get a reference to the Firestore database
        let db = Firestore.firestore()
        // Create a reference to the document for this specific date in the user's logs
        let logRef = db.collection("users").document(user.uid).collection("logs").document(dateKey)
        
        // Truncate the values to 2 decimal places before adding them to the log
        let truncatedCalories = truncateToDecimalPlaces(calories, decimalPlaces: 2)
        let truncatedProtein = truncateToDecimalPlaces(protein, decimalPlaces: 2)
        let truncatedCarbs = truncateToDecimalPlaces(carbs, decimalPlaces: 2)
        let truncatedSugars = truncateToDecimalPlaces(sugars, decimalPlaces: 2)
        let truncatedFats = truncateToDecimalPlaces(fats, decimalPlaces: 2)

        // Check if there's already a log for this date
        logRef.getDocument { [weak self] (document, error) in
            // Handle any errors that occur when fetching the document
            if let error = error {
                self?.showAlert(title: "Error", message: "Failed to check existing log: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                // Try to decode the existing data
                if let data = try? document.data(as: Nutrition.self) {
                    // Add the new nutrition values to the existing ones
                    let updatedCalories = self?.truncateToDecimalPlaces(data.calories + truncatedCalories, decimalPlaces: 2)
                    let updatedProtein = self?.truncateToDecimalPlaces(data.protein + truncatedProtein, decimalPlaces: 2)
                    let updatedCarbs = self?.truncateToDecimalPlaces(data.carbs + truncatedCarbs, decimalPlaces: 2)
                    let updatedSugars = self?.truncateToDecimalPlaces(data.sugars + truncatedSugars, decimalPlaces: 2)
                    let updatedFats = self?.truncateToDecimalPlaces(data.fats + truncatedFats, decimalPlaces: 2)
                    
                    let updatedData: [String: Double?] = [
                        "calories": updatedCalories,
                        "protein": updatedProtein,
                        "carbs": updatedCarbs,
                        "sugars": updatedSugars,
                        "fats": updatedFats
                    ]
                    
                    // Update the document in Firebase
                    logRef.updateData(updatedData) { error in
                        if let error = error {
                            self?.showAlert(title: "Error", message: "Failed to update log: \(error.localizedDescription)")
                        } else {
                            self?.navigationController?.popViewController(animated: true)
                            self?.showAlert(title: "Success", message: "Food added to log for \(dateKey)")

                            self?.addFoodEntryDocument(
                                db: db,
                                userId: user.uid,
                                dateKey: dateKey,
                                food: self?.food ?? Food(food_name: nil, brand_name: "Unknown", serving_qty: nil, serving_unit: nil, serving_weight_grams: nil, nf_metric_qty: nil, nf_metric_uom: nil, nf_calories: nil, nf_total_fat: nil, nf_saturated_fat: nil, nf_sodium: nil, nf_total_carbohydrate: nil, nf_protein: nil, nf_dietary_fiber: nil, nf_sugars: nil, nf_potassium: nil, nf_ingredient_statement: nil, photo: nil, nix_item_id: nil),
                                quantity: self?.quantity ?? 1
                            )
                        }
                    }
                }
            } else {
                // If no existing log, create a new one
                let newLog = Nutrition(calories: truncatedCalories, protein: truncatedProtein, carbs: truncatedCarbs, sugars: truncatedSugars, fats: truncatedFats)
                
                do {
                    try logRef.setData(from: newLog) { error in
                        if let error = error {
                            self?.showAlert(title: "Error", message: "Failed to create log: \(error.localizedDescription)")
                        } else {
                            self?.navigationController?.popViewController(animated: true)
                            self?.showAlert(title: "Success", message: "Food added to log for \(dateKey)")

                            self?.addFoodEntryDocument(
                                db: db,
                                userId: user.uid,
                                dateKey: dateKey,
                                food: self?.food ?? Food(food_name: nil, brand_name: "Unknown", serving_qty: nil, serving_unit: nil, serving_weight_grams: nil, nf_metric_qty: nil, nf_metric_uom: nil, nf_calories: nil, nf_total_fat: nil, nf_saturated_fat: nil, nf_sodium: nil, nf_total_carbohydrate: nil, nf_protein: nil, nf_dietary_fiber: nil, nf_sugars: nil, nf_potassium: nil, nf_ingredient_statement: nil, photo: nil, nix_item_id: nil),
                                quantity: self?.quantity ?? 1
                            )
                        }
                    }
                } catch {
                    self?.showAlert(title: "Error", message: "Failed to encode log data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper method to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func addFoodEntryDocument(db: Firestore, userId: String, dateKey: String, food: Food, quantity: Int) {
        let foodEntryRef = db.collection("users")
            .document(userId)
            .collection("logs")
            .document(dateKey)
            .collection("foods")
            .document()
        
        // Calculate the total values based on quantity and truncate them
        let calories = truncateToDecimalPlaces((food.nf_calories ?? 0) * Double(quantity), decimalPlaces: 2)
        let protein = truncateToDecimalPlaces((food.nf_protein ?? 0) * Double(quantity), decimalPlaces: 2)
        let carbs = truncateToDecimalPlaces((food.nf_total_carbohydrate ?? 0) * Double(quantity), decimalPlaces: 2)
        let sugars = truncateToDecimalPlaces((food.nf_sugars ?? 0) * Double(quantity), decimalPlaces: 2)
        let fats = truncateToDecimalPlaces((food.nf_total_fat ?? 0) * Double(quantity), decimalPlaces: 2)
        
        let foodData: [String: Any] = [
            "name": food.food_name ?? "Unknown",
            "quantity": quantity,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "sugars": sugars,
            "fats": fats,
            "photo": (food.photo?.thumb ?? ""),
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        foodEntryRef.setData(foodData) { error in
            if let error = error {
                print("Failed to add individual food entry: \(error.localizedDescription)")
            } else {
                print("Added food entry to \(dateKey) subcollection.")
            }
        }
    }
    
    func truncateToDecimalPlaces(_ value: Double, decimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(decimalPlaces))
        return floor(value * divisor) / divisor
    }
    
    
    
    //Testing
    func fetchLog(for dateKey: String) {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let logRef = db.collection("users").document(user.uid).collection("logs").document(dateKey)
        
        logRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching document for date \(dateKey): \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let data = try? document.data(as: Nutrition.self) {
                    print("Log for date \(dateKey):")
                    print("Calories: \(data.calories)")
                    print("Protein: \(data.protein)")
                    print("Carbs: \(data.carbs)")
                    print("Sugars: \(data.sugars)")
                    print("Fats: \(data.fats)")
                } else {
                    print("Failed to decode Nutrition data.")
                }
            } else {
                print("No log found for date \(dateKey).")
            }
        }
    }
    
    
    // Nutrition struct for encoding/decoding Firebase data
    //   struct Nutrition: Codable {
    //       let calories: Int
    //       let protein: Int
    //       let carbs: Int
    //       let sugars: Int
    //       let fats: Int
    //   }
    struct Nutrition: Codable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let sugars: Double
        let fats: Double
    }
    
}
