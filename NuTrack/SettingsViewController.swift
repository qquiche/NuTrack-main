//
//  SettingsViewController.swift
//  NuTrack
//
//  Created by Rudy Caballero on 3/5/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SettingsViewController: UIViewController {
    @IBOutlet weak var themeControl: UISegmentedControl!
    
    @IBOutlet weak var caloriesSlider: UISlider!
    @IBOutlet weak var proteinSlider: UISlider!
    @IBOutlet weak var carbsSlider: UISlider!
    @IBOutlet weak var sugarsSlider: UISlider!
    @IBOutlet weak var fatsSlider: UISlider!
    @IBOutlet weak var nutsSegment: UISegmentedControl!
    @IBOutlet weak var dairySegment: UISegmentedControl!
    @IBOutlet weak var seafoodSegment: UISegmentedControl!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var proteinLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    @IBOutlet weak var fatsLabel: UILabel!
    
    @IBOutlet weak var generateGoalsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        caloriesSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        proteinSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        carbsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        sugarsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        fatsSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        nutsSegment.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        dairySegment.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        seafoodSegment.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
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

    
    // Applies the settings whenever this page becomes visible
    private func applySettings() {
        themeControl.selectedSegmentIndex = getAppTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserGoals()
        applySettings()
    }
    
    // load currently stores goals
    private func loadUserGoals() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let goals = document.data()?["intakeGoals"] as? [String: Float] {
                    self.caloriesSlider.value = goals["calories"] ?? 0
                    self.proteinSlider.value = goals["protein"] ?? 0
                    self.carbsSlider.value = goals["carbs"] ?? 0
                    self.sugarsSlider.value = goals["sugars"] ?? 0
                    self.fatsSlider.value = goals["fats"] ?? 0
                }
                if let goals = document.data()?["allergies"] as? [String: Int] {
                    self.dairySegment.selectedSegmentIndex = goals["dairy"] ?? 1
                    self.nutsSegment.selectedSegmentIndex = goals["nuts"] ?? 1
                    self.seafoodSegment.selectedSegmentIndex = goals["seafood"] ?? 1
                }
                self.updateAllLabels()
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    
    private func updateAllLabels() {
        caloriesLabel.text = "\(Int(caloriesSlider.value)) calories"
        proteinLabel.text = "\(Int(proteinSlider.value)) grams"
        carbsLabel.text = "\(Int(carbsSlider.value)) grams"
        sugarLabel.text = "\(Int(sugarsSlider.value)) grams"
        fatsLabel.text = "\(Int(fatsSlider.value)) grams"
    }
    
    @IBAction func themeChanged(_ sender: Any) {
        setAppTheme(setting: themeControl.selectedSegmentIndex)
    }
    
    @IBAction func signOutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("sign out")
        } catch {
            print("sign out error")
            let controller = UIAlertController(
                title:  "Sign out Error",
                message: "Please try again",
                preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "OK", style: .default))
            present(controller, animated: true)
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
       updateAllLabels()
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

       userRef.setData(["intakeGoals": updatedGoals], merge: true) { error in
           if let error = error {
               print("Error updating intake goals: \(error.localizedDescription)")
           } else {
               print("Intake goals updated.")
           }
       }
   }
    
    @objc func segmentValueChanged(_ sender: UISegmentedControl) {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        let updatedAllergies: [String: Int] = [
            "nuts": nutsSegment.selectedSegmentIndex,
            "dairy": dairySegment.selectedSegmentIndex,
            "seafood": seafoodSegment.selectedSegmentIndex
        ]

        userRef.setData(["allergies": updatedAllergies], merge: true) { error in
            if let error = error {
                print("Error updating intake goals: \(error.localizedDescription)")
            } else {
                print("Intake goals updated.")
            }
        }
    }

}

extension SettingsViewController: GenerateGoalsFormDelegate {
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

