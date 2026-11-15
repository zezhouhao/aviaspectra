import AppKit

struct SpeciesURLs {
    static let codes:[String:String] = {
        guard let url=Bundle.main.url(forResource:"ebird_codes",withExtension:"json"),
              let data=try? Data(contentsOf:url),let mapping=try? JSONDecoder().decode([String:String].self,from:data) else{return [:]}
        return mapping
    }()
    static func xc(_ bird:BirdPrediction)->URL? {
        guard bird.scientific.range(of:"^[A-Z][a-z]+ [a-z]+$",options:.regularExpression) != nil,
              !["Human vocal","Human non-vocal","Power tools"].contains(bird.scientific) else{return nil}
        return URL(string:"https://xeno-canto.org/species/"+bird.scientific.replacingOccurrences(of:" ",with:"-"))
    }
    static func ebird(_ bird:BirdPrediction)->URL? {
        guard xc(bird) != nil,let code=codes[bird.scientific+"_"+bird.english],
              code.range(of:"^[a-z0-9]+$",options:.regularExpression) != nil else{return nil}
        return URL(string:"https://ebird.org/species/"+code)
    }
}

final class SpeciesLinkRow:NSStackView {
    let name=NSTextField(labelWithString:"")
    let latin=NSButton(title:"",target:nil,action:nil)
    let ebird=NSButton(title:"eBird ↗",target:nil,action:nil)
    let score=NSTextField(labelWithString:"")
    var xcURL:URL?
    var ebirdURL:URL?
    // Injectable for action-routing tests; production uses the user's default browser.
    var openURL:(URL)->Bool = {NSWorkspace.shared.open($0)}
    var requestOpenURL:((URL,@escaping(Bool)->Void)->Void)?
    override init(frame frameRect:NSRect) {
        super.init(frame:frameRect);orientation = .horizontal;alignment = .centerY;spacing=12
        name.font = .systemFont(ofSize:16,weight:.semibold)
        name.lineBreakMode = .byTruncatingTail
        score.font = .monospacedDigitSystemFont(ofSize:13,weight:.regular);score.textColor = .secondaryLabelColor;score.toolTip="模型最高窗口置信度，不代表识别准确率"
        latin.isBordered=false;latin.bezelStyle = .inline;latin.target=self;latin.action = #selector(openXC)
        ebird.bezelStyle = .rounded;ebird.font = .systemFont(ofSize:14,weight:.medium);ebird.target=self;ebird.action = #selector(openEBird)
        ebird.heightAnchor.constraint(equalToConstant:30).isActive=true
        ebird.widthAnchor.constraint(equalToConstant:88).isActive=true
        ebird.setContentCompressionResistancePriority(.required,for:.horizontal)
        score.setContentCompressionResistancePriority(.required,for:.horizontal)
        let spacer=NSView();spacer.setContentHuggingPriority(.defaultLow,for:.horizontal)
        [name,latin,spacer,score,ebird].forEach{addArrangedSubview($0)}
        name.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(751),for:.horizontal)
        latin.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        latin.cell?.lineBreakMode = .byTruncatingTail
    }
    required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
    func show(_ bird:BirdPrediction) {
        name.stringValue=bird.name;name.toolTip=bird.name
        score.stringValue=String(format:"置信度 %.2f",bird.score)
        xcURL=SpeciesURLs.xc(bird);ebirdURL=SpeciesURLs.ebird(bird)
        latin.attributedTitle=NSAttributedString(string:bird.scientific+" ↗",attributes:[.font:NSFont.systemFont(ofSize:15),.foregroundColor:xcURL == nil ? NSColor.labelColor : NSColor.systemTeal,.underlineStyle:xcURL == nil ? 0 : NSUnderlineStyle.single.rawValue])
        latin.isEnabled=xcURL != nil;latin.toolTip=xcURL.map{"打开 XC 物种页："+$0.absoluteString}
        latin.setAccessibilityLabel(bird.scientific+"，打开 XC 物种页")
        ebird.isHidden=false;ebird.isEnabled=ebirdURL != nil
        ebird.toolTip=ebirdURL?.absoluteString ?? "当前物种暂无 eBird 对应页面"
        ebird.setAccessibilityLabel(bird.scientific+"，打开 eBird 物种页")
    }
    private func openLink(_ url:URL?) {
        guard let url=url else{return}
        if let request=requestOpenURL {
            request(url){[weak self] ok in DispatchQueue.main.async{if !ok{self?.showOpenFailure(url)}}};return
        }
        if openURL(url){return}
        showOpenFailure(url)
    }
    private func showOpenFailure(_ url:URL) {
        let alert=NSAlert();alert.messageText="未能打开浏览器";alert.informativeText="可复制链接后在浏览器中打开。\n"+url.absoluteString
        alert.addButton(withTitle:"复制链接");alert.addButton(withTitle:"取消")
        let finish:(NSApplication.ModalResponse)->Void={response in
            if response == .alertFirstButtonReturn {NSPasteboard.general.clearContents();NSPasteboard.general.setString(url.absoluteString,forType:.string)}
        }
        if let window=window{alert.beginSheetModal(for:window,completionHandler:finish)}else{finish(alert.runModal())}
    }
    @objc func openXC(){openLink(xcURL)}
    @objc func openEBird(){openLink(ebirdURL)}
}
