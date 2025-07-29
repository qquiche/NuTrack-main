//
//  GenerateGoalsFormViewController.swift
//  NuTrack
//
//  Created by Zuhair Merali on 4/24/25.
//

import UIKit

protocol GenerateGoalsFormDelegate: AnyObject {
    func didCalculateGoals(calories: Int, protein: Int, carbs: Int, fats: Int)
}

class GenerateGoalsFormViewController: UIViewController {
    weak var delegate: GenerateGoalsFormDelegate?

    // UI Elements
    let weightLabel = UILabel()
    let weightField = UITextField()
    let heightLabel = UILabel()
    let heightButton = UIButton(type: .system)
    let heightPickerContainer = UIView()
    let feetPicker = UIPickerView()
    let inchesPicker = UIPickerView()
    let ageLabel = UILabel()
    let ageField = UITextField()
    let sexLabel = UILabel()
    let sexSegment = UISegmentedControl(items: ["Male", "Female"])
    let activityLabel = UILabel()
    let activityPicker = UIPickerView()
    let goalLabel = UILabel()
    let goalSegment = UISegmentedControl(items: ["Lose 0.5lb/wk", "Maintain", "Gain 0.5lb/wk"])
    let submitButton = UIButton(type: .system)

    let feetOptions = Array(4...7)
    let inchesOptions = Array(0...11)
    var selectedFeet = 5
    var selectedInches = 8

