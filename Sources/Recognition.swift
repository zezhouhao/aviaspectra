import Foundation
import AVFoundation

struct BirdPrediction: Codable {
    let scientific: String
    let name: String
    let english: String
    let score: Double
}
struct BirdResponse: Codable {
    let predictions: [BirdPrediction]
    let cached: Bool
    let elapsed_ms: Double
}
struct BirdSegment {
    let start: Double
    let end: Double
    let predictions: [BirdPrediction]
}

final class RecognitionJob {
    private let lock = NSLock()
    private var stopped = false
    var cancelled: Bool {lock.lock();defer{lock.unlock()};return stopped}
    func cancel() {lock.lock();stopped=true;lock.unlock()}
    static func pcm(_ url: URL,selection:AudioSelection?=nil) throws -> (AVAudioPCMBuffer,Double) {
        let file=try AVAudioFile(forReading:url)
        let input=file.processingFormat
        guard input.channelCount<=8, input.sampleRate>0,
              let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:48000,channels:input.channelCount,interleaved:false),
              let converter=AVAudioConverter(from:input,to:format) else {
            throw NSError(domain:"AviaSpectra",code:10,userInfo:[NSLocalizedDescriptionKey:"暂支持最多 8 声道的音频"])
        }
        let start=selection?.start ?? 0
        file.framePosition=min(file.length,max(0,AVAudioFramePosition(start*input.sampleRate)))
        let duration=min(120,min((selection.map{$0.end-$0.start} ?? 120),Double(file.length-file.framePosition)/input.sampleRate))
        guard duration>0,let out=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(ceil(duration*48000))) else {
            throw NSError(domain:"AviaSpectra",code:11,userInfo:[NSLocalizedDescriptionKey:"音频为空"])
        }
        var readError:Error?
        var reachedEOF=false
        var error:NSError?
        let status=converter.convert(to:out,error:&error){count,state in
            do {
                guard !reachedEOF && file.framePosition<file.length else {state.pointee = .endOfStream;return nil}
                let n=min(count,8192)
                let buffer=AVAudioPCMBuffer(pcmFormat:input,frameCapacity:n)!
                do {try file.read(into:buffer,frameCount:n)} catch {
                    let e=error as NSError
                    // MP3 headers can overestimate decoded frames due to encoder padding.
                    if e.domain==NSOSStatusErrorDomain && e.code == -39 {reachedEOF=true}
                    else{throw error}
                }
                state.pointee = buffer.frameLength>0 ? .haveData : .endOfStream
                return buffer
            } catch {readError=error;state.pointee = .endOfStream;return nil}
        }
        if let e=readError{throw e};if status == .error{throw error ?? NSError(domain:"AviaSpectra",code:12)}
        guard out.frameLength>0 else {throw NSError(domain:"AviaSpectra",code:13)}
        return (out,Double(out.frameLength)/48000)
    }
    func run(_ url:URL,selection:AudioSelection?=nil,location:RecordingLocation?=nil, update:@escaping(BirdSegment,Double,Bool,Double)->Void, finish:@escaping(String?)->Void) {
        DispatchQueue.global(qos:.utility).async { [self] in
            let startTime=Date()
            do {
                let (buffer,duration)=try Self.pcm(url,selection:selection)
                guard let channels=buffer.floatChannelData else {throw NSError(domain:"AviaSpectra",code:15)}
                let frames=Int(buffer.frameLength), count=Int(buffer.format.channelCount)
                if let box=selection {
                    for c in 0..<count {
                        var values=Array(UnsafeBufferPointer(start:channels[c],count:frames))
                        filterSelection(&values,sampleRate:48000,low:box.minFrequency,high:box.maxFrequency)
                        values.withUnsafeBufferPointer{channels[c].update(from:$0.baseAddress!,count:frames)}
                    }
                }
                let starts=stride(from:0,through:max(0,frames-144000),by:72000).map{$0}
                var offsets=starts
                // Cover the complete tail without a redundant mostly padded final window.
                if let last=offsets.last,last+144000<frames {offsets.append(max(0,frames-144000))}
                var allCached=true
                for (index,offset) in offsets.enumerated() {
                    if cancelled{return}
                    var data=Data(capacity:144000*4*count)
                    for c in 0..<count {
                        let valid=min(144000,max(0,frames-offset))
                        data.append(UnsafeRawPointer(channels[c]+offset).assumingMemoryBound(to:UInt8.self),count:valid*4)
                        if valid<144000{data.append(Data(count:(144000-valid)*4))}
                    }
                    if cancelled{return}
                    let result=try NativeBirdEngine.shared.predict(data,channels:count,location:location)
                    if cancelled{return}
                    allCached = allCached && result.cached
                    let cachedSnapshot=allCached
                    let segment=BirdSegment(start:(selection?.start ?? 0)+Double(offset)/48000,end:(selection?.start ?? 0)+min(duration,Double(offset+144000)/48000),predictions:result.predictions)
                    DispatchQueue.main.async { [self] in
                        if !cancelled{update(segment,Double(index+1)/Double(offsets.count),cachedSnapshot,Date().timeIntervalSince(startTime))}
                    }
                }
                DispatchQueue.main.async{[self] in if !cancelled{finish(nil)}}
            } catch {
                fputs("AviaSpectra recognition: \(error)\n",stderr)
                if !cancelled{DispatchQueue.main.async{[self] in if !cancelled{finish("本地模型分析失败；音频仍可播放。")}}}
            }
        }
    }
}
