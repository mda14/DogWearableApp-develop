//
//  IncomingData.swift
//  DogWearableApp
//
//  Created by Chispi on 08/02/2018.
//  Copyright © 2018 WearablesGuder. All rights reserved.
//

import Foundation
import Accelerate

public func featureExtraction(x: [Double], y: [Double], z: [Double]) -> [Double] {
    // calculate mean, std and skew
    var mean_x = average(nums: x); var std_x = standardDeviation(arr: x); var skew_x = skew(x);
    var mean_y = average(nums: y); var std_y = standardDeviation(arr: y); var skew_y = skew(y);
    var mean_z = average(nums: z); var std_z = standardDeviation(arr: z); var skew_z = skew(z);
    // calculate max and min
    var max_x = x.max(); var min_x = x.min();
    var max_y = y.max(); var min_y = y.min();
    var max_z = z.max(); var min_z = z.min();
    // calculate directions x/z y/z x/y
    var x_z = mean_x/mean_z;
    var y_z = mean_y/mean_z;
    var x_y = mean_x/mean_y;
    // calculate mean, std and skew of real fft
    // calculate max, min and 2nd max
    
    // calculate mean, max and 2nd max
    return features;
}

func average(nums: [Double]) -> Double {
    
    var total = 0.0
    //use the parameter-array instead of the global variable votes
    for vote in nums{
        
        total += Double(vote)
        
    }
    
    let votesTotal = Double(nums.count)
    return total/votesTotal
}

func standardDeviation(arr : [Double]) -> Double
{
    let length = Double(arr.count)
    let avg = arr.reduce(0, {$0 + $1}) / length
    let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
    return sqrt(sumOfSquaredAvgDiff / length)
}

// function from Alan James Salmoni

func skew(_ values: [Double]) -> Double? {
    let count = Double(values.count)
    if count < 3 { return nil }
    guard let moment3 = centralMoment(values, order: 3) else { return nil }
    let stdDev = standardDeviation(arr: values)
    if stdDev == 0 { return nil }
    
    return pow(count, 2) / ((count - 1) * (count - 2)) * moment3 / pow(stdDev, 3)
}

func centralMoment(_ values: [Double], order: Int) -> Double? {
    let count = Double(values.count)
    if count == 0 { return nil }
    let averageVal = average(nums: values)
    
    let total = values.reduce(0) { sum, value in
        sum + pow((value - averageVal), Double(order))
    }
    
    return total / count
}
