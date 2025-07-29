//
//  LoginViewController.swift
//  NuTrack
//
//  Created by Rudy Caballero on 3/7/25.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    let loggedinSegue = "loggedinSegueIdentifier"
    let signupSegue = "signupSegueIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: self.loggedinSegue, sender: nil)
                self.emailField.text = nil
                self.passwordField.text = nil
            }
        }
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
//    TODO check if either fields are blank???
    @IBAction func loginButton(_ sender: Any) {
        self.view.endEditing(true)
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) {
            (authResult,error) in
            if let error = error as NSError?{
                self.errorLabel.text = "\(error.localizedDescription)"
            } else {
                self.errorLabel.text = ""
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == signupSegue,
           let nextVC = segue.destination as? SignupViewController {
            nextVC.delegate = self
        }
    }
}
