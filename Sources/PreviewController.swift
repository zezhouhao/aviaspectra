import AppKit
import AVFoundation
import UniformTypeIdentifiers

final class SpectrogramView: NSView {
    var analysis: AudioAnalysis? { didSet { needsDisplay = true;needsLayout=true } }
    var segments: [BirdSegment] = [] { didSet { needsDisplay = true;needsLayout=true } }
    var position: Double = 0 { didSet { needsDisplay = true } }
    var onSeek: ((Double) -> Void)?
    var onViewportChanged:(()->Void)?
    var onSelectionChanged:(()->Void)?
    var selection:AudioSelection? {didSet{needsDisplay=true;onSelectionChanged?()}}
    private var dragAnchor:NSPoint?
    private var drewSelection=false
    var visibleStart:Double=0
    var visibleDuration:Double=0
    var visibleLowFrequency:Double=0
    var detailAnalysis:AudioAnalysis?
    var rangeDuration:Double{max(0.001,visibleDuration>0 ? visibleDuration : (analysis?.duration ?? 1))}
    var rangeEnd:Double{visibleStart+rangeDuration}
    var frequencySpan:Double{(analysis?.maxFrequency ?? 12000)*rangeDuration/max(0.001,analysis?.duration ?? 1)}
    var frequencyEnd:Double{visibleLowFrequency+frequencySpan}
    func setViewport(start:Double,duration:Double,lowFrequency:Double?=nil){
        guard let a=analysis else{return}
        let oldCenter=visibleLowFrequency+frequencySpan/2
        let length=min(a.duration,max(min(0.1,a.duration),duration))
        visibleDuration=length;visibleStart=min(max(0,start),max(0,a.duration-length));detailAnalysis=nil
        visibleLowFrequency=min(max(0,lowFrequency ?? oldCenter-frequencySpan/2),max(0,a.maxFrequency-frequencySpan))
        needsDisplay=true;onViewportChanged?()
    }
    func zoom(_ factor:Double,anchor:Double=0.5,frequencyAnchor:Double=0.5){
        guard let a=analysis,factor.isFinite,factor>0 else{return}
        let x=min(1,max(0,anchor)),y=min(1,max(0,frequencyAnchor))
        let time=visibleStart+rangeDuration*x,frequency=visibleLowFrequency+frequencySpan*y
        let newDuration=min(a.duration,max(min(0.1,a.duration),rangeDuration/factor))
        let newSpan=a.maxFrequency*newDuration/max(0.001,a.duration)
        setViewport(start:time-newDuration*x,duration:newDuration,lowFrequency:frequency-newSpan*y)
    }
    func fit(){setViewport(start:0,duration:analysis?.duration ?? 1,lowFrequency:0)}
    override func scrollWheel(with event:NSEvent){
        guard analysis != nil else{return}
        let delta=event.hasPreciseScrollingDeltas ? 0.015 : 0.12
        let panScale=event.hasPreciseScrollingDeltas ? 0.002 : 0.03
        if event.modifierFlags.contains(.option) {
            setViewport(start:visibleStart-event.scrollingDeltaX*rangeDuration*panScale,duration:rangeDuration,lowFrequency:visibleLowFrequency+event.scrollingDeltaY*frequencySpan*panScale)
        } else if event.modifierFlags.contains(.shift) || abs(event.scrollingDeltaX)>abs(event.scrollingDeltaY) {
            let amount=event.modifierFlags.contains(.shift) ? event.scrollingDeltaY : event.scrollingDeltaX
            setViewport(start:visibleStart-amount*rangeDuration*panScale,duration:rangeDuration,lowFrequency:visibleLowFrequency)
        } else {
            let point=convert(event.locationInWindow,from:nil)
            zoom(exp(max(-0.7,min(0.7,event.scrollingDeltaY*delta))),anchor:(point.x-plot.minX)/plot.width,frequencyAnchor:(point.y-plot.minY)/plot.height)
        }
    }
    override func magnify(with event:NSEvent){let p=convert(event.locationInWindow,from:nil);zoom(exp(Double(event.magnification)),anchor:(p.x-plot.minX)/plot.width,frequencyAnchor:(p.y-plot.minY)/plot.height)}
    var preferredSpecies:String?
    var additionalCandidates=false
    var rankedBirds:[BirdPrediction] {
        var best:[String:BirdPrediction]=[:]
        for s in segments {for bird in s.predictions where bird.score>=0.5 {
            if bird.score>(best[bird.scientific]?.score ?? 0){best[bird.scientific]=bird}
        }}
        var ranked=best.values.sorted{$0.score>$1.score}
        if let selected=preferredSpecies,let index=ranked.firstIndex(where:{$0.scientific==selected}) {let bird=ranked.remove(at:index);ranked.insert(bird,at:0)}
        return Array(ranked.prefix(3))
    }
    var floatingCard:FloatingSpeciesCard?
    override func layout(){
        super.layout()
        if let card=floatingCard {
            let p=plot, width=min(570,max(100,p.width-24)),height=Double(rankedBirds.count)*24+16+(additionalCandidates ? 24 : 0)
            let origin=card.userPosition ?? NSPoint(x:p.maxX-width-12,y:p.maxY-height-12)
            card.frame=NSRect(x:min(p.maxX-width,max(p.minX,origin.x)),y:min(p.maxY-height,max(p.minY,origin.y)),width:width,height:height)
        }
    }
    var regionTips:[NSView.ToolTipTag:String]=[:]
    var plot: NSRect { NSRect(x: 60, y: 34, width: max(1,bounds.width-80), height: max(1,bounds.height-125-Double(rankedBirds.count)*12)) }
    func view(_ view:NSView,stringForToolTip tag:NSView.ToolTipTag,point:NSPoint,userData:UnsafeMutableRawPointer?)->String {regionTips[tag] ?? ""}
    override var acceptsFirstResponder: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed: 0.025, green: 0.045, blue: 0.075, alpha: 1).setFill(); bounds.fill()
        guard let a = analysis else { return }
        let p = plot
        removeAllToolTips();regionTips.removeAll()
        let source=detailAnalysis ?? a
        let from=NSRect(x:(visibleStart-source.startTime)/source.duration*source.image.size.width,y:visibleLowFrequency/source.maxFrequency*source.image.size.height,width:rangeDuration/source.duration*source.image.size.width,height:frequencySpan/source.maxFrequency*source.image.size.height)
        source.image.draw(in:p,from:from,operation:.sourceOver,fraction:1)
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular), .foregroundColor: NSColor(calibratedWhite: 0.7, alpha: 1)]
        for i in 0...6 {
            let y = p.minY + Double(i)/6*p.height
            NSColor(white: 1, alpha: 0.10).setStroke()
            let path=NSBezierPath();path.move(to:NSPoint(x:p.minX,y:y));path.line(to:NSPoint(x:p.maxX,y:y));path.stroke()
            let label=String(format:frequencySpan<600 ? "%.2f" : "%.1f", (visibleLowFrequency+frequencySpan*Double(i)/6)/1000)
            (label as NSString).draw(at:NSPoint(x:24,y:y-6),withAttributes:attrs)
        }
        ("kHz" as NSString).draw(at:NSPoint(x:17,y:p.maxY+12),withAttributes:attrs)
        for i in 0...6 {
            let x=p.minX+Double(i)/6*p.width
            let label=String(format:rangeDuration<2 ? "%.2f s" : "%.1f s",visibleStart+rangeDuration*Double(i)/6)
            (label as NSString).draw(at:NSPoint(x:x-14,y:12),withAttributes:attrs)
        }
        let waveRect=NSRect(x:p.minX,y:p.maxY+30+Double(rankedBirds.count)*12,width:p.width,height:40)
        NSColor(calibratedRed:0.35,green:0.8,blue:0.75,alpha:0.8).setStroke()
        let wave=NSBezierPath();wave.lineWidth=1
        let maxAmp=max(0.001,source.waveform.max() ?? 1)
        for i in source.waveform.indices {
            let time=source.startTime+Double(i)/Double(max(1,source.waveform.count-1))*source.duration
            guard time>=visibleStart && time<=rangeEnd else{continue}
            let x=waveRect.minX+(time-visibleStart)/rangeDuration*waveRect.width
            let h=Double(source.waveform[i]/maxAmp)*waveRect.height/2
            wave.move(to:NSPoint(x:x,y:waveRect.midY-h));wave.line(to:NSPoint(x:x,y:waveRect.midY+h))
        }
        wave.stroke()
        let colors:[NSColor]=[.systemCyan,.systemOrange,.systemPink]
        for (row,bird) in rankedBirds.enumerated() {
            let y=p.maxY+16+Double(rankedBirds.count-1-row)*12
            var spans:[(Double,Double,Double)]=[]
            for segment in segments.sorted(by:{$0.start<$1.start}) {
                guard let match=segment.predictions.first(where:{$0.scientific==bird.scientific && $0.score>=0.5}) else{continue}
                if let last=spans.last,segment.start<=last.1+0.001 {
                    spans[spans.count-1]=(last.0,max(last.1,segment.end),max(last.2,match.score))
                } else {spans.append((segment.start,segment.end,match.score))}
            }
            for (start,end,score) in spans {
                let left=max(start,visibleStart),right=min(end,rangeEnd)
                guard right>left else{continue}
                let rect=NSRect(x:p.minX+(left-visibleStart)/rangeDuration*p.width,y:y,width:max(2,(right-left)/rangeDuration*p.width),height:8)
                colors[row].withAlphaComponent(0.32).setFill();NSBezierPath(roundedRect:rect,xRadius:3,yRadius:3).fill()
                let full="\(bird.name) · \(bird.scientific) · \(String(format:"%.2f",score))"
                let tag=addToolTip(rect,owner:self,userData:nil)
                regionTips[tag]=full+String(format:"\n%.2f–%.2f 秒",start,end)
            }
        }
        if let box=selection {
            let left=max(box.start,visibleStart),right=min(box.end,rangeEnd)
            let bottom=max(box.minFrequency,visibleLowFrequency),top=min(box.maxFrequency,frequencyEnd)
            if right>left && top>bottom {
                let rect=NSRect(x:p.minX+(left-visibleStart)/rangeDuration*p.width,y:p.minY+(bottom-visibleLowFrequency)/frequencySpan*p.height,width:(right-left)/rangeDuration*p.width,height:(top-bottom)/frequencySpan*p.height)
                NSColor.systemYellow.withAlphaComponent(0.12).setFill();rect.fill()
                NSColor.systemYellow.setStroke();let border=NSBezierPath(rect:rect);border.lineWidth=1.5;border.stroke()
                let text=String(format:"%.2f–%.2f s · %.1f–%.1f kHz",box.start,box.end,box.minFrequency/1000,box.maxFrequency/1000)
                (text as NSString).draw(at:NSPoint(x:rect.minX+4,y:min(p.maxY-16,rect.maxY+3)),withAttributes:[.font:NSFont.monospacedDigitSystemFont(ofSize:10,weight:.medium),.foregroundColor:NSColor.systemYellow])
            }
        }
        guard position>=visibleStart && position<=rangeEnd else{return}
        let x=p.minX+(position-visibleStart)/rangeDuration*p.width
        NSColor.white.setStroke();let cursor=NSBezierPath();cursor.lineWidth=1.5
        cursor.move(to:NSPoint(x:x,y:p.minY));cursor.line(to:NSPoint(x:x,y:waveRect.maxY));cursor.stroke()
        NSColor.white.setFill();NSBezierPath(ovalIn:NSRect(x:x-3,y:p.maxY+5,width:6,height:6)).fill()
    }
    override func mouseDown(with event:NSEvent) {
        if event.clickCount==2{fit();dragAnchor=nil;return}
        let point=convert(event.locationInWindow,from:nil)
        dragAnchor=plot.contains(point) ? point : nil;drewSelection=false
    }
    override func mouseDragged(with event:NSEvent) {
        guard let anchor=dragAnchor,analysis != nil else{return}
        let current=convert(event.locationInWindow,from:nil)
        guard abs(current.x-anchor.x)>3 || abs(current.y-anchor.y)>3 else{return}
        drewSelection=true
        func time(_ p:NSPoint)->Double{visibleStart+min(1,max(0,(p.x-plot.minX)/plot.width))*rangeDuration}
        func frequency(_ p:NSPoint)->Double{visibleLowFrequency+min(1,max(0,(p.y-plot.minY)/plot.height))*frequencySpan}
        selection=AudioSelection(start:min(time(anchor),time(current)),end:max(time(anchor),time(current)),minFrequency:min(frequency(anchor),frequency(current)),maxFrequency:max(frequency(anchor),frequency(current)))
    }
    override func mouseUp(with event:NSEvent){
        if !drewSelection && event.clickCount<2 {seek(event)}
        if let box=selection,box.end-box.start<0.05 || box.maxFrequency-box.minFrequency<50{selection=nil}
        dragAnchor=nil
    }
    func seek(_ event:NSEvent) {
        guard analysis != nil else{return}
        let point=convert(event.locationInWindow,from:nil)
        onSeek?(visibleStart+min(1,max(0,(point.x-plot.minX)/plot.width))*rangeDuration)
    }
}

