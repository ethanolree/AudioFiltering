//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal





class ModuleBViewController: UIViewController {
    
    @IBOutlet weak var freqSlider: UISlider!
    @IBOutlet weak var curFrequencyLabel: UILabel!
    @IBOutlet weak var movementIndLabel: UILabel!
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.MainView)
    }()
    
    @IBOutlet weak var MainView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Range for Freq Slider and default to min
        freqSlider.minimumValue = 15000
        freqSlider.maximumValue = 20000
        freqSlider.isContinuous = false
        freqSlider.setValue(freqSlider.maximumValue, animated: false)
        curFrequencyLabel.text = Int(freqSlider.value).description
        
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            // add in graphs for display
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)


            graph.makeGrids() // add grids to graph
        }
        
        // start up the audio model here, querying microphone
        audio.startProcessingSinewaveForPlayback(withFreq: 20000)
        audio.startMicrophoneProcessing(withFps: 10)
        audio.play()
        
//         run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        
        Timer.scheduledTimer(timeInterval: 0.5, target: self,
            selector: #selector(self.checkForMovement),
            userInfo: nil,
            repeats: true)
       
    }
    
    // periodically, update the graph with refreshed FFT Data
    @objc
    func updateGraph(){
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        
        
        
        
    }
    @objc
    func checkForMovement(){
        
        movementIndLabel.text = self.audio.checkForMovement(currFreq: Int(freqSlider.value))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
        
        audio.stop()
    }
    
    @IBAction func sliderFunction(_ sender: UISlider) {
        curFrequencyLabel.text = Int(sender.value).description
        self.audio.sineFrequency = sender.value
    }

}

