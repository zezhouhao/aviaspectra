import AppKit

final class LocationForm:NSView {
    let preset=NSPopUpButton(frame:.zero,pullsDown:false)
    let latitude=NSTextField(string:"")
    let longitude=NSTextField(string:"")
    let placeName=NSTextField(string:"")
    let places:[RecordingLocation]=[
        .init(latitude:39.9042,longitude:116.4074,name:"北京"),.init(latitude:23.1291,longitude:113.2644,name:"广州"),
        .init(latitude:31.2304,longitude:121.4737,name:"上海"),.init(latitude:25.0389,longitude:102.7183,name:"昆明"),
        .init(latitude:20.044,longitude:110.1999,name:"海口"),.init(latitude:30.5728,longitude:104.0668,name:"成都")]
    init(location:RecordingLocation?){
        super.init(frame:NSRect(x:0,y:0,width:390,height:160))
        preset.addItems(withTitles:["全球（不限制）","自定义录音地点"]+places.map{$0.name})
        preset.target=self;preset.action = #selector(changePreset)
        latitude.placeholderString="−90 至 90";longitude.placeholderString="−180 至 180";placeName.placeholderString="可选"
        for (index,pair) in [("纬度",latitude),("经度",longitude),("地点名",placeName)].enumerated(){
            let label=NSTextField(labelWithString:pair.0);label.frame=NSRect(x:0,y:86-index*30,width:60,height:22)
            pair.1.frame=NSRect(x:70,y:86-index*30,width:310,height:22);addSubview(label);addSubview(pair.1)
        }
        preset.frame=NSRect(x:0,y:120,width:380,height:26);addSubview(preset)
        if let location=location{preset.selectItem(at:1);latitude.stringValue=String(location.latitude);longitude.stringValue=String(location.longitude);placeName.stringValue=location.name}
        changePreset()
    }
    required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
    @objc func changePreset(){
        let index=preset.indexOfSelectedItem
        for field in [latitude,longitude,placeName]{field.isEnabled=index != 0}
        if index>=2 {let p=places[index-2];latitude.stringValue=String(p.latitude);longitude.stringValue=String(p.longitude);placeName.stringValue=p.name}
    }
    func result() throws -> RecordingLocation? {
        if preset.indexOfSelectedItem==0{return nil}
        guard let lat=Double(latitude.stringValue),let lon=Double(longitude.stringValue),lat.isFinite,lon.isFinite,(-90...90).contains(lat),(-180...180).contains(lon) else {
            throw NSError(domain:"AviaSpectraLocation",code:1,userInfo:[NSLocalizedDescriptionKey:"请输入有效的纬度（−90 至 90）和经度（−180 至 180）。"])
        }
        return RecordingLocation(latitude:lat,longitude:lon,name:placeName.stringValue.isEmpty ? String(format:"%.2f, %.2f",lat,lon) : placeName.stringValue)
    }
}

extension PreviewController {
    @objc func chooseLocation(){
        let alert=NSAlert();alert.messageText="录音地点";alert.informativeText="按录音地点筛选全年可能出现的物种。未知地点请选全球。"
        alert.addButton(withTitle:"应用");alert.addButton(withTitle:"取消")
        let form=LocationForm(location:recordingLocation);alert.accessoryView=form
        let apply:(NSApplication.ModalResponse)->Void = {[weak self] response in
            guard let self=self,response == .alertFirstButtonReturn else{return}
            do {
                self.recordingLocation=try form.result()
                self.locationButton.title="地点：\(self.recordingLocation?.name ?? "全球") ▾"
                if let data=try? JSONEncoder().encode(self.recordingLocation){UserDefaults.standard.set(data,forKey:"AviaSpectraRecordingLocation")}
                if let url=self.currentURL {self.recognize(url,current:self.token,selection:self.graph.selection)}
            } catch {
                let notice=NSAlert(error:error);if let window=self.view.window{notice.beginSheetModal(for:window)}
            }
        }
        if let window=view.window{alert.beginSheetModal(for:window,completionHandler:apply)}else{apply(alert.runModal())}
    }
}
