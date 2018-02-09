//
//  IncomingData.swift
//  DogWearableApp
//
//  Created by Chispi on 08/02/2018.
//  Copyright © 2018 WearablesGuder. All rights reserved.
//

import Foundation

public class IncomingData {
    var accelerometer: Accelerometer
    var time : Float
    var motion: Motion?
    
    init() {
        accelerometer = Accelerometer(x: 0.0, y: 0.0, z: 0.0)
        time = 0.0
    }
}

struct Accelerometer {
    var x = 0.0
    var y = 0.0
    var z = 0.0
}

enum Motion {
    case down
    case sit
    case walk
    case run
}
