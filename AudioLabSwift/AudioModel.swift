//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    var movementData:[Float]
    var rightAvgArray = [Float]()
    var leftAvgArray = [Float]()
    var minuteCounter = 0
    var startingIndex = 0
    var endingIndex = 0
    var increment = 50
    var sinWaveIndex = 0
    var prevRightAverage:Float
    var prevLeftAverage:Float
    var messageToReturn:String
    var movedLeft = "Gesturing Toward"
    var movedRight = "Gesturing Away"
    var movedNone = "Not Gesturing"
    var sinFreqChanged = false
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        movementData = Array.init(repeating: 0.0, count: 102)
        // magnitude of FFT split into 20
        increment = Int(BUFFER_SIZE)/2/20
        endingIndex = increment
        prevRightAverage = 0
        prevLeftAverage = 0
        messageToReturn = movedNone
    }
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        sineFrequency = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        if let manager = self.audioManager{
            manager.setOutputBlockToPlaySineWave(sineFrequency)
        }
    }
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                                 selector: #selector(self.runEveryInterval),
                                 userInfo: nil,
                                 repeats: true)
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            
            if let manager = self.audioManager {
                manager.sineFrequency = sineFrequency
                sinFreqChanged = true
            }
        }
    }
    
    //==========================================
    // MARK: Private Methods
    // NONE for this model
    
    //==========================================
    // MARK: Model Callback Methods
    @objc
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            
        }
    }
    
    @objc
    func checkForMovement(currFreq:Int) -> String{
        messageToReturn = movedNone
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            let freqIndexIncrement = 44100/(BUFFER_SIZE)
            let curSinFreqIndex = Int(currFreq/freqIndexIncrement)
            
            messageToReturn = movedNone
            //updateAverages
            if sinFreqChanged {
                prevRightAverage = vDSP.mean(fftData[curSinFreqIndex+1...curSinFreqIndex+4])
                
                prevLeftAverage = vDSP.mean(fftData[curSinFreqIndex-4...curSinFreqIndex-1])
                sinFreqChanged = false
            }
            
            print(" ")
            print(fftData[curSinFreqIndex]/fftData[curSinFreqIndex])
            print("right previous: " + String(prevRightAverage))
            print("right current: " + String(vDSP.mean(fftData[curSinFreqIndex+1...curSinFreqIndex+4])))
            print("left previous: " + String(prevLeftAverage))
            print("left current: " + String(vDSP.mean(fftData[curSinFreqIndex-4...curSinFreqIndex-1])))

            if vDSP.mean(fftData[curSinFreqIndex+1...curSinFreqIndex+4]) > prevRightAverage + 2{
                print("MOVING CLOSER")
                messageToReturn = movedRight
            }
            
            if vDSP.mean(fftData[curSinFreqIndex-4...curSinFreqIndex-1]) > prevLeftAverage + 2{
                print("MOVING AWAY")
                messageToReturn = movedLeft
            }
            
            prevRightAverage = vDSP.mean(fftData[curSinFreqIndex+1...curSinFreqIndex+4])
                
            prevLeftAverage = vDSP.mean(fftData[curSinFreqIndex-4...curSinFreqIndex-1])
            
            
        }
        return messageToReturn
    }
    
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    
}
