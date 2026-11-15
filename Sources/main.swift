import AppKit
import UniformTypeIdentifiers

if CommandLine.arguments.count == 4 && CommandLine.arguments[1] == "--analyse" {
    do {
        let a=try AudioAnalysis.compute(URL(fileURLWithPath:CommandLine.arguments[2]))
        let bitmap=NSBitmapImageRep(data:a.image.tiffRepresentation!)!
        try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[3]))
        print("{\"duration\":\(a.duration),\"sample_rate\":\(a.sampleRate),\"peak_hz\":\(a.peakFrequency),\"columns\":\(a.columns)}")
        exit(0)
    } catch {fputs("\(error)\n",stderr);exit(1)}
}

if (CommandLine.arguments.count == 4 && CommandLine.arguments[1] == "--recognize") || ((CommandLine.arguments.count==8 || CommandLine.arguments.count==10) && CommandLine.arguments[1]=="--recognize-box") {
    let args=CommandLine.arguments
    let selected=args[1]=="--recognize-box"
    let box:AudioSelection? = selected ? AudioSelection(start:Double(args[3])!,end:Double(args[4])!,minFrequency:Double(args[5])!,maxFrequency:Double(args[6])!) : nil
    let location:RecordingLocation? = args.count==10 ? RecordingLocation(latitude:Double(args[8])!,longitude:Double(args[9])!,name:"test") : nil
    let outputPath=selected ? args[7] : args[3]
    let job=RecognitionJob();var done=false;var records:[[String:Any]]=[];var failure:String?
    let start=Date()
    job.run(URL(fileURLWithPath:CommandLine.arguments[2]),selection:box,location:location,update:{segment,progress,cached,elapsed in
        records.append(["start":segment.start,"end":segment.end,"progress":progress,"cached":cached,"elapsed":elapsed,
                        "predictions":segment.predictions.map{["scientific":$0.scientific,"name":$0.name,"score":$0.score] as [String:Any]}])
    },finish:{error in failure=error;done=true})
    while !done && Date().timeIntervalSince(start)<90 {RunLoop.current.run(until:Date().addingTimeInterval(0.05))}
    if !done{job.cancel();failure="timeout"}
    let report:[String:Any]=["segments":records,"elapsed":Date().timeIntervalSince(start),"error":failure as Any? ?? NSNull()]
    try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:outputPath))
    print("segments=\(records.count), elapsed=\(Date().timeIntervalSince(start)), error=\(failure ?? "none")")
    exit(failure == nil ? 0 : 1)
}

if CommandLine.arguments.count==3 && CommandLine.arguments[1]=="--check-zoom" {
    let url=URL(fileURLWithPath:CommandLine.arguments[2]);let full=try AudioAnalysis.compute(url)
    let graph=SpectrogramView(frame:NSRect(x:0,y:0,width:1000,height:600));graph.analysis=full
    let anchor=full.duration*0.4;let frequencyAnchor=full.maxFrequency*0.3;graph.zoom(4,anchor:0.4,frequencyAnchor:0.3)
    precondition(abs(graph.visibleLowFrequency+graph.frequencySpan*0.3-frequencyAnchor)<0.0001)
    precondition(abs(full.duration/graph.rangeDuration-full.maxFrequency/graph.frequencySpan)<0.0001)
    precondition(abs(graph.visibleStart+graph.rangeDuration*0.4-anchor)<0.0001)
    graph.selection=AudioSelection(start:1,end:2,minFrequency:2000,maxFrequency:6000)
    let detail=try AudioAnalysis.compute(url,startTime:graph.visibleStart,durationLimit:graph.rangeDuration)
    precondition(abs(detail.startTime-graph.visibleStart)<0.0001)
    precondition(abs(detail.duration-full.duration/4)<0.001)
    graph.zoom(4);precondition(graph.selection?.start==1 && graph.selection?.end==2 && graph.selection?.minFrequency==2000 && graph.selection?.maxFrequency==6000)
    precondition(abs(full.duration/graph.rangeDuration-full.maxFrequency/graph.frequencySpan)<0.0001)
    precondition(graph.visibleLowFrequency>=0 && graph.frequencyEnd<=full.maxFrequency+0.0001)
    graph.setViewport(start:99999,duration:0.1);precondition(graph.rangeEnd<=full.duration+0.0001)
    graph.fit();precondition(graph.visibleLowFrequency==0 && abs(graph.frequencySpan-full.maxFrequency)<0.0001)
    precondition(graph.visibleStart==0 && abs(graph.rangeDuration-full.duration)<0.0001)
    print("Isotropic time/frequency zoom, both anchors, boundaries, local FFT and absolute selection preservation: PASS");exit(0)
}

