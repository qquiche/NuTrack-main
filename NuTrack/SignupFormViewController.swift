//
//  SignupFormViewController.swift
//  NuTrack
//
//  Created by Rudy Caballero on 3/7/25.
//

import UIKit
import Firebase
import FirebaseAuth

class SignupFormViewController: UIViewController {

    @IBOutlet weak var caloriesSlider: UISlider!
    @IBOutlet weak var proteinSlider: UISlider!
    @IBOutlet weak var carbsSlider: UISlider!
    @IBOutlet weak var sugarsSlider: UISlider!
    @IBOutlet weak var fatsSlider: UISlider!
    @IBOutlet weak var nutsSegment: UISegmentedControl!
    @IBOutlet weak var dairySegment: UISegmentedControl!
    @IBOutlet weak var seafoodSegment: UISegmentedControl!
    let confirmInputSegue = "SigninUserSegue"
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var fatsLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    
    @IBOutlet weak var generateGoalsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        caloriesSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        proteinSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        carbsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        sugarsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        fatsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        updateAllLabels()
        
        var config = UIButton.Configuration.filled()
        config.title = "Generate Goals"
        config.baseBackgroundColor = .systemIndigo
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.buttonSize = .large

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        // Yellow star icon
        let yellowStar = UIImage(systemName: "star.fill", withConfiguration: symbolConfig)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        config.image = yellowStar
        config.imagePadding = 6
        config.imagePlacement = .leading

        let font = UIFont.boldSystemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        config.attributedTitle = AttributedString("Generate Goals", attributes: AttributeContainer(attributes))

        generateGoalsButton.configuration = config

        generateGoalsButton.layer.shadowColor = UIColor.systemIndigo.cgColor
        generateGoalsButton.layer.shadowOpacity = 0.3
        generateGoalsButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        generateGoalsButton.layer.shadowRadius = 10
    }
    
    
    @IBAction func generateGoalsButtonTapped(_ sender: UIButton) {
        
        presentGenerateGoalsForm()
    }
    
    func presentGenerateGoalsForm() {
        let formVC = GenerateGoalsFormViewController()
        formVC.delegate = self
        formVC.modalPresentationStyle = .formSheet // or .overCurrentContext for a true popup
        present(formVC, animated: true)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        print("Storing information in firebase")
        self.saveNameToFirestore(name: "Name")
        self.performSegue(withIdentifier: self.confirmInputSegue, sender: nil)
    }
    
    func saveNameToFirestore(name: String) {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }

        let userID = user.uid
        let db = Firestore.firestore()

        // Convert segmented control values to Bool
        let hasNutAllergy = nutsSegment.selectedSegmentIndex
        let hasDairyAllergy = dairySegment.selectedSegmentIndex
        let hasSeafoodAllergy = seafoodSegment.selectedSegmentIndex

        // Set the user data
        let userData: [String: Any] = [
            "name": name,
            "intakeGoals": [
                "calories": caloriesSlider.value,
                "protein": proteinSlider.value,
                "carbs": carbsSlider.value,
                "sugars": sugarsSlider.value,
                "fats": fatsSlider.value
            ],
            "allergies": [
                "nuts": hasNutAllergy,
                "dairy": hasDairyAllergy,
                "seafood": hasSeafoodAllergy
            ]
        ]

        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("User data successfully saved!")
            }
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        updateAllLabels()
    }
    
    func updateAllLabels() {
        caloriesLabel.text = "\(Int(caloriesSlider.value)) calories"
        proteinLabel.text = "\(Int(proteinSlider.value)) grams"
        carbsLabel.text = "\(Int(carbsSlider.value)) grams"
        sugarLabel.text = "\(Int(sugarsSlider.value)) grams"
        fatsLabel.text = "\(Int(fatsSlider.value)) grams"
    }
    
//    func saveNameToFirestore(name: String) {
//        if let user = Auth.auth().currentUser {
//            let userID = user.uid
//            let db = Firestore.firestore()
//            
//            let documentRef = db.collection("users").document(userID)
//            documentRef.setData([
//                "name": name
//            ]) { error in
//                if let error = error {
//                    print("Error adding document: \(error)")
//                } else {
//                    print("Document successfully added!")
//                }
//            }
//        } else {
//            print("User not authenticated.")
//        }
//    }
}

extension SignupFormViewController: GenerateGoalsFormDelegate {
    func didCalculateGoals(calories: Int, protein: Int, carbs: Int, fats: Int) {
        // Update sliders and labels
        caloriesSlider.value = Float(calories)
        proteinSlider.value = Float(protein)
        carbsSlider.value = Float(carbs)
        fatsSlider.value = Float(fats)
        updateAllLabels()
        // Save to Firestore
        saveGoalsToFirestore()
    }
    func saveGoalsToFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        let updatedGoals: [String: Int] = [
            "calories": Int(caloriesSlider.value),
            "protein": Int(proteinSlider.value),
            "carbs": Int(carbsSlider.value),
            "sugars": Int(sugarsSlider.value),
            "fats": Int(fatsSlider.value)
        ]
        userRef.setData(["intakeGoals": updatedGoals], merge: true)
    }
}
