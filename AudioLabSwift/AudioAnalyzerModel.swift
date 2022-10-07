//
//  AudioAnalyzerModel.swift
//  AudioLabSwift
//
//  Created by Ethan Olree on 10/2/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import Foundation

class AudioAnalyzerModel {
    var maxFreq: (Float, Float) = (0.0, 0.0)
    var WINDOW_SIZE = 20
    
    
    var BUFFER_SIZE = 4096*16
    
    init() {
        
    }
    
    // Function for calculating peak frequencies from the dataset
    // Adds significant max values to the maxFreq model
    func calcMaxFreq(data:[Float]) {
        for i in 0...(data.count-WINDOW_SIZE) {
            var temp: [Float] = Array(data[i..<i+WINDOW_SIZE])
            var max: Float = 0.0
            var index: Int = 0
            vDSP_maxvi(&temp, 1, &max, &index, vDSP_Length(WINDOW_SIZE))
            
            // Checks for a significant frequency
            if (index == Int(WINDOW_SIZE/2) && max > 5) {
                
                // Calculate the peak frequency using the adjacent values
                // f values are along the x-axis, m values are the y-axis
                let f1: Float = (Float(i) - 1) * (48000 / Float(BUFFER_SIZE))
                let f2: Float = Float(i) * (48000 / Float(BUFFER_SIZE))
                let f3: Float = (Float(i) + 1) * (48000 / Float(BUFFER_SIZE))
                
                let m1: Float = data[i-1]
                let m2: Float = data[i]
                let m3: Float = data[i+1]
                
                let freq: Float = f2 + ((m1 - m2) / (m3 - 2*m2 + m1)) * (f3-f1)/2
                
                // See if a new max frequency has been found and add it to the max if so
                if (abs(freq - maxFreq.0) > 50 && abs(freq - maxFreq.1) > 50 && freq > 0) {
                    maxFreq.1 = maxFreq.0
                    maxFreq.0 = freq
                    print(maxFreq)
                }
            }
        }
    }
}
