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
import SystemConfiguration.CaptiveNetwork

class StartVC: UIViewController, CPTScatterPlotDataSource, CPTAxisDelegate, Rotatable  {
    
    private var scatterGraph : CPTXYGraph? = nil
    typealias plotDataType = [CPTScatterPlotField : Double]
    private var dataForPlotX = [plotDataType]()
    private var dataForPlotY = [plotDataType]()
    private var dataForPlotZ = [plotDataType]()

    var plotSpace: CPTXYPlotSpace?
    
    @IBOutlet weak var hostingView: CPTGraphHostingView!
    
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
   // var incoming: IncomingData
    var maxY = 3.0
    var minY = -0.2
    var X = 0.0
    var xContent = [plotDataType]()
    var yContent = [plotDataType]()
    var zContent = [plotDataType]()
    
    var counter = 0
    let dataLength = 512
    var rawData : [Byte]?
    
    let movingWindowLength = 80.0
    var xCounter = 0
    var lastX = 0
    
    // Create UDP socket that connects to address and port of ESP32 board
    let client = UDPClient(address: "192.168.4.1", port: 3333)
    
    var timerBackground : Timer?
    
    
    
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
        newGraph.paddingLeft   = 0.1
        newGraph.paddingRight  = 0.1
        newGraph.paddingTop    = 0.1
        newGraph.paddingBottom = 0.1
        
        // Plot space
        self.plotSpace = newGraph.defaultPlotSpace as? CPTXYPlotSpace
        self.plotSpace?.allowsUserInteraction = true
        self.plotSpace?.yRange = CPTPlotRange(location:-7, length:18.0)
        self.plotSpace?.xRange = CPTPlotRange(location:-10, length: NSNumber(value: movingWindowLength))
        
        // Axes
        let axisSet = newGraph.axisSet as! CPTXYAxisSet
        
        if let x = axisSet.xAxis {
            x.majorIntervalLength   = 15
            x.orthogonalPosition    = 0
            x.minorTicksPerInterval = 1
//            x.labelExclusionRanges  = [
//                CPTPlotRange(location: 0.99, length: 0.02),
//                CPTPlotRange(location: 1.99, length: 0.02),
//                CPTPlotRange(location: 2.99, length: 0.02)
//            ]
            x.delegate = self //this line was missing before
        }
        
        if let y = axisSet.yAxis {
            y.majorIntervalLength   = 5
            y.minorTicksPerInterval = 1
            y.orthogonalPosition    = 0
//            y.labelExclusionRanges  = [
//                CPTPlotRange(location: 0.99, length: 0.02),
//                CPTPlotRange(location: 1.99, length: 0.02),
//                CPTPlotRange(location: 3.99, length: 0.02)
//            ]
            y.delegate = self
        }
        
        //new blue plot (x)
        let xPlot = CPTScatterPlot(frame: .zero)
        let blueLineStyle = CPTMutableLineStyle()
        blueLineStyle.miterLimit    = 1.0
        blueLineStyle.lineWidth     = 1.0
        blueLineStyle.lineColor     = .blue()
        xPlot.dataLineStyle = blueLineStyle
        xPlot.identifier    = NSString.init(string: "xPlot")
        xPlot.dataSource    = self
        newGraph.add(xPlot)
        
        // Add plot symbols
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = .black()
        let plotSymbol = CPTPlotSymbol.ellipse()
        plotSymbol.fill          = CPTFill(color: .blue())
        plotSymbol.lineStyle     = symbolLineStyle
        plotSymbol.size          = CGSize(width: 1.0, height: 1.0)
        xPlot.plotSymbol = plotSymbol
        
        //new blue plot (y)
        let yPlot = CPTScatterPlot(frame: .zero)
        let greenLineStyle = CPTMutableLineStyle()
        greenLineStyle.miterLimit    = 1.0
        greenLineStyle.lineWidth     = 1.0
        greenLineStyle.lineColor     = .green()
        yPlot.dataLineStyle = greenLineStyle
        yPlot.identifier    = NSString.init(string: "yPlot")
        yPlot.dataSource    = self
        newGraph.add(yPlot)
        
        // Add plot symbols
        plotSymbol.fill          = CPTFill(color: .green())
        plotSymbol.lineStyle     = symbolLineStyle
        plotSymbol.size          = CGSize(width: 1.0, height: 1.0)
        yPlot.plotSymbol = plotSymbol
        
        //new blue plot (z)
        let zPlot = CPTScatterPlot(frame: .zero)
        let yellowLineStyle = CPTMutableLineStyle()
        yellowLineStyle.miterLimit    = 1.0
        yellowLineStyle.lineWidth     = 1.0
        yellowLineStyle.lineColor     = .yellow()
        zPlot.dataLineStyle = yellowLineStyle
        zPlot.identifier    = NSString.init(string: "zPlot")
        zPlot.dataSource    = self
        newGraph.add(zPlot)
        
        // Add plot symbols

        plotSymbol.fill          = CPTFill(color: .yellow())
        plotSymbol.lineStyle     = symbolLineStyle
        plotSymbol.size          = CGSize(width: 1.0, height: 1.0)
        zPlot.plotSymbol = plotSymbol
        
