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
    // variables for graphs
    private var scatterGraph : CPTXYGraph? = nil
    private var scatterGraphSound : CPTXYGraph? = nil
    typealias plotDataType = [CPTScatterPlotField : Double]
    private var dataForPlotX = [plotDataType]()
    private var dataForPlotY = [plotDataType]()
    private var dataForPlotZ = [plotDataType]()
    private var dataForPlotSound = [plotDataType]()

    var plotSpace: CPTXYPlotSpace?
    var plotSpaceSound: CPTXYPlotSpace?
    
    @IBOutlet weak var hostingView: CPTGraphHostingView!
    @IBOutlet weak var hostingViewSound: CPTGraphHostingView!
    
    @IBOutlet weak var predictedLabel: UITextField!
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    
   // variables for plotting
    var maxY = 3.0
    var minY = -0.2
    var X = 0.0
    var xContent = [plotDataType]()
    var yContent = [plotDataType]()
    var zContent = [plotDataType]()
    
    var maxYsound = 50.0
    var minYsound = -2.0
    var soundContent = [plotDataType]()
    
    let dataLength = 512
    var rawData : [Byte]?
    let movingWindowLength = 80.0
    var xCounter = 0
    var xCounterSound = 0
    
    // variables for passing data to prediction function
    
    var x_buffer = [Double] ()
    var x_temp = Double()
    var y_buffer = [Double] ()
    var y_temp = Double ()
    var z_buffer = [Double] ()
    var z_temp = Double()
    // windowing variable (determines size of buffers)
    var n = 5
    
    // Create UDP socket that connects to address and port of ESP32 board
    let client = UDPClient(address: "192.168.4.1", port: 3333)
    
    var timerBackground : Timer?
    var timerPredictionBackground : Timer?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        self.refresh()
    }
    
    // MARK: Initialization of graphs area
    
    override func viewDidAppear(_ animated : Bool)
    {
        super.viewDidAppear(animated)
        
        // Create graph from theme - accelerometer
        let newGraph = CPTXYGraph(frame: .zero)
        newGraph.apply(CPTTheme(named: .darkGradientTheme))
        // Create graph for soundData
        let newGraphSound = CPTXYGraph(frame: .zero)
        newGraphSound.apply(CPTTheme(named: .darkGradientTheme))
        
        hostingView.hostedGraph = newGraph
        hostingViewSound.hostedGraph = newGraphSound
        
        // Paddings
        newGraph.paddingLeft   = 0.1; newGraphSound.paddingLeft = 0.1
        newGraph.paddingRight  = 0.1; newGraphSound.paddingRight = 0.1
        newGraph.paddingTop    = 0.1; newGraphSound.paddingTop = 0.1
        newGraph.paddingBottom = 0.1; newGraphSound.paddingBottom = 0.1
        
        // Plot space for accelerometer
        self.plotSpace = newGraph.defaultPlotSpace as? CPTXYPlotSpace
        self.plotSpace?.allowsUserInteraction = true
        self.plotSpace?.yRange = CPTPlotRange(location:-7, length:18.0)
        self.plotSpace?.xRange = CPTPlotRange(location:-10, length: NSNumber(value: movingWindowLength))
        
        // Plot space for sound graph
        self.plotSpaceSound = newGraphSound.defaultPlotSpace as? CPTXYPlotSpace
        self.plotSpaceSound?.allowsUserInteraction = true
        self.plotSpaceSound?.yRange = CPTPlotRange(location:-7, length:18)
        self.plotSpaceSound?.xRange = CPTPlotRange(location:-10, length: 80)
        
        // Axes for accelerometer
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
            x.delegate = self
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
        
        // Axes for sound plot
        let axisSetSound = newGraphSound.axisSet as! CPTXYAxisSet
        
        if let x = axisSetSound.xAxis {
            x.majorIntervalLength   = 100
            x.orthogonalPosition    = 0
            x.minorTicksPerInterval = 1
            //            x.labelExclusionRanges  = [
            //                CPTPlotRange(location: 0.99, length: 0.02),
            //                CPTPlotRange(location: 1.99, length: 0.02),
            //                CPTPlotRange(location: 2.99, length: 0.02)
            //            ]
            x.delegate = self
        }
        
        if let y = axisSetSound.yAxis {
            y.majorIntervalLength   = 100
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
        
        //sound plot
        let soundPlot = CPTScatterPlot(frame: .zero)
        let soundLineStyle = CPTMutableLineStyle()
        soundLineStyle.miterLimit    = 1.0
        soundLineStyle.lineWidth     = 1.0
        soundLineStyle.lineColor     = .white()
        soundPlot.dataLineStyle = soundLineStyle
        soundPlot.identifier    = NSString.init(string: "soundPlot")
        soundPlot.dataSource    = self
        newGraphSound.add(soundPlot)
        // Add plot symbols
        plotSymbol.fill          = CPTFill(color: .yellow())
        plotSymbol.lineStyle     = symbolLineStyle
        plotSymbol.size          = CGSize(width: 1.0, height: 1.0)
        soundPlot.plotSymbol = plotSymbol
        
        self.scatterGraph = newGraph
        self.scatterGraphSound = newGraphSound
        
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
            // 0.066 works
            self.timerBackground = Timer.scheduledTimer(withTimeInterval: 0.066, repeats: true) {
                timerBackground in let (x_temp, y_temp, z_temp) = self.someBackgroundTask(timer: self.timerBackground!)
                self.x_buffer.append(x_temp); self.y_buffer.append(y_temp); self.z_buffer.append(z_temp)
                print(x_temp, y_temp, z_temp)
                print("Size of buffer:", self.x_buffer.count)
                if(self.x_buffer.count == self.n) {
                    let output = self.accelerationPrediction(x: self.x_buffer, y: self.y_buffer, z: self.z_buffer)
                    print("done accelerationPrediction")
                    let text = "Predicted: " + String(output)
                    self.predictedLabel.text = text
                    self.x_buffer.removeAll(); self.y_buffer.removeAll(); self.z_buffer.removeAll()
                }
            }
            
            
        }
    }
    
    
    @IBAction func clearData(_ sender: Any) {
        //clear data in Plot
        print("Clear graph")
        self.X = 0
        self.xCounter = 0
        self.maxY = 0
        self.minY = -2
        self.maxYsound = 0
        self.minYsound = -2
        self.xCounterSound = 0
        
        self.xContent.removeAll()
        self.yContent.removeAll()
        self.zContent.removeAll()
        self.soundContent.removeAll()
        
        self.dataForPlotX = self.xContent
        self.dataForPlotY = self.yContent
        self.dataForPlotZ = self.zContent
        self.dataForPlotSound = self.soundContent
        
        self.plotSpace?.yRange = CPTPlotRange(location:-7, length:18.0)
        self.plotSpace?.xRange = CPTPlotRange(location:-10, length:100.0)
        
        self.plotSpaceSound?.yRange = CPTPlotRange(location:-7, length:180.0)
        self.plotSpaceSound?.xRange = CPTPlotRange(location:-10, length: 500)
        
        self.scatterGraph?.reloadData()
        self.scatterGraphSound?.reloadData()
    }
    
    @IBAction func stopPlotting(_ sender: Any) {
        // stop plotting data
        _ = client.send(string: "stop")
        self.timerBackground?.invalidate()
        print("Stop plotting")
    }
    
    @IBAction func saveData(_ sender: Any) {
        // save current plot into user data to AWS
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
    func someBackgroundTask(timer:Timer) -> (Double, Double, Double) {
        var accelData: [Byte] = []; var soundData: [Byte] = []; var x: Double?; var y: Double?; var z: Double?
        var x_send = Double(1); var y_send = Double(1); var z_send = Double(1)
        print("do some background task")

        
        DispatchQueue.global(qos: DispatchQoS.default.qosClass).async {
            print("do some background task in async")
            let raw = self.client.recv(512)
            
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
            
            self.x_temp = x!
            self.y_temp = y!
            self.z_temp = z!
            

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
            
            
            // add soundData to another plot
            var sum = 0.0
            var i = 0
            while(i<506) {
                for j in 0...22 {
                    sum = Double(soundData[i+j]) + sum
                }
                let point = sum/23
                let soundDataPoint: plotDataType = [.X: Double(self.soundContent.count), .Y: point]
                self.soundContent.append(soundDataPoint)
                //do max and min values
                if (point > self.maxYsound) { self.maxYsound = point }
                if (point < self.minYsound) { self.minYsound = point }
                i = i+23
                sum = 0
            }
            

        }
        
            DispatchQueue.main.async {
                print("update some UI")
                // update accelerometer plot
                self.dataForPlotX = self.xContent
                self.dataForPlotY = self.yContent
                self.dataForPlotZ = self.zContent
                self.plotSpace?.yRange = CPTPlotRange(location:NSNumber(value: self.minY-3), length: NSNumber(value: 5+self.maxY+abs(self.minY)))
                if (self.X < 70) {
                    self.plotSpace?.xRange = CPTPlotRange(location:NSNumber(value: -7), length: NSNumber(value: self.movingWindowLength))
                } else {
                    
                    self.plotSpace?.xRange = CPTPlotRange(location:NSNumber(value: -5+self.xCounter), length: NSNumber(value: self.movingWindowLength))
                    self.xCounter = self.xCounter + 1
                }
                self.scatterGraph?.reloadData()
                
                // update sound plot
                self.dataForPlotSound = self.soundContent
                self.plotSpaceSound?.yRange = CPTPlotRange(location: NSNumber(value: self.minYsound-10), length: NSNumber(value: 20+self.maxYsound+abs(self.minYsound)))
                self.plotSpaceSound?.xRange = CPTPlotRange(location: NSNumber(value: self.xCounterSound-100), length: NSNumber(value: self.movingWindowLength))
                self.scatterGraphSound?.reloadData()
                self.xCounterSound = self.xCounterSound + 21
            }
        
        // return acceleration values for behaviour prediction
        x_send = self.x_temp; y_send = self.y_temp; z_send = self.z_temp
        return (x_send, y_send, z_send)
        
        
    }
    
    // function to predict dog behaviour from accelerometer data
    func accelerationPrediction (x: [Double], y: [Double], z: [Double]) -> String {
        var output = DogBehaviourOutput(label: 0)
        // perform feature extraction
        let (mean_x,std_x,skew_x,max_x,min_x, mean_y,std_y,skew_y,max_y,min_y,mean_z,std_z,skew_z,max_z,min_z,x_z,y_z,x_y,
        fft_mean_x,fft_std_x,fft_skew_x,fft_max_x,fft_2max_x,fft_min_x,
        fft_mean_y,fft_std_y,fft_skew_y,fft_max_y,fft_2max_y,fft_min_y,
        fft_mean_z,fft_std_z,fft_skew_z,fft_max_z,fft_2max_z,fft_min_z,
        psd_mean_x,psd_max_x,psd_2max_x,
        psd_mean_y,psd_max_y,psd_2max_y,
        psd_mean_z,psd_max_z,psd_2max_z) = featureExtraction(x: x, y: y, z: z)
        let mlmodel = DogBehaviour()
 
        do {
            output = try mlmodel.prediction(mean_x: mean_x, std_x: std_x, skew_x: skew_x, max_x: max_x!, min_x: min_x!, mean_y: mean_y, std_y: std_y, skew_y: skew_y, max_y: max_y!, min_y: min_y!, mean_z: mean_z, std_z: std_z, skew_z: skew_z, max_z: max_z!, min_z: min_z!, x_z: x_z, y_z: y_z, x_y: x_y, fft_mean_x: fft_mean_x, fft_std_x: fft_std_x, fft_skew_x: fft_skew_x, fft_max_x: fft_max_x, fft_2max_x: fft_2max_x, fft_min_x: fft_min_x!, fft_mean_y: fft_mean_y, fft_std_y: fft_std_y, fft_skew_y: fft_skew_y, fft_max_y: fft_max_y, fft_2max_y: fft_2max_y, fft_min_y: fft_min_y!, fft_mean_z: fft_mean_z, fft_std_z: fft_std_z, fft_skew_z: fft_skew_z, fft_max_z: fft_max_z, fft_2max_z: fft_2max_z, fft_min_z: fft_min_z!, psd_mean_x: psd_mean_x, psd_max_x: psd_max_x, psd_2max_x: psd_2max_x, psd_mean_y: psd_mean_y, psd_max_y: psd_max_y, psd_2max_y: psd_2max_y, psd_mean_z: psd_mean_z, psd_max_z: psd_max_z, psd_2max_z: psd_2max_z)
        }
            catch {
            print("Error when mlmodel prediction")
        }
        var label = ""
        switch output.label {
        case 1:
            label = "Down"
        case 2:
            label = "Sitting"
        case 3:
            label = "Standing"
        case 4:
            label = "Moving"
        default:
            label = "Unknown"
        }
        return label
    }
        
    // MARK: - Plot Data Source Methods
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        let plotID = plot.identifier as! String
        if (plotID == "xPlot") {
            return UInt(self.dataForPlotX.count)
        }
        if (plotID == "yPlot") {
            return UInt(self.dataForPlotY.count)
        }
        if (plotID == "zPlot") {
            return UInt(self.dataForPlotZ.count)
        }
        else {
            return UInt(self.dataForPlotSound.count)
        }
        
    }
    
    func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any?
    {
        let plotField = CPTScatterPlotField(rawValue: Int(field))
        let plotID = plot.identifier as! String
        
        if (plotID == "xPlot") {
            return self.dataForPlotX[Int(record)][plotField!]! as NSNumber
        }
        if (plotID == "yPlot") {
            return self.dataForPlotY[Int(record)][plotField!]! as NSNumber
        }
        if (plotID == "zPlot") {
            return self.dataForPlotZ[Int(record)][plotField!]! as NSNumber
        }
        else {
            return self.dataForPlotSound[Int(record)][plotField!]! as NSNumber
        }

    }
    
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

