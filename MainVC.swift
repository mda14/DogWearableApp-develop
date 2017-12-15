//
//  ViewController.swift
//  DogWearableApp
//
//  Created by mda14 on 09/11/2017.
//  Copyright © 2017 WearablesGuder. All rights reserved.
//

import UIKit

class MainVC: UIViewController {

    @IBOutlet weak var OwnerBtn: UIButton!
    @IBOutlet weak var VetBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func VetBtn(_ sender: Any) {
    }
    
    @IBAction func OwnerBtn(_ sender: Any) {
    }
    
    @IBAction func unwindToUI1(unwindSegue: UIStoryboardSegue) {
        
    }
    
}