if CommandLine.arguments.count==3 && CommandLine.arguments[1]=="--check-restore" {
    _=NSApplication.shared
    let url=URL(fileURLWithPath:CommandLine.arguments[2]),controller=PreviewController()
    _=controller.view;controller.recordingLocation=nil;controller.currentURL=url
    controller.graph.analysis=try AudioAnalysis.compute(url)
    func waitForRecognition(){
        let deadline=Date().addingTimeInterval(30)
        while controller.recognitionJob != nil && Date()<deadline{RunLoop.current.run(until:Date().addingTimeInterval(0.02))}
        precondition(controller.recognitionJob == nil && controller.recognitionStatus.isHidden)
    }
    controller.recognize(url,current:controller.token);waitForRecognition()
    let baseline=controller.graph.segments
    precondition(baseline.count>1)
    controller.graph.zoom(4)
    controller.graph.selection=AudioSelection(start:1,end:4,minFrequency:1000,maxFrequency:10000)
    controller.analyzeSelection();waitForRecognition()
    precondition(controller.graph.segments.allSatisfy{$0.start>=1 && $0.end<=4.001})
    controller.clearSelection() // Returning must also work after the box has been cleared.
    controller.restoreOverview();waitForRecognition()
    precondition(controller.graph.selection == nil && controller.graph.visibleStart==0 && controller.graph.visibleLowFrequency==0)
    precondition(abs(controller.graph.rangeDuration-controller.graph.analysis!.duration)<0.001)
    precondition(controller.graph.segments.count==baseline.count)
    for (a,b) in zip(controller.graph.segments,baseline){precondition(a.start==b.start && a.end==b.end && a.predictions.map{$0.scientific}==b.predictions.map{$0.scientific})}
    controller.graph.selection=AudioSelection(start:1,end:4,minFrequency:1000,maxFrequency:10000)
    controller.analyzeSelection();controller.restoreOverview();waitForRecognition()
    precondition(controller.graph.segments.count==baseline.count && controller.graph.selection == nil)
    print("Whole -> selection -> clear -> restore, full candidates/timeline, viewport reset and in-flight cancellation: PASS");exit(0)
}

if CommandLine.arguments.count==2 && CommandLine.arguments[1]=="--check-results" {
    _=NSApplication.shared
    func verify(_ condition:@autoclosure()->Bool,_ message:String="",line:Int=#line){
        if !condition(){fputs("Result UI check failed at line \(line): \(message)\n",stderr);exit(1)}
    }
    let birds=[BirdPrediction(scientific:"Campylorhamphus falcularius",name:"黑嘴镰嘴䴕雀",english:"Black-billed Scythebill",score:0.99),BirdPrediction(scientific:"Passerina ciris",name:"丽彩鹀",english:"Painted Bunting",score:0.90),BirdPrediction(scientific:"Corvus corone",name:"小嘴乌鸦",english:"Carrion Crow",score:0.80)]
    for width in [850.0,1080.0] {for count in [1,3] {
        let controller=PreviewController();let window=NSWindow(contentRect:NSRect(x:0,y:0,width:width,height:820),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
        let host=NSView(frame:NSRect(x:0,y:0,width:width,height:820));window.contentView=host
        host.addSubview(controller.view);controller.view.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([controller.view.leadingAnchor.constraint(equalTo:host.leadingAnchor),controller.view.trailingAnchor.constraint(equalTo:host.trailingAnchor),controller.view.topAnchor.constraint(equalTo:host.topAnchor),controller.view.bottomAnchor.constraint(equalTo:host.bottomAnchor)])
        controller.graph.segments=[BirdSegment(start:0,end:3,predictions:Array(birds.prefix(count)))];controller.refreshCandidates()
        controller.preferredContentSize=NSSize(width:width,height:820);window.setContentSize(NSSize(width:width,height:820));host.setFrameSize(NSSize(width:width,height:820))
        host.needsLayout=true;controller.view.needsLayout=true;host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until:Date().addingTimeInterval(0.05));host.layoutSubtreeIfNeeded()
        verify(abs(controller.view.frame.width-width)<0.1,"Test host did not apply requested width")
        verify(controller.speciesPanel.superview !== controller.graph && !controller.speciesPanel.isHidden)
        verify(controller.speciesPanel.frame.width>=width-50)
        for row in controller.speciesRows where !row.isHidden {
            verify(row.name.font!.pointSize>=16 && row.ebird.isEnabled)
            let rect=row.ebird.convert(row.ebird.bounds,to:controller.view)
            let point=NSPoint(x:rect.midX,y:rect.midY)
            let hit=controller.view.hitTest(point)
            verify(hit === row.ebird || hit?.isDescendant(of:row.ebird)==true,"eBird hit target blocked")
            verify(row.ebird.bounds.width>=88 && row.ebird.bounds.height>=30)
            verify(controller.speciesPanel.bounds.contains(controller.speciesPanel.convert(rect,from:controller.view)),"eBird outside fixed panel")
            var opened:[URL]=[];row.openURL={opened.append($0);return true}
            row.ebird.performClick(nil);row.latin.performClick(nil)
            verify(opened.count==2 && opened[0]==row.ebirdURL && opened[1]==row.xcURL)
            verify(opened[0].absoluteString.hasPrefix("https://ebird.org/species/"))
        }
        print("Result rows: width=\(width), candidates=\(count), bounds + hit targets + eBird/XC actions: PASS")
    }}
    let row=SpeciesLinkRow(frame:.zero)
    row.show(BirdPrediction(scientific:"Human vocal",name:"人声",english:"Human vocal",score:0.9))
    verify(!row.ebird.isEnabled && !row.latin.isEnabled)
    print("Unknown/non-bird links disabled: PASS");exit(0)
}

