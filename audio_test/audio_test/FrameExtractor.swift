//
//  FrameExtractor.swift
//  audio_test
//
//  Created by Kexuan Liu on 5/30/21.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    //func captured(image: UIImage)
    func captured(intensity: Double)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.medium
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return }
        
        /*try! captureDevice.lockForConfiguration();
        captureDevice.exposureMode = AVCaptureDevice.ExposureMode.locked
        captureDevice.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode.locked
        captureDevice.unlockForConfiguration()*/
        
        //captureDevice.set(frameRate: 60)
        //captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(60))
        //captureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(60))
        configureCameraForHighestFrameRate(device: captureDevice)
        //print(captureDevice.activeFormat.videoSupportedFrameRateRanges)
        captureDevice.set(frameRate: 60)
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .back
    }
    
    private func configureCameraForHighestFrameRate(device: AVCaptureDevice) {
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?

        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate > bestFrameRateRange?.maxFrameRate ?? 0 {
                    bestFormat = format
                    bestFrameRateRange = range
                }
            }
        }
        
        if let bestFormat = bestFormat,
           let bestFrameRateRange = bestFrameRateRange {
            do {
                try device.lockForConfiguration()
                
                // Set the device's active format.
                device.activeFormat = bestFormat
                
                // Set the device's min/max frame duration.
                let duration = bestFrameRateRange.minFrameDuration
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
                
                device.unlockForConfiguration()
            } catch {
                // Handle error.
            }
        }
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaType.video) &&
            ($0 as AnyObject).position == position
        }.first as? AVCaptureDevice
    }
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> Double? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let uiIm = UIImage(cgImage: cgImage)
        guard let res: Double = uiIm.averageIntensity() else { return nil }
        //return UIImage(cgImage: cgImage)
        return res
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: didOutput) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(intensity: uiImage)
        }
    }
}

extension UIImage {
    func averageIntensity() -> Double? {
        guard let cgImage = self.cgImage else { return nil }
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
}

extension AVCaptureDevice {
    func set(frameRate: Double) {
        guard let range = activeFormat.videoSupportedFrameRateRanges.first,
            range.minFrameRate...range.maxFrameRate ~= frameRate
            else {
                print("Requested FPS is not supported by the device's activeFormat !")
                return
        }

        do { try lockForConfiguration()
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            unlockForConfiguration()
        } catch {
            print("LockForConfiguration failed with error: \(error.localizedDescription)")
        }
    }
}
