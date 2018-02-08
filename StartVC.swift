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
import CorePlot


class StartVC: UIViewController, CPTScatterPlotDataSource, CPTAxisDelegate, Rotatable  {
    
    private var scatterGraph : CPTXYGraph? = nil
    typealias plotDataType = [CPTScatterPlotField : Double]
    private var dataForPlot = [plotDataType]()
    
    @IBOutlet weak var hostingView: CPTGraphHostingView!
    
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
    
    // MARK: Initialization
    
    override func viewDidAppear(_ animated : Bool)
    {
        super.viewDidAppear(animated)
        
        // Create graph from theme
        let newGraph = CPTXYGraph(frame: .zero)
        newGraph.apply(CPTTheme(named: .darkGradientTheme))
        
        hostingView.hostedGraph = newGraph
        
        // Paddings
        newGraph.paddingLeft   = 1.0
        newGraph.paddingRight  = 1.0
        newGraph.paddingTop    = 1.0
        newGraph.paddingBottom = 1.0
        
        // Plot space
        let plotSpace = newGraph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = true
        plotSpace.yRange = CPTPlotRange(location:-0.1, length:2.0)
        plotSpace.xRange = CPTPlotRange(location:-0.1, length:3.0)
        
        // Axes
        let axisSet = newGraph.axisSet as! CPTXYAxisSet
        
        if let x = axisSet.xAxis {
            x.majorIntervalLength   = 0.5
            x.orthogonalPosition    = 0
            x.minorTicksPerInterval = 2
            x.labelExclusionRanges  = [
                CPTPlotRange(location: 0.99, length: 0.02),
                CPTPlotRange(location: 1.99, length: 0.02),
                CPTPlotRange(location: 2.99, length: 0.02)
            ]
        }
        
        if let y = axisSet.xAxis {
            y.majorIntervalLength   = 0.5
            y.minorTicksPerInterval = 5
            y.orthogonalPosition    = 0
            y.labelExclusionRanges  = [
                CPTPlotRange(location: 0.99, length: 0.02),
                CPTPlotRange(location: 1.99, length: 0.02),
                CPTPlotRange(location: 3.99, length: 0.02)
            ]
            y.delegate = self
        }
        
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParentViewController {
                resetToPortrait()
        }
    }
    
    
    //MARK - button functions
    
    @IBAction func startUdpConnection(_ sender: Any) {
        //check if user is connected to guderesearch WiFi
        //if not, promt user to connect
        
        
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
    
    
    @IBAction func clearData(_ sender: Any) {
        //clear data in Plot
    }
    
    @IBAction func stopPlotting(_ sender: Any) {
        // stop plotting data
    }
    
    @IBAction func saveData(_ sender: Any) {
        // save current plot into user data
    }
    
    @IBAction func signOut(_ sender: Any) {
       
        self.user?.signOut()
        self.title = nil
        self.response = nil
        self.refresh()
    
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
    
    // MARK: - Plot Data Source Methods
    
    func numberOfRecords(for plot: CPTPlot) -> UInt
    {
        return UInt(self.dataForPlot.count)
    }
    
    func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any?
    {
        let plotField = CPTScatterPlotField(rawValue: Int(field))
        
        if let num = self.dataForPlot[Int(record)][plotField!] {
            let plotID = plot.identifier as! String
            if (plotField! == .Y) && (plotID == "Green Plot") {
                return (num + 1.0) as NSNumber
            }
            else {
                return num as NSNumber
            }
        }
        else {
            return nil
        }
    }
    
    // MARK: - Axis Delegate Methods
    
    private func axis(_ axis: CPTAxis, shouldUpdateAxisLabelsAtLocations locations: NSSet!) -> Bool
    {
        if let formatter = axis.labelFormatter {
            let labelOffset = axis.labelOffset
            
            var newLabels = Set<CPTAxisLabel>()
            
            if let labelTextStyle = axis.labelTextStyle?.mutableCopy() as? CPTMutableTextStyle {
                for location in locations {
                    if let tickLocation = location as? NSNumber {
                        if tickLocation.doubleValue >= 0.0 {
                            labelTextStyle.color = .green()
                        }
                        else {
                            labelTextStyle.color = .red()
                        }
                        
                        let labelString   = formatter.string(for:tickLocation)
                        let newLabelLayer = CPTTextLayer(text: labelString, style: labelTextStyle)
                        
                        let newLabel = CPTAxisLabel(contentLayer: newLabelLayer)
                        newLabel.tickLocation = tickLocation
                        newLabel.offset       = labelOffset
                        
                        newLabels.insert(newLabel)
                    }
                }
                
                axis.axisLabels = newLabels
            }
        }
        
        return false
    }
}

protocol Rotatable: AnyObject {
    func resetToPortrait()
}
extension Rotatable where Self: UIViewController {
    func resetToPortrait() {
        UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
    }
}