final class AppDelegate:NSObject,NSApplicationDelegate,NSWindowDelegate {
    var window:NSWindow!
    let controller=PreviewController()
    var keyMonitor:Any?
    func applicationDidFinishLaunching(_ notification:Notification) {
        let menu=NSMenu();let appItem=NSMenuItem();menu.addItem(appItem);let appMenu=NSMenu();appItem.submenu=appMenu
        appMenu.addItem(withTitle:"退出 AviaSpectra",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")
        let fileItem=NSMenuItem();menu.addItem(fileItem);let fileMenu=NSMenu(title:"文件");fileItem.submenu=fileMenu
        let openItem=fileMenu.addItem(withTitle:"打开音频…",action:#selector(openFile),keyEquivalent:"o");openItem.target=self;NSApp.mainMenu=menu
        let buttons=NSStackView();buttons.orientation = .horizontal;buttons.spacing=10
        let open=NSButton(title:"打开其它音频…",target:self,action:#selector(openFile));open.bezelStyle = .rounded;buttons.addArrangedSubview(open)
        controller.extraControls=buttons
        window=NSWindow(contentRect:NSRect(x:0,y:0,width:1080,height:820),styleMask:[.titled,.closable,.miniaturizable,.resizable],backing:.buffered,defer:false)
        window.title="AviaSpectra 谱羽 · 鸟鸣声谱预览 1.0.1";window.contentViewController=controller;window.minSize=NSSize(width:850,height:700);window.delegate=self;window.center();window.makeKeyAndOrderFront(nil)
        keyMonitor=NSEvent.addLocalMonitorForEvents(matching:.keyDown){[weak self] event in
            guard let self=self,self.window.isKeyWindow,!(self.window.firstResponder is NSTextView) else{return event}
            if event.keyCode==49 && event.modifierFlags.intersection([.command,.control,.option]).isEmpty {self.controller.toggle();return nil}
            if event.keyCode==53 {self.window.close();return nil};return event
        }
        NSApp.activate(ignoringOtherApps:true)
        let files=CommandLine.arguments.dropFirst().filter{!$0.hasPrefix("-") && FileManager.default.fileExists(atPath:$0)}
        if let first=files.first{controller.load(URL(fileURLWithPath:first))}else{controller.recognitionStatus.isHidden=true}
    }
    @objc func openFile(){let p=NSOpenPanel();p.allowedContentTypes=[.audio];p.allowsMultipleSelection=false;if p.runModal() == .OK,let u=p.url{controller.load(u)}}
    func application(_ sender:NSApplication,openFiles filenames:[String]){if let name=filenames.first{controller.load(URL(fileURLWithPath:name))};sender.reply(toOpenOrPrint:.success)}
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{true}
    func windowWillClose(_ notification:Notification){controller.player?.stop()}
}
let delegate=AppDelegate()
NSApplication.shared.setActivationPolicy(.regular)
NSApplication.shared.delegate=delegate
NSApplication.shared.run()