class PreviewController: NSViewController {
    let graph=SpectrogramView()
    let heading=NSTextField(labelWithString:"AviaSpectra · 鸟鸣快速预览")
    let subtitle=NSTextField(labelWithString:"选择音频，查看声音随时间变化的频率结构")
    let analyzeSelectionButton=NSButton(title:"识别选框",target:nil,action:nil)
    let clearSelectionButton=NSButton(title:"清除",target:nil,action:nil)
    let restoreOverviewButton=NSButton(title:"返回整体",target:nil,action:nil)
    var recognitionID=UUID()
    let locationButton=NSButton(title:"地点：全球 ▾",target:nil,action:nil)
    var recordingLocation:RecordingLocation?
    let zoomInButton=NSButton(title:"+",target:nil,action:nil)
    let zoomOutButton=NSButton(title:"−",target:nil,action:nil)
    let fitButton=NSButton(title:"全览",target:nil,action:nil)
    var currentURL:URL?
    var detailWork:DispatchWorkItem?
    var detailToken=UUID()
    let play=NSButton(title:"▶ 播放",target:nil,action:nil)
    let autoplay=NSButton(checkboxWithTitle:"自动播放",target:nil,action:nil)
    let timerLabel=NSTextField(labelWithString:"00:00 / 00:00")
    let note=NSTextField(labelWithString:"点击声谱图跳转 · 空格播放/暂停 · Esc 关闭")
    let recognitionStatus=NSTextField(labelWithString:"AI 候选 · 等待音频")
    let recognitionSummary=NSTextField(labelWithString:"识别结果会在播放后逐段补充")
    let speciesRows=(0..<3).map{_ in SpeciesLinkRow(frame:.zero)}
    let moreCandidates=NSButton(title:"更多候选 ▾",target:nil,action:nil)
    var allCandidates:[BirdPrediction]=[]
    let speciesCard=FloatingSpeciesCard(frame:.zero)
    var recognitionJob:RecognitionJob?
    var recognitionStarted:Date?
    let progress=NSSlider(value:0,minValue:0,maxValue:1,target:nil,action:nil)
    var player:AVAudioPlayer?
    var timer:Timer?
    var token=UUID()
    var extraControls:NSView?
    override func loadView() {
        view=NSView(frame:NSRect(x:0,y:0,width:1040,height:800))
        view.wantsLayer=true;view.layer?.backgroundColor=NSColor(calibratedRed:0.06,green:0.08,blue:0.11,alpha:1).cgColor
        view.appearance=NSAppearance(named:.darkAqua)
        heading.font = .systemFont(ofSize:21,weight:.semibold);heading.textColor = .white
        subtitle.font = .systemFont(ofSize:12);subtitle.textColor = .secondaryLabelColor
        heading.lineBreakMode = .byTruncatingMiddle;subtitle.lineBreakMode = .byTruncatingMiddle
        note.font = .systemFont(ofSize:11);note.textColor = .secondaryLabelColor
        timerLabel.font = .monospacedDigitSystemFont(ofSize:12,weight:.medium)
        play.target=self;play.action = #selector(toggle);play.bezelStyle = .rounded;play.isEnabled=false
        progress.target=self;progress.action = #selector(slide);progress.isContinuous=true;progress.isEnabled=false
        let top=NSStackView(views:[heading,subtitle]);top.orientation = .vertical;top.alignment = .leading;top.spacing=8
        if let data=UserDefaults.standard.data(forKey:"AviaSpectraRecordingLocation"),let saved=try? JSONDecoder().decode(RecordingLocation.self,from:data){recordingLocation=saved;locationButton.title="地点：\(saved.name) ▾"}
        autoplay.state = .on
        zoomInButton.target=self;zoomInButton.action = #selector(zoomIn);zoomInButton.toolTip="等比例放大时间和频率；滚轮或捏合缩放，Option+滚动平移"
        zoomOutButton.target=self;zoomOutButton.action = #selector(zoomOut);zoomOutButton.toolTip="等比例缩小时间和频率"
        fitButton.target=self;fitButton.action = #selector(fitView);fitButton.toolTip="恢复全览；也可双击声谱图"
        for button in [zoomInButton,zoomOutButton,fitButton]{button.bezelStyle = .rounded}
        analyzeSelectionButton.target=self;analyzeSelectionButton.action = #selector(analyzeSelection);analyzeSelectionButton.isEnabled=false
        clearSelectionButton.target=self;clearSelectionButton.action = #selector(clearSelection);clearSelectionButton.isEnabled=false
        restoreOverviewButton.target=self;restoreOverviewButton.action = #selector(restoreOverview);restoreOverviewButton.isEnabled=false
        restoreOverviewButton.toolTip="清除选框，恢复完整频谱与整段识别结果"
        locationButton.target=self;locationButton.action = #selector(chooseLocation)
        let toolbar=NSStackView(views:[locationButton,analyzeSelectionButton,clearSelectionButton,restoreOverviewButton,zoomOutButton,zoomInButton,fitButton]);toolbar.orientation = .horizontal;toolbar.spacing=10
        let bottom=NSStackView(views:[play,progress,timerLabel,autoplay]);bottom.orientation = .horizontal;bottom.spacing=18
        recognitionStatus.font = .systemFont(ofSize:12,weight:.medium);recognitionStatus.textColor = .systemTeal
        recognitionSummary.font = .systemFont(ofSize:12);recognitionSummary.textColor = .labelColor
        recognitionSummary.lineBreakMode = .byTruncatingTail
        recognitionSummary.isHidden=true;note.isHidden=true
        speciesRows.forEach{$0.isHidden=true}
        moreCandidates.target=self;moreCandidates.action = #selector(showCandidates);moreCandidates.isBordered=false;moreCandidates.font = .systemFont(ofSize:11);moreCandidates.toolTip="选择候选以查看对应的时间分布";moreCandidates.isHidden=true
        let cardStack=NSStackView(views:speciesRows.map{$0 as NSView}+[moreCandidates]);cardStack.orientation = .vertical;cardStack.alignment = .leading;cardStack.spacing=4
        speciesCard.wantsLayer=true;speciesCard.layer?.backgroundColor=NSColor(calibratedRed:0.04,green:0.07,blue:0.10,alpha:0.88).cgColor;speciesCard.layer?.cornerRadius=9
        speciesCard.layer?.borderWidth=1;speciesCard.layer?.borderColor=NSColor(white:1,alpha:0.12).cgColor
        speciesCard.addSubview(cardStack);cardStack.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([cardStack.leadingAnchor.constraint(equalTo:speciesCard.leadingAnchor,constant:10),cardStack.trailingAnchor.constraint(equalTo:speciesCard.trailingAnchor,constant:-10),cardStack.centerYAnchor.constraint(equalTo:speciesCard.centerYAnchor)])
        for (i,row) in speciesRows.enumerated(){row.name.textColor=[NSColor.systemCyan,.systemOrange,.systemPink][i];row.heightAnchor.constraint(equalToConstant:20).isActive=true;row.widthAnchor.constraint(equalTo:cardStack.widthAnchor).isActive=true}
        graph.addSubview(speciesCard);graph.floatingCard=speciesCard;speciesCard.isHidden=true
        let recognition=NSStackView(views:[recognitionStatus,recognitionSummary]);recognition.orientation = .vertical;recognition.alignment = .leading;recognition.spacing=5
        let stack=NSStackView(views:[top,toolbar,graph,recognition,bottom,note]);stack.orientation = .vertical;stack.alignment = .leading;stack.spacing=18
        if let extras=extraControls { stack.insertArrangedSubview(extras,at:1) }
        view.addSubview(stack);stack.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:24),stack.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-24),stack.topAnchor.constraint(equalTo:view.topAnchor,constant:24),stack.bottomAnchor.constraint(equalTo:view.bottomAnchor,constant:-20),graph.widthAnchor.constraint(equalTo:stack.widthAnchor),graph.heightAnchor.constraint(greaterThanOrEqualToConstant:300),bottom.widthAnchor.constraint(equalTo:stack.widthAnchor),top.widthAnchor.constraint(equalTo:stack.widthAnchor),recognition.widthAnchor.constraint(equalTo:stack.widthAnchor),recognitionSummary.widthAnchor.constraint(equalTo:stack.widthAnchor),play.widthAnchor.constraint(equalToConstant:100)])
        graph.wantsLayer=true;graph.layer?.cornerRadius=12
        graph.onSelectionChanged={ [weak self] in
            guard let self=self else{return}
            let valid=self.graph.selection.map{$0.end-$0.start>=0.05 && $0.maxFrequency-$0.minFrequency>=50} ?? false
            self.analyzeSelectionButton.isEnabled=valid;self.clearSelectionButton.isEnabled=self.graph.selection != nil
        }
        graph.onViewportChanged={ [weak self] in self?.scheduleDetail() }
        graph.onSeek={ [weak self] time in self?.player?.currentTime=time;self?.updateTime() }
        preferredContentSize=NSSize(width:1040,height:800)
    }
    func load(_ url:URL, completion:((Error?)->Void)?=nil) {
        _=view;restoreOverviewButton.isEnabled=false;graph.selection=nil;fitButton.title="全览";currentURL=url;detailWork?.cancel();detailToken=UUID();graph.visibleStart=0;graph.visibleDuration=0;graph.visibleLowFrequency=0;graph.detailAnalysis=nil;graph.preferredSpecies=nil;graph.additionalCandidates=false;moreCandidates.isHidden=true;allCandidates=[];speciesCard.isHidden=true;speciesCard.userPosition=nil;speciesRows.forEach{$0.isHidden=true};recognitionJob?.cancel();recognitionJob=nil;graph.segments=[];recognitionStatus.isHidden=false;recognitionStatus.stringValue="识别中…";recognitionSummary.isHidden=true;recognitionSummary.stringValue="";player?.stop();timer?.invalidate();player=nil;graph.analysis=nil;progress.isEnabled=false;play.isEnabled=false
        let current=UUID();token=current
        heading.stringValue=url.lastPathComponent;subtitle.stringValue="正在计算声谱图…";play.title="▶ 播放"
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let result=Result { try AudioAnalysis.compute(url) }
            DispatchQueue.main.async { [weak self] in
                guard let self=self,self.token==current else{completion?(NSError(domain:"AviaSpectra",code:4));return}
                do {
                    let a=try result.get();let player=try AVAudioPlayer(contentsOf:url);player.prepareToPlay();self.player=player
                    self.graph.analysis=a;self.graph.position=0;self.progress.maxValue=a.duration;self.progress.doubleValue=0
                    self.play.isEnabled=true;self.progress.isEnabled=true;self.restoreOverviewButton.isEnabled=true
                    self.subtitle.stringValue=String(format:"%.1f 秒  ·  %.1f kHz  ·  %d 声道 ",player.duration,a.sampleRate/1000,player.numberOfChannels)
                    self.note.isHidden=player.duration<=a.duration+0.1;self.note.stringValue="仅预览前 120 秒"
                    self.timer=Timer.scheduledTimer(withTimeInterval:0.04,repeats:true){[weak self] _ in self?.updateTime()}
                    if self.autoplay.state == .on { player.play() }
                    self.updateTime();completion?(nil);self.recognize(url,current:current)
                } catch {self.subtitle.stringValue="无法读取：\(error.localizedDescription)";completion?(error)}
            }
        }
    }
    @objc func zoomIn(){graph.zoom(2)}
    @objc func zoomOut(){graph.zoom(0.5)}
    @objc func fitView(){graph.fit()}
    func scheduleDetail(){
        detailWork?.cancel();let detailID=UUID();detailToken=detailID
        guard let url=currentURL,let full=graph.analysis else{return}
        let start=graph.visibleStart,duration=graph.rangeDuration
        fitButton.title=duration<full.duration-0.001 ? String(format:"%.1f×",full.duration/duration) : "全览"
        fitButton.setAccessibilityLabel(String(format:"恢复全览，当前范围 %.2f 至 %.2f 秒",start,start+duration))
        if duration>=full.duration-0.001{return}
        let current=token
        let work=DispatchWorkItem{[weak self] in
            guard let self=self,self.token==current,self.detailToken==detailID else{return}
            let result=try? AudioAnalysis.compute(url,startTime:start,durationLimit:duration)
            DispatchQueue.main.async{[weak self] in
                guard let self=self,self.token==current,self.detailToken==detailID else{return}
                self.graph.detailAnalysis=result;self.graph.needsDisplay=true
            }
        }
        detailWork=work;DispatchQueue.global(qos:.userInitiated).asyncAfter(deadline:.now()+0.12,execute:work)
    }
    @objc func analyzeSelection(){
        guard let url=currentURL,let selection=graph.selection else{return}
        recognize(url,current:token,selection:selection)
    }
    @objc func clearSelection(){graph.selection=nil}
    @objc func restoreOverview(){
        guard let url=currentURL,graph.analysis != nil else{return}
        graph.selection=nil;graph.preferredSpecies=nil;speciesCard.userPosition=nil
        graph.fit()
        recognize(url,current:token)
    }
    func recognize(_ url:URL,current:UUID,selection:AudioSelection?=nil) {
        recognitionJob?.cancel();let requestID=UUID();recognitionID=requestID
        graph.segments=[];refreshCandidates();speciesCard.isHidden=true;recognitionStatus.isHidden=false;recognitionStatus.stringValue="识别中…"
        let job=RecognitionJob();recognitionJob=job;recognitionStarted=Date()
        job.run(url,selection:selection,location:recordingLocation,update:{[weak self] segment,progress,cached,elapsed in
            guard let self=self,self.token==current,self.recognitionID==requestID else{return}
            self.graph.segments.append(segment)
            self.refreshCandidates()
            self.recognitionStatus.stringValue=String(format:"识别中 %.0f%%",progress*100)
        },finish:{[weak self] error in
            guard let self=self,self.token==current,self.recognitionID==requestID else{return}
            self.recognitionJob=nil
            if let error=error{self.recognitionStatus.stringValue=error}
            else{self.recognitionStatus.isHidden=true;self.recognitionSummary.isHidden=self.recognitionSummary.stringValue.isEmpty}
        })
    }
    func refreshCandidates(){
        var best:[String:BirdPrediction]=[:]
        for segment in graph.segments {for bird in segment.predictions where bird.score>=0.5 {
            if bird.score>(best[bird.scientific]?.score ?? 0){best[bird.scientific]=bird}
        }}
        allCandidates=best.values.sorted{$0.score>$1.score}
        let ranked=graph.rankedBirds
        speciesCard.isHidden=ranked.isEmpty
        graph.additionalCandidates=allCandidates.count>3;moreCandidates.isHidden = !graph.additionalCandidates
        moreCandidates.title="更多候选 (\(max(0,allCandidates.count-3))) ▾"
        for (i,row) in speciesRows.enumerated(){row.isHidden=i>=ranked.count;if !row.isHidden{row.show(ranked[i])}}
        recognitionSummary.stringValue=ranked.isEmpty ? "未检出可靠候选" : "";recognitionSummary.isHidden=true
        graph.needsLayout=true;graph.needsDisplay=true
    }
    @objc func showCandidates(){
        let menu=NSMenu()
        for bird in allCandidates {
            let item=NSMenuItem(title:"\(bird.name) · \(bird.scientific) · \(String(format:"%.2f",bird.score))",action:#selector(selectCandidate(_:)),keyEquivalent:"")
            item.target=self;item.representedObject=bird.scientific
            item.state=graph.rankedBirds.contains(where:{$0.scientific==bird.scientific}) ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(positioning:nil,at:NSPoint(x:0,y:moreCandidates.bounds.maxY),in:moreCandidates)
    }
    @objc func selectCandidate(_ sender:NSMenuItem){graph.preferredSpecies=sender.representedObject as? String;refreshCandidates()}
    @objc func toggle() {guard let p=player else{return};if p.isPlaying{p.pause()}else{if p.currentTime >= (graph.analysis?.duration ?? p.duration)-0.05{p.currentTime=0};p.play()};updateTime()}
    @objc func slide() {player?.currentTime=progress.doubleValue;updateTime()}
    func updateTime() {
        guard let p=player else{return}
        if let a=graph.analysis,p.currentTime>=a.duration {p.pause()}
        graph.position=p.currentTime;progress.doubleValue=p.currentTime
        func fmt(_ t:Double)->String{String(format:"%02d:%02d",Int(t)/60,Int(t)%60)}
        timerLabel.stringValue="\(fmt(p.currentTime)) / \(fmt(graph.analysis?.duration ?? p.duration))"
        play.title=p.isPlaying ? "Ⅱ 暂停" : "▶ 播放"
    }
    override func viewDidDisappear(){super.viewDidDisappear();detailWork?.cancel();detailToken=UUID();token=UUID();player?.pause();timer?.invalidate();recognitionJob?.cancel()}
    deinit {recognitionJob?.cancel();timer?.invalidate();player?.stop()}
}
