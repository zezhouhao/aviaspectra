import Foundation
struct AudioSelection {
    let start:Double
    let end:Double
    let minFrequency:Double
    let maxFrequency:Double
}

struct RecordingLocation:Codable {
    let latitude:Double
    let longitude:Double
    let name:String
}

// Fourth-order Butterworth edges; filters only an explicitly drawn selection.
func filterSelection(_ samples:inout [Float],sampleRate:Double,low:Double,high:Double){
    func section(_ cutoff:Double,_ q:Double,_ highpass:Bool){
        let w=2*Double.pi*cutoff/sampleRate,c=cos(w),alpha=sin(w)/(2*q),a0=1+alpha
        let b0=(highpass ? 1+c : 1-c)/2/a0
        let b1=(highpass ? -(1+c) : 1-c)/a0
        let b2=b0,a1 = -2*c/a0,a2=(1-alpha)/a0
        var z1=0.0,z2=0.0
        for i in samples.indices {let x=Double(samples[i]);let y=b0*x+z1;z1=b1*x-a1*y+z2;z2=b2*x-a2*y;samples[i]=Float(y)}
    }
    for q in [0.5411961,1.306563] {
        if low>10{section(min(low,sampleRate*0.49),q,true)}
        if high<sampleRate*0.49{section(max(20,high),q,false)}
    }
}