    let activityLevels = [
        "Sedentary (little/no exercise)",
        "Lightly active (1-3 days/week)",
        "Moderately active (3-5 days/week)",
        "Very active (6-7 days/week)",
        "Extra active (hard exercise/physical job)"
    ]
    let activityFactors: [Double] = [1.2, 1.375, 1.55, 1.725, 1.9]
    var selectedActivityIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        view.backgroundColor = .backgroundColors
        setupUI()
    }

    func setupUI() {
        // --- Labels ---
        weightLabel.text = "Weight (lbs)"
        weightLabel.font = .boldSystemFont(ofSize: 16)
        weightLabel.translatesAutoresizingMaskIntoConstraints = false
        weightLabel.textColor = .oppositeBackground
        
        heightLabel.text = "Height"
        heightLabel.font = .boldSystemFont(ofSize: 16)
        heightLabel.translatesAutoresizingMaskIntoConstraints = false
        heightLabel.textColor = .oppositeBackground

        ageLabel.text = "Age"
        ageLabel.font = .boldSystemFont(ofSize: 16)
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.textColor = .oppositeBackground

        sexLabel.text = "Sex"
        sexLabel.font = .boldSystemFont(ofSize: 16)
        sexLabel.translatesAutoresizingMaskIntoConstraints = false
        sexLabel.textColor = .oppositeBackground

        activityLabel.text = "Activity Level"
        activityLabel.font = .boldSystemFont(ofSize: 16)
        activityLabel.translatesAutoresizingMaskIntoConstraints = false
        activityLabel.textColor = .oppositeBackground

        goalLabel.text = "Goal"
        goalLabel.font = .boldSystemFont(ofSize: 16)
        goalLabel.translatesAutoresizingMaskIntoConstraints = false
        goalLabel.textColor = .oppositeBackground

        // --- Fields Setup ---
        [weightField, ageField].forEach {
            $0.borderStyle = .roundedRect
            $0.keyboardType = .decimalPad
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        weightField.placeholder = "Enter weight in lbs"
        weightField.backgroundColor = .white
        ageField.placeholder = "Enter age"
        ageField.backgroundColor = .white
        sexSegment.selectedSegmentIndex = 0
        sexSegment.translatesAutoresizingMaskIntoConstraints = false

        activityPicker.dataSource = self
        activityPicker.delegate = self
        activityPicker.translatesAutoresizingMaskIntoConstraints = false
        activityPicker.heightAnchor.constraint(equalToConstant: 100).isActive = true

        goalSegment.selectedSegmentIndex = 1
        goalSegment.translatesAutoresizingMaskIntoConstraints = false

        submitButton.setTitle("Calculate", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.layer.cornerRadius = 8
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.backgroundColor = .oppositeBackground
        submitButton.titleLabel?.textColor = .backgroundColors

        // --- Height Button and Picker ---
        heightButton.setTitle("\(selectedFeet) ft \(selectedInches) in", for: .normal)
        heightButton.titleLabel?.font = .systemFont(ofSize: 16)
        heightButton.setTitleColor(.oppositeBackground, for: .normal)
        heightButton.layer.borderWidth = 1
        heightButton.layer.borderColor = UIColor.systemGray4.cgColor
        heightButton.layer.cornerRadius = 6
        heightButton.translatesAutoresizingMaskIntoConstraints = false
        heightButton.addTarget(self, action: #selector(toggleHeightPicker), for: .touchUpInside)

        feetPicker.dataSource = self
        feetPicker.delegate = self
        feetPicker.tag = 1
        feetPicker.selectRow(selectedFeet - feetOptions.first!, inComponent: 0, animated: false)
        feetPicker.translatesAutoresizingMaskIntoConstraints = false

        inchesPicker.dataSource = self
        inchesPicker.delegate = self
        inchesPicker.tag = 2
        inchesPicker.selectRow(selectedInches, inComponent: 0, animated: false)
        inchesPicker.translatesAutoresizingMaskIntoConstraints = false

        // Height Picker Container
        heightPickerContainer.translatesAutoresizingMaskIntoConstraints = false
        heightPickerContainer.backgroundColor = .secondarySystemBackground
        heightPickerContainer.layer.cornerRadius = 8
        heightPickerContainer.isHidden = true

        let pickerStack = UIStackView(arrangedSubviews: [feetPicker, inchesPicker])
        pickerStack.axis = .horizontal
        pickerStack.spacing = 8
        pickerStack.alignment = .center
        pickerStack.distribution = .fillEqually
        pickerStack.translatesAutoresizingMaskIntoConstraints = false

        heightPickerContainer.addSubview(pickerStack)
        NSLayoutConstraint.activate([
            pickerStack.topAnchor.constraint(equalTo: heightPickerContainer.topAnchor, constant: 8),
            pickerStack.bottomAnchor.constraint(equalTo: heightPickerContainer.bottomAnchor, constant: -8),
            pickerStack.leadingAnchor.constraint(equalTo: heightPickerContainer.leadingAnchor, constant: 8),
            pickerStack.trailingAnchor.constraint(equalTo: heightPickerContainer.trailingAnchor, constant: -8),
            feetPicker.widthAnchor.constraint(equalToConstant: 70),
            inchesPicker.widthAnchor.constraint(equalToConstant: 70)
        ])

        // --- Main Stack ---
        let stack = UIStackView(arrangedSubviews: [
            weightLabel, weightField,
            heightLabel, heightButton, heightPickerContainer,
            ageLabel, ageField,
            sexLabel, sexSegment,
            activityLabel, activityPicker,
            goalLabel, goalSegment,
            submitButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            heightButton.heightAnchor.constraint(equalToConstant: 36),
            heightPickerContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    @objc func toggleHeightPicker() {
        heightPickerContainer.isHidden.toggle()
    }

    @objc func submitTapped() {
        guard
            let weightLbs = Double(weightField.text ?? ""),
            let age = Int(ageField.text ?? "")
        else {
            let alert = UIAlertController(title: "Error", message: "Please fill all fields correctly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Convert pounds to kg for calculation
        let weightKg = weightLbs * 0.453592

        // Convert feet/inches to centimeters
        let heightCm = Double(selectedFeet * 12 + selectedInches) * 2.54

        let isMale = sexSegment.selectedSegmentIndex == 0
        let activity = activityFactors[selectedActivityIndex]
        let goalIndex = goalSegment.selectedSegmentIndex

        // --- Calculate BMR ---
        let bmr: Double
        if isMale {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        } else {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        }

        // --- Calculate TDEE ---
        var tdee = bmr * activity
        if goalIndex == 0 { // Lose
            tdee -= 250
        } else if goalIndex == 2 { // Gain
            tdee += 250
        }
        let calories = Int(round(tdee))

        // --- Split into macros ---
        // Protein: 30%, Carbs: 40%, Fats: 30%
        let protein = Int(round((tdee * 0.25) / 4))
        let carbs = Int(round((tdee * 0.5) / 4))
        let fats = Int(round((tdee * 0.25) / 9))

        delegate?.didCalculateGoals(calories: calories, protein: protein, carbs: carbs, fats: fats)
        dismiss(animated: true)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension GenerateGoalsFormViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
            case 1: return feetOptions.count
            case 2: return inchesOptions.count
            default: return activityLevels.count
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
            case 1: return "\(feetOptions[row]) ft"
            case 2: return "\(inchesOptions[row]) in"
            default: return activityLevels[row]
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
            case 1:
                selectedFeet = feetOptions[row]
                heightButton.setTitle("\(selectedFeet) ft \(selectedInches) in", for: .normal)
            case 2:
                selectedInches = inchesOptions[row]
                heightButton.setTitle("\(selectedFeet) ft \(selectedInches) in", for: .normal)
            default:
                selectedActivityIndex = row
        }
    }
}
