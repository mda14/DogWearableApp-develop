//
//  StartVC.swift
//  DogWearableApp
//
//  Created by Chispi on 13/12/2017.
//  Copyright © 2017 WearablesGuder. All rights reserved.
//

import UIKit
import SwiftSocket
import AWSCognitoIdentityProvider

class StartVC: UIViewController  {
    @IBOutlet weak var StartBtn: UIButton!
    @IBOutlet weak var BackBtn: UIButton!
    @IBOutlet weak var ConnectBtn: UIButton!

    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        self.refresh()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func BackBtn(_ sender: Any) {
        print("Back Button")
    }
    
    @IBAction func connectToBoard(_ sender: Any) {
        print("ConnectToBoard")
        //check if user is connected to guderesearch WiFi
        //if not, promt user to connect

            }
    
    @IBAction func startUdpConnection(_ sender: Any) {

        // Create UDP socket that connects to address and port of ESP32 board
        let client = UDPClient(address: "192.168.4.1", port: 3333)
        print("Client address:  \(client.address)")
        client.enableBroadcast()

        // Send 'start' string for board to start sending data
        let data = "start" // ... Bytes you want to send
        let result = client.send(string: data)
        print("Result: \(result.isSuccess)")
        let incoming = client.recv(1024*10)
        // to view message printed need to decode
        let incoming_print = String(bytes: incoming.0!, encoding: String.Encoding.utf8)
        print("Data received: \(String(describing: incoming_print))")
    }
    
    func refresh() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                self.title = self.user?.username
            })
            return nil
        }
    }
    
}
