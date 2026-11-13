import AppKit
import QuickLookUI
@objc(AviaSpectraQuickLookController)
final class AviaSpectraQuickLookController:PreviewController,QLPreviewingController {
    func preparePreviewOfFile(at url:URL,completionHandler handler:@escaping(Error?)->Void){load(url,completion:handler)}
}
@_silgen_name("NSExtensionMain")
func NSExtensionMain(_ argc:Int32,_ argv:UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>)->Int32
@main struct ExtensionEntry {
    static func main(){exit(NSExtensionMain(CommandLine.argc,CommandLine.unsafeArgv))}
}
