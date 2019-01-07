//
//  ViewController.swift
//  macOSUSB
//
//  Created by Alessandro Saba on 06/01/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, NSComboBoxDelegate {

    @IBOutlet weak var installerBox: NSComboBox!
    @IBOutlet weak var driveBox: NSComboBox!
    @IBOutlet weak var iconView: NSImageView!
    
    var macOS_installers : [String] = []
    var volumes : [String] = []
    
    var icon : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installerBox.delegate = self
        
        installerBox.isEditable = false
        driveBox.isEditable = false
        
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
        
        volumes = try! fileManager.contentsOfDirectory(atPath: "/Volumes")
        driveBox.addItems(withObjectValues: volumes)
        
        installerBox.selectItem(at: 0)
        driveBox.selectItem(at: volumes.count - 1 )
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification){
        let insTag = installerBox.indexOfSelectedItem
        icon = "/Applications/\(macOS_installers[insTag])/Contents/Resources/ProductPageIcon.icns"
        iconView.image = NSImage(contentsOfFile: icon)
        iconView.isHidden = false
    }
    
    @IBAction func startProcess(_ sender: NSButton) {
        
        let alert = NSAlert()
        
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        
        alert.buttons[0].keyEquivalent = ""
        alert.buttons[1].keyEquivalent = "\r" // Makes Cancel the default button
        
        
        alert.messageText = "Are you sure? This will erase the selected drive to place the macOS installer"
        alert.alertStyle = .warning
        alert.icon = NSImage(contentsOfFile: icon)
        
        
        alert.beginSheetModal(for: self.view.window!){ (modalResponse) -> Void in
            if modalResponse == .alertFirstButtonReturn {
                
                let installer = self.macOS_installers[self.installerBox.indexOfSelectedItem]//.replacingOccurrences(of: " ", with: "\\ ")
                let drive = self.volumes[self.driveBox.indexOfSelectedItem]//.replacingOccurrences(of: " ", with: "\\ ")
                
                
                let cmd = "/Applications/\(installer)/Contents/Resources/createinstallmedia --volume /Volumes/\(drive) --nointeraction"
                
                let process = Process()
                process.launchPath = "/usr/bin/osascript"
                process.arguments = ["-e","do shell script \"\(cmd)\" with administrator privileges"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.launch()
                
                sender.title = "Wait..."
                sender.isEnabled = false
                self.installerBox.isEnabled = false
                self.driveBox.isEnabled = false
                
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let response = String(data: data, encoding: .utf8)
                
                NSLog(response ?? "No Output :-/")
                
                sender.title = "Prepare USB"
                sender.isEnabled = true
                self.installerBox.isEnabled = true
                self.driveBox.isEnabled = true
                
                let alert2 = NSAlert()
                alert2.messageText = "Done :-)"
                alert2.alertStyle = .informational
                alert2.icon = NSImage(contentsOfFile: self.icon)
                alert2.runModal()
                
            }
        }
    }
}
