//
//  IncomingData.swift
//  DogWearableApp
//
//  Created by Chispi on 08/02/2018.
//  Copyright © 2018 WearablesGuder. All rights reserved.
//

import Foundation
import Accelerate
import Surge

public func featureExtraction(x: [Double], y: [Double], z: [Double]) -> (Double, Double, Double, Double?, Double?, Double, Double, Double, Double?, Double?, Double, Double, Double, Double?, Double?, Double, Double, Double, Double, Double, Double, Double, Double, Double?, Double, Double, Double, Double, Double, Double?, Double, Double, Double, Double, Double, Double?, Double, Double, Double, Double, Double, Double, Double, Double, Double) {
    // calculate mean, std and skew
    let mean_x = average(nums: x); let std_x = standardDeviation(arr: x); let skew_x = skew(x);
    let mean_y = average(nums: y); let std_y = standardDeviation(arr: y); let skew_y = skew(y);
    let mean_z = average(nums: z); let std_z = standardDeviation(arr: z); let skew_z = skew(z);
    // calculate max and min
    let max_x = x.max(); let min_x = x.min();
    let max_y = y.max(); let min_y = y.min();
    let max_z = z.max(); let min_z = z.min();
    // calculate directions x/z y/z x/y
    var x_z = 0.0; if(mean_z != 0) {x_z = mean_x/mean_z;}
    var y_z = 0.0; if(mean_z != 0) {y_z = mean_y/mean_z;}
    var x_y = 0.0; if(mean_y != 0) {x_y = mean_x/mean_y;}
    // calculate mean, std and skew of real fft
    let fft_x = my_fft(x); let fft_y = my_fft(y); let fft_z = my_fft(z);
    let fft_mean_x = average(nums: fft_x); let fft_std_x = standardDeviation(arr: fft_x); let fft_skew_x = skew(fft_x);
    let fft_mean_y = average(nums: fft_y); let fft_std_y = standardDeviation(arr: fft_y); let fft_skew_y = skew(fft_y);
    let fft_mean_z = average(nums: fft_z); let fft_std_z = standardDeviation(arr: fft_z); let fft_skew_z = skew(fft_z);
    // calculate max, min and 2nd max
    var fft_x2 = fft_x.sorted(); var fft_y2 = fft_y.sorted(); var fft_z2 = fft_z.sorted()
    let fft_max_x = fft_x2[0]; let fft_min_x = fft_x.min(); let fft_2max_x = fft_x2[1]
    let fft_max_y = fft_y2[0]; let fft_min_y = fft_y.min(); let fft_2max_y = fft_y2[1]
    let fft_max_z = fft_z2[0]; let fft_min_z = fft_z.min(); let fft_2max_z = fft_z2[1]
    // calculate mean, max and 2nd max of psd
    var psd_x = my_psd(fft_x).sorted(); var psd_y = my_psd(fft_x).sorted(); var psd_z = my_psd(fft_x).sorted();
    let psd_mean_x = average(nums: psd_x); let psd_max_x = psd_x[0]; let psd_2max_x = psd_x[1]
    let psd_mean_y = average(nums: psd_y); let psd_max_y = psd_y[0]; let psd_2max_y = psd_y[1]
    let psd_mean_z = average(nums: psd_z); let psd_max_z = psd_z[0]; let psd_2max_z = psd_z[1]
    
    return (mean_x,std_x,skew_x,max_x,min_x, mean_y,std_y,skew_y,max_y,min_y,mean_z,std_z,skew_z,max_z,min_z,x_z,y_z,x_y,
            fft_mean_x,fft_std_x,fft_skew_x,fft_max_x,fft_2max_x,fft_min_x,
            fft_mean_y,fft_std_y,fft_skew_y,fft_max_y,fft_2max_y,fft_min_y,
            fft_mean_z,fft_std_z,fft_skew_z,fft_max_z,fft_2max_z,fft_min_z,
            psd_mean_x,psd_max_x,psd_2max_x,
            psd_mean_y,psd_max_y,psd_2max_y,
            psd_mean_z,psd_max_z,psd_2max_z)
    
    
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

//func skew(_ values: [Double]) -> Double? {
//    let count = Double(values.count)
//    if count < 3 { return nil }
//    guard let moment3 = centralMoment(values, order: 3) else { return nil }
//    let stdDev = standardDeviation(arr: values)
//    if stdDev == 0 { return nil }
//
//    return pow(count, 2) / ((count - 1) * (count - 2)) * moment3 / pow(stdDev, 3)
//}


func skew(_ values: [Double]) -> Double {
    let count = Double(values.count)
    //if count < 3 { return nil }
    //guard let moment3 = centralMoment(values, order: 3) else { return nil }
    guard let moment3 = centralMoment(values, order: 3) else { return 0.0}
    let stdDev = standardDeviation(arr: values)
    if stdDev == 0 { return 0.0 }
    
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

func my_fft(_ input: [Double]) -> [Double] {
    //    y(j) = sum[k=0..n-1] x[k] * exp(-sqrt(-1)*j*k*2*pi/n)
    // This fft function is equivalent to the rfft in fftpack in Python
    // my_fft only works with input.count is odd (when it's even it misses the last fft value)
    let PI = 3.141596
    let n = Double(input.count)
    let m = input.count
    var real = [Double]()
    var img =  [Double]()
    var fft_array = [Double]()
    for i in 0...(m-1)/2 {
        real.removeAll(); img.removeAll()
        for k in 0...(m-1) {
            let a = input[k] * cos(-2*PI*Double(k)*Double(i)/n)
            let b = input[k] * sin(-2*PI*Double(k)*Double(i)/n)
            real.append(a)
            img.append(b)
        }
        if(i == 0) {fft_array.append(sum(real)+sum(img))}
        else{fft_array.append(sum(real)); fft_array.append(sum(img))}
    }
    return fft_array
}

func my_psd(_ input: [Double]) -> [Double] {
    var psd_array = [Double]()
    let num = zip(input, input).map(*)
    let den = Double(input.count*input.count)
    for index in 0...input.count-1{
        psd_array.append(num[index]/den)
    }
    
    return psd_array
}

