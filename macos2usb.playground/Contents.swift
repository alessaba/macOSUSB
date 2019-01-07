import Cocoa
import Foundation

var macOS_installers : [String] = []
var installerBox = NSComboBox()

let fileManager = FileManager.default
let applications = try? fileManager.contentsOfDirectory(atPath: "/Applications")
if applications != nil{
    macOS_installers = applications!.filter{ $0.prefix(4) == "Inst"}
}
installerBox.addItems(withObjectValues:
    macOS_installers
        .map{
            let releaseName = $0.split(separator: " ")[2].split(separator: ".")[0]
            let version = String(describing: NSDictionary.init(contentsOfFile: "/Applications/\($0)/Contents/version.plist")!["CFBundleShortVersionString"]!)
            return "\(releaseName) (\(version))"
            })

let a : String = "Mojave (10.14.2)"
let installer = "/Applications/*\(a.split(separator: " ")[0]).app"

NSDictionary.init(contentsOfFile: "/Applications/Install macOS Mojave.app/Contents/version.plist")?["CFBundleShortVersionString"]

let process = Process()
process.launchPath = "/usr/bin/osascript"
process.arguments = ["-e","do shell script \"ls \(installer)\" with administrator privileges"]

let pipe = Pipe()
process.standardOutput = pipe
process.launch()

var data = pipe.fileHandleForReading.readDataToEndOfFile()
var result_s = String(data: data, encoding: .utf8)


