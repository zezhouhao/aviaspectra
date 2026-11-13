import AppKit
import AVFoundation
import Accelerate

struct AudioAnalysis {
    let image: NSImage
    let startTime: Double
    let duration: Double
    let sampleRate: Double
    let maxFrequency: Double
    let waveform: [Float]
    let peakFrequency: Double
    let columns: Int
    static let fftSize = 2048

    static func compute(_ url: URL, startTime:Double=0, durationLimit:Double=120) throws -> AudioAnalysis {
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        let rate = file.processingFormat.sampleRate
        // Bound prototype memory use. Long files explicitly preview their first 120 seconds.
        let startFrame=max(0,min(file.length,AVAudioFramePosition(startTime*rate)))
        file.framePosition=startFrame
        let count = min(file.length-startFrame, AVAudioFramePosition(rate * min(120,max(0,durationLimit))))
        guard count > 0, let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(count)) else {
            throw NSError(domain: "AviaSpectra", code: 1, userInfo: [NSLocalizedDescriptionKey: "音频为空或无法读取"])
        }
        try file.read(into: buffer, frameCount: AVAudioFrameCount(count))
        guard let channels = buffer.floatChannelData else { throw NSError(domain: "AviaSpectra", code: 2) }
        let n = Int(buffer.frameLength)
        // First channel avoids cancellation of opposite-phase stereo bird recordings.
        let samples = Array(UnsafeBufferPointer(start: channels[0], count: n))
        let fftSize = Self.fftSize
        guard let setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD) else {
            throw NSError(domain: "AviaSpectra", code: 3)
        }
        defer { vDSP_DFT_DestroySetup(setup) }
        var window = [Float](repeating: 0, count: fftSize)
        for i in 0..<fftSize { window[i] = Float(0.5 - 0.5 * cos(2 * Double.pi * Double(i) / Double(fftSize - 1))) }
        let width = max(1, min(1600, Int(ceil(Double(n) / (durationLimit<10 ? 64 : 256)))))
        let height = 480, maxF = min(12000.0, rate / 2)
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        var re = [Float](repeating: 0, count: fftSize), im = re, outRe = re, outIm = re
        var peaks = [Float](repeating: 0, count: fftSize/2)
        let stops: [(Double, Double, Double)] = [(6,14,27),(14,43,65),(17,95,113),(43,158,154),(159,207,126),(255,218,108),(255,249,219)]
        for x in 0..<width {
            let center = Int((Double(x) + 0.5) / Double(width) * Double(n))
            for i in 0..<fftSize {
                let at = center + i - fftSize/2
                re[i] = (at >= 0 && at < n ? samples[at] : 0) * window[i]
            }
            vDSP_DFT_Execute(setup, re, im, &outRe, &outIm)
            for k in 0..<fftSize/2 { peaks[k] += outRe[k]*outRe[k] + outIm[k]*outIm[k] }
            for y in 0..<height {
                let f = Double(height-1-y) / Double(height-1) * maxF
                let k = min(fftSize/2-1, Int((f/rate * Double(fftSize)).rounded()))
                let mag = sqrt(outRe[k]*outRe[k] + outIm[k]*outIm[k]) * 4 / Float(fftSize)
                let db = 20 * log10(max(mag, 0.000001))
                let t = Double(max(0, min(1, (db + 90) / 80))) * Double(stops.count-1)
                let j = min(stops.count-2, Int(t)), a = t-Double(j)
                let c0 = stops[j], c1 = stops[j+1], offset = (y*width+x)*4
                pixels[offset] = UInt8(c0.0*(1-a)+c1.0*a)
                pixels[offset+1] = UInt8(c0.1*(1-a)+c1.1*a)
                pixels[offset+2] = UInt8(c0.2*(1-a)+c1.2*a)
            }
        }
        let data = Data(pixels)
        let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width*4,
                         space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                         provider: CGDataProvider(data: data as CFData)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        let image = NSImage(cgImage: cg, size: NSSize(width: width, height: height))
        var wave = [Float](repeating: 0, count: width)
        for x in 0..<width {
            let a = x*n/width, b = max(a+1, (x+1)*n/width)
            for i in a..<min(n,b) { wave[x] = max(wave[x], abs(samples[i])) }
        }
        let peak = (1..<peaks.count).max(by: { peaks[$0] < peaks[$1] }) ?? 0
        return AudioAnalysis(image: image, startTime:Double(startFrame)/rate, duration: Double(n)/rate, sampleRate: rate, maxFrequency: maxF,
                             waveform: wave, peakFrequency: Double(peak)*rate/Double(fftSize), columns: width)
    }
}
