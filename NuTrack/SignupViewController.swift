//
//  SignupViewController.swift
//  NuTrack
//
//  Created by Rudy Caballero on 3/7/25.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var retypedField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    let segueIdentifier = "signupFormSegueIdentifier"
    var delegate: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        retypedField.isSecureTextEntry = true
        emailField.delegate = self
        passwordField.delegate = self
        retypedField.delegate = self
    }
    
    //    TODO check if either fields are blank???
    @IBAction func createButtonPressed(_ sender: Any) {
        self.view.endEditing(true)
        if passwordField.text! != self.retypedField.text {
            errorLabel.text = "Passwords do not match"
            return
        }
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) {
            (authResult,error) in
            if let error = error as NSError?{
                self.errorLabel.text = "\(error.localizedDescription)"
            } else {
                self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                self.errorLabel.text = ""
                self.emailField.text = ""
                self.passwordField.text = ""
                self.retypedField.text = ""
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
