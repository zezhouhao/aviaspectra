import Foundation
import CryptoKit

final class NativeBirdEngine {
    static let shared=NativeBirdEngine()
    private let lock=NSLock()
    private var handle:UnsafeMutableRawPointer?
    private var geoHandle:UnsafeMutableRawPointer?
    private var geoMasks:[String:[Bool]]=[:]
    private var labels:[(String,String)]=[]
    private var chinese:[String:String]=[:]
    private var modelHash=""
    private var missCount=0
    private lazy var cacheURL:URL = {
        let base=FileManager.default.urls(for:.cachesDirectory,in:.userDomainMask).first ?? FileManager.default.temporaryDirectory
        let url=base.appendingPathComponent("AviaSpectra/BirdNET-V2.4-native-v1",isDirectory:true)
        try? FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)
        return url
    }()
    private func initialize() throws {
        guard handle == nil else{return}
        guard let url=Bundle.main.url(forResource:"model",withExtension:"tflite"),
              let labelsURL=Bundle.main.url(forResource:"labels",withExtension:"txt"),
              let zhURL=Bundle.main.url(forResource:"labels_zh",withExtension:"txt") else {throw NSError(domain:"AviaSpectraModel",code:1)}
        labels=try String(contentsOf:labelsURL,encoding:.utf8).split(whereSeparator:\.isNewline).map{line in
            let parts=line.split(separator:"_",maxSplits:1);return(String(parts[0]),parts.count>1 ? String(parts[1]) : String(parts[0]))
        }
        guard labels.count==6522 else{throw NSError(domain:"AviaSpectraModel",code:2)}
        for line in try String(contentsOf:zhURL,encoding:.utf8).split(whereSeparator:\.isNewline) {
            let parts=line.split(separator:"_",maxSplits:1);if parts.count==2{chinese[String(parts[0])]=String(parts[1])}
        }
        modelHash=SHA256.hash(data:try Data(contentsOf:url,options:.mappedIfSafe)).map{String(format:"%02x",$0)}.joined()
        var status:Int32=0
        handle=url.path.withCString{bs_create($0,&status)}
        guard handle != nil else{throw NSError(domain:"AviaSpectraModel",code:Int(status))}
    }
    func predict(_ raw:Data,channels:Int,location:RecordingLocation?=nil) throws -> BirdResponse {
        lock.lock();defer{lock.unlock()}
        let start=Date();try initialize()
        guard channels>0,channels<=8,raw.count==channels*144000*4 else{throw NSError(domain:"AviaSpectraModel",code:3)}
        let locationKey=location.map{String(format:"%.6f,%.6f",$0.latitude,$0.longitude)} ?? "global"
        var mask:[Bool]?
        if let location=location {
            if let saved=geoMasks[locationKey]{mask=saved}
            else {
                if geoHandle == nil {
                    guard let url=Bundle.main.url(forResource:"geo",withExtension:"tflite") else{throw NSError(domain:"AviaSpectraModel",code:5)}
                    var status:Int32=0;geoHandle=url.path.withCString{bs_create_geo($0,&status)}
                    guard geoHandle != nil else{throw NSError(domain:"AviaSpectraModel",code:Int(status))}
                }
                let input:[Float]=[Float(location.latitude),Float(location.longitude),-1]
                var output=[Float](repeating:0,count:6522)
                guard bs_predict(geoHandle,input,&output)==0 else{throw NSError(domain:"AviaSpectraModel",code:6)}
                let allowed=output.map{$0>=0.03};geoMasks[locationKey]=allowed;mask=allowed
            }
        }
        var hasher=SHA256();hasher.update(data:Data((modelHash+":native-v2:geo="+locationKey+":48k:3s:channels="+String(channels)).utf8));hasher.update(data:raw)
        let key=hasher.finalize().map{String(format:"%02x",$0)}.joined()
        let path=cacheURL.appendingPathComponent(key+".json")
        if let data=try? Data(contentsOf:path),let predictions=try? JSONDecoder().decode([BirdPrediction].self,from:data) {
            return BirdResponse(predictions:predictions,cached:true,elapsed_ms:Date().timeIntervalSince(start)*1000)
        }
        var scores=[Float](repeating:0,count:6522)
        var input=[Float](repeating:0,count:144000),output=[Float](repeating:0,count:6522)
        for c in 0..<channels {
            _=input.withUnsafeMutableBytes{raw.copyBytes(to:$0,from:(c*144000*4)..<((c+1)*144000*4))}
            guard input.allSatisfy({$0.isFinite}) else{throw NSError(domain:"AviaSpectraModel",code:4)}
            if (input.map{abs($0)}.max() ?? 0)<1e-7{continue}
            let status=bs_predict(handle,input,&output)
            guard status==0 else{throw NSError(domain:"AviaSpectraModel",code:Int(status))}
            for i in scores.indices {scores[i]=max(scores[i],1/(1+exp(-min(20,max(-20,output[i])))))}
        }
        if let mask=mask{for i in scores.indices where !mask[i]{scores[i]=0}}
        let top=scores.indices.sorted{scores[$0]>scores[$1]}.prefix(5).filter{scores[$0]>=0.1}
        let predictions=top.map{i in BirdPrediction(scientific:labels[i].0,name:chinese[labels[i].0] ?? labels[i].1,english:labels[i].1,score:Double(scores[i]))}
        if let data=try? JSONEncoder().encode(predictions){try? data.write(to:path,options:.atomic)}
        missCount += 1
        if missCount % 256 == 0,let files=try? FileManager.default.contentsOfDirectory(at:cacheURL,includingPropertiesForKeys:[.contentModificationDateKey]),files.count>4096 {
            let sorted=files.sorted{((try? $0.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast)<((try? $1.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast)}
            for old in sorted.prefix(files.count-3840){try? FileManager.default.removeItem(at:old)}
        }
        return BirdResponse(predictions:predictions,cached:false,elapsed_ms:Date().timeIntervalSince(start)*1000)
    }
    deinit {if let handle=handle{bs_destroy(handle)};if let geoHandle=geoHandle{bs_destroy(geoHandle)}}
}
