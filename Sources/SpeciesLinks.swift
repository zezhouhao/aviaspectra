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
    override init(frame frameRect:NSRect) {
        super.init(frame:frameRect);orientation = .horizontal;alignment = .centerY;spacing=10
        name.font = .systemFont(ofSize:12);score.font = .monospacedDigitSystemFont(ofSize:12,weight:.regular);score.textColor = .secondaryLabelColor;score.toolTip="模型最高窗口评分，不代表识别准确率"
        for button in [latin,ebird] {button.isBordered=false;button.bezelStyle = .inline;button.target=self}
        latin.action = #selector(openXC);ebird.action = #selector(openEBird)
        ebird.attributedTitle=NSAttributedString(string:"eBird ↗",attributes:[.foregroundColor:NSColor.systemTeal,.underlineStyle:NSUnderlineStyle.single.rawValue,.font:NSFont.systemFont(ofSize:12)])
        [name,latin,score,ebird].forEach{addArrangedSubview($0)}
        latin.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        latin.cell?.lineBreakMode = .byTruncatingTail
    }
    required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
    func show(_ bird:BirdPrediction) {
        name.stringValue=bird.name;score.stringValue=String(format:"评分 %.2f",bird.score)
        xcURL=SpeciesURLs.xc(bird);ebirdURL=SpeciesURLs.ebird(bird)
        latin.attributedTitle=NSAttributedString(string:bird.scientific,attributes:[.font:NSFont.systemFont(ofSize:12),.foregroundColor:xcURL == nil ? NSColor.labelColor : NSColor.systemTeal,.underlineStyle:xcURL == nil ? 0 : NSUnderlineStyle.single.rawValue])
        latin.isEnabled=xcURL != nil;latin.toolTip=xcURL.map{"打开 XC 物种页："+$0.absoluteString}
        latin.setAccessibilityLabel(bird.scientific+"，打开 XC 物种页")
        ebird.isHidden=ebirdURL == nil;ebird.toolTip=ebirdURL?.absoluteString
        ebird.setAccessibilityLabel(bird.scientific+"，打开 eBird 物种页")
    }
    @objc func openXC(){if let url=xcURL{let ok=NSWorkspace.shared.open(url);NSLog("AviaSpectra open XC result %d",ok ? 1 : 0)}}
    @objc func openEBird(){if let url=ebirdURL{NSWorkspace.shared.open(url)}}
}

final class FloatingSpeciesCard:NSView {
    private var dragStart:NSPoint?
    private var originStart=NSPoint.zero
    var userPosition:NSPoint?
    override func mouseDown(with event:NSEvent){dragStart=event.locationInWindow;originStart=frame.origin}
    override func mouseDragged(with event:NSEvent){
        guard let start=dragStart,let parent=superview else{return}
        let dx=event.locationInWindow.x-start.x,dy=event.locationInWindow.y-start.y
        let origin=NSPoint(x:min(parent.bounds.width-frame.width-10,max(10,originStart.x+dx)),y:min(parent.bounds.height-frame.height-10,max(10,originStart.y+dy)))
        setFrameOrigin(origin);userPosition=origin
    }
}
