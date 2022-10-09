//
//  AudioAnalyzerModel.swift
//  AudioLabSwift
//
//  Created by Ethan Olree on 10/2/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import Foundation

class AudioAnalyzerModel {
    var maxFreq: (Int, Int) = (0, 0)
    var WINDOW_SIZE = 7
    
    
    var BUFFER_SIZE = 4096*16
    
    init() {
        
    }
    
    // Function for calculating peak frequencies from the dataset
    // Adds significant max values to the maxFreq model
    func calcMaxFreq(data:[Float]) {
        var maxVals: ((Float, Float), (Float, Float)) = ((0.0, 0.0), (0.0, 0.0))
        for i in 0...(data.count-WINDOW_SIZE) {
            var temp: [Float] = Array(data[i..<i+WINDOW_SIZE])
            var max: Float = 0.0
            var index: Int = 0
            vDSP_maxvi(&temp, 1, &max, &index, vDSP_Length(WINDOW_SIZE))
            
            // Checks for a significant frequency
            if (index == Int(WINDOW_SIZE/2)) {
                
                // Calculate the peak frequency using the adjacent values
                // f values are along the x-axis, m values are the y-axis
                let f1: Float = (Float(i) - 1) * (48000 / Float(BUFFER_SIZE))
                let f2: Float = Float(i) * (48000 / Float(BUFFER_SIZE))
                let f3: Float = (Float(i) + 1) * (48000 / Float(BUFFER_SIZE))
                
                let m1: Float = data[i-1 + Int(WINDOW_SIZE / 2)]
                let m2: Float = data[i + Int(WINDOW_SIZE / 2)]
                let m3: Float = data[i+1 + Int(WINDOW_SIZE / 2)]
                
                let freq: Float = f2 + ((m1 - m2) / (m3 - 2*m2 + m1)) * (f3-f1)/2
                
                // See if a new max frequency has been found and add it to the max if so
                if (freq > 100 && freq < 20000) {
                    if (max > maxVals.0.1) {
                        maxVals.1 = maxVals.0
                        maxVals.0 = (freq, max)
                    } else if (max > maxVals.1.1) {
                        maxVals.1 = (freq, max)
                    }
                }
            }
        }
        maxFreq = (Int(maxVals.0.0), Int(maxVals.1.0))
    }
}
