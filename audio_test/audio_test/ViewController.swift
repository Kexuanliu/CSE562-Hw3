//
//  ViewController.swift
//  audio_test
//
//  Created by Justin Kwok Lam CHAN on 4/4/21.
//

import UIKit
import AVFoundation
import Accelerate

class ViewController: UIViewController, FrameExtractorDelegate {
    var frameExtractor: FrameExtractor!
    
    //var bgImage: UIImageView?
    var intensityData: [Double] = []
    let modulation_length: Int = 16
    var cali = false
    var bits: String = ""
    var p = 0
    var pr = false
    var cou = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
    }
    
    func captured(intensity: Double) {
        //bgImage = UIImageView(image: image)
        //self.view.addSubview(bgImage ?? UIImageView(image: UIImage(named: "afternoon!")))
        //guard let curIn: Double = getIntensity(image: image) else { return }
        /*cou = cou + 1
        if cou > 250 {
            print(cou)
        }*/
        getIntensityChange(intensity: intensity)
        applyFFT()
    }
    
    func getIntensityChange(intensity: Double) {
        if intensityData.count == modulation_length {
            intensityData.removeFirst()
            /*if !cali {
                intensityData.removeFirst()
                intensityData.append(intensity)
                applyFFT()
            } else {
                applyFFT()
                intensityData.append(intensity)
            }*/
        }
        intensityData.append(intensity)
    }
    
    func applyFFT() {
        if intensityData.count == modulation_length {
            let best = myfft(sig: intensityData)
            if best == 1 {
                if !cali {
                    cali = true
                }
                bits = "\(bits)1"
                intensityData = []
            }
            if cali {
                if best == 0 {
                    bits = "\(bits)0"
                }
                intensityData = []
            }
            //intensityData = []
            if bits.count > p {
                print(bits)
                p = p + 1
            }
            //print(bits)
        }
    }
    
    /*func frombits() {
        bits = "01" + bits
        let byteArray = bits.components(separatedBy: .whitespaces).compactMap{UInt8($0, radix: 2)}
        if let originalString = String(bytes: byteArray, encoding: .utf8) {
            print(originalString)
        } else {
            print("bad encoding")
        }
    }
    
    func getIntensity(image: UIImage) -> Double? {
        /*let s = image.size
        let n = s.width * s.height * 4
        var indices = [UInt8](repeating: 0, count: Int(n))
        
        let color = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &indices, width: Int(s.width), height: Int(s.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(s.width), space: color, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = image.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: s.width, height: s.height))
        
        let red = getAverage(data: indices, s: 0, n: 4)
        let green = getAverage(data: indices, s: 1, n: 4)
        let blue = getAverage(data: indices, s: 2, n: 4)
        //print(indices)
        return (red + green + blue) / 3*/
        guard let cgImage = image.cgImage else { return nil }
        guard let imageData = cgImage.dataProvider?.data else { return nil }
        guard let ptr = CFDataGetBytePtr(imageData) else { return nil }
        let length = CFDataGetLength(imageData)
        
        var sum = Double(0)
        for i in stride(from: 0, to: length, by: 4) {
            let r = ptr[i]
            let g = ptr[i + 1]
            let b = ptr[i + 2]
            //let luminance = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
            let luminance = Double(r) + Double(g) + Double(b)
            sum = sum + luminance
        }
        return sum / Double(length)
    }
    
    func getAverage(data: [UInt8], s: Int, n: Int) -> Double {
        let indices = Array(stride(from: s, to: data.count, by: n))
        var sum: Double = 0
        let count = Double(indices.count)
        for i in indices {
            sum = sum + Double(data[i])
        }
        return sum / count
    }*/
    
    /*@IBAction func startButton(_ sender: Any) {
        
    }*/
    
    func myfft(sig: Array<Double>) -> Int {
        let n = modulation_length
        let LOG_N = vDSP_Length(log2(Float(n)));
        
        let setup = vDSP_create_fftsetupD(LOG_N,2)!;
        
        var tempSplitComplexReal = [Double](repeating: 0.0, count: sig.count);
        var tempSplitComplexImag = [Double](repeating: 0.0, count: sig.count);
        for i in 0..<sig.count {
            tempSplitComplexReal[i] = sig[i];
        }
        
        var tempSplitComplex = DSPDoubleSplitComplex(realp: &tempSplitComplexReal, imagp: &tempSplitComplexImag);
        
        vDSP_fft_zipD(setup, &tempSplitComplex, 1, LOG_N, FFTDirection(FFT_FORWARD));
        
        var fftMagnitudes = [Double](repeating: 0.0, count: n/2)
        vDSP_zvmagsD(&tempSplitComplex, 1, &fftMagnitudes, 1, vDSP_Length(n/2));
        vDSP_destroy_fftsetupD(setup);
        
        /*if !pr {
            print(fftMagnitudes)
            pr = true
        }*/
        
        // remove freq < 15 Hz
        fftMagnitudes.removeFirst()
        fftMagnitudes.removeFirst()
        //fftMagnitudes.removeFirst()
        let t = fftMagnitudes.enumerated().sorted {
            $0.element > $1.element
        }.map {
            return $0.offset
        }
        
        print(t)
        /*if t[0] == 5 {
            return 0
        } else if t[0] == 7 {
            return 1
        }
        return -1*/
        /*if fftMagnitudes[3] > fftMagnitudes[4] {
            return 1
        }
        return 0*/
        if t[0] == 2 || t[0] == 3 || t[0] == 4 || t[0] == 5 {
            return 1
        }
        return 0
    }
}

