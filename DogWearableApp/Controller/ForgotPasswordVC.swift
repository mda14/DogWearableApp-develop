//
//  ForgotPasswordVC.swift
//  DogWearableApp
//
//  Created by Chispi on 06/02/2018.
//  Copyright © 2018 WearablesGuder. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

class ForgotPasswordVC: UIViewController {
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    @IBOutlet weak var username: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        self.hideKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newPasswordViewController = segue.destination as? ConfirmForgotPasswordVC {
            newPasswordViewController.user = self.user
        }
    }
    
    // MARK :- IBActions
    
    // handle forgot password
    
    @IBAction func forgotPassword(_ sender: AnyObject) {
        guard let username = self.username.text, !username.isEmpty else {
            
            let alertController = UIAlertController(title: "Missing UserName",
                                                    message: "Please enter a valid user name.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion:  nil)
            return
        }
        
        self.user = self.pool?.getUser(self.username.text!)
        self.user?.forgotPassword().continueWith{[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else {return nil}
            DispatchQueue.main.async(execute: {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    
                    self?.present(alertController, animated: true, completion:  nil)
                } else {
                    strongSelf.performSegue(withIdentifier: "confirmForgotPasswordVC", sender: sender)
                }
            })
            return nil
        }
    }
}