        self.scatterGraph = newGraph
        
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
        let ssid = self.getWiFiSsid()
        if (ssid != "guderesearch" && ssid != "guderesearch_USB") {
            let alertController = UIAlertController(title: "Wrong WiFi",
                                                    message: "Please connect to 'guderesearch' WiFi",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion:  nil)
        }
        else {
            print("Client address:  \(self.client.address)")
            // Send 'start' string for board to start sending data
            _ = self.client.send(string: "start")
            
            self.timerBackground = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                timerBackground in self.someBackgroundTask(timer: self.timerBackground!)
            }
            
        }
    }
    
    
    @IBAction func clearData(_ sender: Any) {
        //clear data in Plot
        print("Clear graph")
        self.X = 0
        self.xCounter = 0
        self.maxY = 0
        self.xContent.removeAll()
        self.yContent.removeAll()
        self.zContent.removeAll()
        self.dataForPlotX = self.xContent
        self.dataForPlotY = self.yContent
        self.dataForPlotZ = self.zContent
        self.plotSpace?.yRange = CPTPlotRange(location:-7, length:18.0)
        self.plotSpace?.xRange = CPTPlotRange(location:-10, length:100.0)
        self.scatterGraph?.reloadData()
    }
    
    @IBAction func stopPlotting(_ sender: Any) {
        // stop plotting data
        self.timerBackground?.invalidate()
        print("Stop plotting")
        _ = client.send(string: "stop")
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
    
    // MARK: - Refresh user
    func refresh() {
        self.user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async(execute: {
                self.response = task.result
                self.title = self.user?.username
            })
            return nil
        }
    }
    
    // MARK: - Plot incoming data
    func someBackgroundTask(timer:Timer) {
        var accelData: [Byte] = []; var soundData: [Byte] = []; var x: Double?; var y: Double?; var z: Double?
        print("do some background task")

        
        DispatchQueue.global(qos: DispatchQoS.default.qosClass).async {
            print("do some background task in async")
            let raw = self.client.recv(512)
            let printable = raw.0!
            print("Incoming raw data: \(String(describing: printable))")
            
            if (raw.0?.count == self.dataLength){
                accelData = Array(raw.0![0...5])
                soundData = Array(raw.0![6...self.dataLength-1])
            }
            
            if (accelData[0] > 99) {
                x = Double(100 - Double(accelData[0]) - (Double(accelData[1])-100)/100)
            } else {
                x = Double(Double(accelData[0]) - 1 + (Double(accelData[1])-100)/100)
            }
            if (accelData[2] > 99){
                y = Double(100 - Double(accelData[2]) - (Double(accelData[3])-100)/100)
            } else {
                y = Double(Double(accelData[2]) - 1 + (Double(accelData[3])-100)/100)
            }
            if (accelData[4] > 99){
                z = Double(100 - Double(accelData[4]) - (Double(accelData[5])-100)/100)
            } else {
                z = Double(Double(accelData[4]) - 1 + (Double(accelData[5])-100)/100)
            }

            print("Value of x: \(String(describing: x))")
            print("Value of y: \(String(describing: y))")
            print("Value of z: \(String(describing: z))")

            // add x,y,z to accelerometer plot
            let xDataPoint: plotDataType = [.X: self.X, .Y: x!]
            let yDataPoint: plotDataType = [.X: self.X, .Y: y!]
            let zDataPoint: plotDataType = [.X: self.X, .Y: z!]
            if (x! > self.maxY){self.maxY = x!}; if (y! > self.maxY){self.maxY = y!}; if (z! > self.maxY){self.maxY = z!}
            if (x! < self.minY){self.minY = x!}; if (y! < self.minY){self.minY = y!}; if (z! < self.minY){self.minY = z!}
            self.X = self.X + 1
            self.xContent.append(xDataPoint)
            self.yContent.append(yDataPoint)
            self.zContent.append(zDataPoint)
            
            // soundData to another plot
          /*  for i in 0...soundData.count {
                let dataPoint: plotDataType = [.X: self.X, .Y: Double(soundData[i])]
                //append dataPoint
                //do max and min values too
            }*/


        }
        
            DispatchQueue.main.async {
            print("update some UI")
                self.dataForPlotX = self.xContent
                self.dataForPlotY = self.yContent
                self.dataForPlotZ = self.zContent
                self.plotSpace?.yRange = CPTPlotRange(location:NSNumber(value: self.minY-3), length: NSNumber(value: 5+self.maxY+abs(self.minY)))
                if (self.X < 70) {
                    self.plotSpace?.xRange = CPTPlotRange(location:NSNumber(value: -7), length: NSNumber(value: self.movingWindowLength))
                } else {
                    
                    self.plotSpace?.xRange = CPTPlotRange(location:NSNumber(value: -7+self.xCounter), length: NSNumber(value: self.movingWindowLength))
                    self.xCounter = self.xCounter + 1
                }
                self.scatterGraph?.reloadData()
            }
        
    }
        
    // MARK: - Plot Data Source Methods
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(self.dataForPlotX.count)
    }
    
    func number(for plot: CPTPlot, field: UInt, record recordIndex: UInt) -> Any?
    {
        let plotField = CPTScatterPlotField(rawValue: Int(field))
        let plotID = plot.identifier as! String
        
        if (plotID == "xPlot") {
            return self.dataForPlotX[Int(recordIndex)][plotField!]! as NSNumber
        }
        if (plotID == "yPlot"){
            return self.dataForPlotY[Int(recordIndex)][plotField!]! as NSNumber
        }
        else {
            return self.dataForPlotZ[Int(recordIndex)][plotField!]! as NSNumber
        }

    }
    
//    func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any?
//    {
//        let plotField = CPTScatterPlotField(rawValue: Int(field))
//
//        if let num = self.dataForPlot[Int(record)][plotField!] {
//            let plotID = plot.identifier as! String
//            if (plotField! == .Y) && (plotID == "yPlot") {
//                return (num + 1.0) as NSNumber
//            }
//            else {
//                return num as NSNumber
//            }
//        }
//        else {
//            return nil
//        }
//    }
    
    // MARK: - Checking SSID of correct connection
    
    func getWiFiSsid() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
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

