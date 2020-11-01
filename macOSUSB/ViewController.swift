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
	@IBOutlet weak var volumesBox: NSComboBox!
	@IBOutlet weak var iconView: NSImageView!
	@IBOutlet weak var spinningIndicator: NSProgressIndicator!
	
	var installers_path = "/Volumes/1TB/MacInstallers" //"/Applications"
	var macOS_installers : [String] = []
	var installer_names : [String] = []
	var volumes : [String] = []
	var icon : String = ""
	
	func getVersion(application: String) -> String {
		return String(describing: NSDictionary.init(contentsOfFile: "\(installers_path)/\(application)/Contents/version.plist")!["CFBundleShortVersionString"] ?? "0.0.0")
	}
	
	func isOlderThanHSierra(_ installer: String) -> Bool{
		let version = getVersion(application: installer)
		let majorRelease = Int(version.split(separator: ".")[0])!
		return (majorRelease < 13)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		installerBox.delegate = self
		
		let fileManager = FileManager.default
		
		let applications = try? fileManager.contentsOfDirectory(atPath: installers_path)
		if applications != nil{
			macOS_installers = applications!.filter{ $0.prefix(4) == "Inst"}
		}
		
		installer_names = macOS_installers.map{
			let releaseName = $0.split(separator: " ")[2].split(separator: ".")[0]
			let version = getVersion(application: $0)
			return "\(releaseName) (\(version))"
		}
		installerBox.addItems(withObjectValues: installer_names)
		
		volumes = try! fileManager.contentsOfDirectory(atPath: "/Volumes")
		volumesBox.addItems(withObjectValues: volumes)
		
		if installer_names != [] {
			installerBox.selectItem(at: 0)
		} else {
			NSLog("No installers found.")
			//NSApplication.shared.mainMenu?.item(at: 1)?._highlightItem()
		}
		
		volumesBox.selectItem(at: volumes.count - 1 )
	}
	
	func comboBoxSelectionDidChange(_ notification: Notification){
		let insTag = installerBox.indexOfSelectedItem
		icon = "\(installers_path)/\(macOS_installers[insTag])/Contents/Resources/ProductPageIcon.icns"
		iconView.image = NSImage(contentsOfFile: icon)
		iconView.isHidden = false
	}
	
	@IBAction func startProcess(_ sender: NSButton) {
		
		let alert = NSAlert()
		
		alert.addButton(withTitle: "Start")
		alert.addButton(withTitle: "Cancel")
		
		alert.buttons[0].keyEquivalent = ""
		alert.buttons[1].keyEquivalent = "\r" // Makes Cancel the default button
		alert.messageText = "Are you sure?"
		alert.informativeText = "This will erase the selected drive to place the macOS installer. The process will take from 5 to 10 minutes. Go take some coffee in the meantime :-)"
		alert.alertStyle = .warning
		alert.icon = NSImage(contentsOfFile: icon)
		
		
		alert.beginSheetModal(for: self.view.window!){ (modalResponse) -> Void in
			if modalResponse == .alertFirstButtonReturn {
				// *[macOSReleaseName].app/path_to_executable
				let installer = "*\(self.installer_names[self.installerBox.indexOfSelectedItem].split(separator: " ")[0]).app"
				let drive = self.volumes[self.volumesBox.indexOfSelectedItem].replacingOccurrences(of: " ", with: "*")
				let cmd = "\(self.installers_path)/\(installer)/Contents/Resources/createinstallmedia --volume /Volumes/\(drive) --applicationpath \(self.installers_path)/\(installer) --nointeraction"
				
				/*if self.isOlderThanHSierra(installer){
				cmd += " --applicationpath \(installers_path)/\(installer)" // Must verify if this argument can be used in High Sierra and newer too.
				}*/
				
				let background = DispatchQueue(label: "Process")
				// I call this constant "background" just for readability. The actual QoS is 'default', but it doensn't matter in this case
				
				sender.title = ""
				sender.isEnabled = false
				self.installerBox.isEnabled = false
				self.volumesBox.isEnabled = false
				self.spinningIndicator.isHidden = false
				self.spinningIndicator.startAnimation(nil)
				
				
				background.async{
					let process = Process()
					process.launchPath = "/usr/bin/osascript"
					process.arguments = ["-e","do shell script \"\(cmd)\" with administrator privileges"]
					
					let pipe = Pipe()
					process.standardOutput = pipe
					process.launch()
					process.waitUntilExit()
					
					let outHandle = pipe.fileHandleForReading
					outHandle.waitForDataInBackgroundAndNotify()
					/*
					var observer : NSObjectProtocol!
					observer = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outHandle, queue: nil) {  notification -> Void in
					let data = outHandle.availableData
					if data.count > 0 {
					if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
					NSLog("Got output: \(str)")
					}
					outHandle.waitForDataInBackgroundAndNotify()
					} else {
					NSLog("Finished.")
					NotificationCenter.default.removeObserver(observer!)
					}
					}
					*/
					
					let data = outHandle.readDataToEndOfFile() //Result of the terminal command in raw data form
					let response = String(data: data, encoding: .utf8)
					
					NSLog(response ?? "No Output :-/")
					
					DispatchQueue.main.async {
						sender.title = "Prepare USB"
						sender.isEnabled = true
						self.installerBox.isEnabled = true
						self.volumesBox.isEnabled = true
						self.spinningIndicator.isHidden = true
						self.spinningIndicator.stopAnimation(nil)
						
						let alert2 = NSAlert()
						alert2.messageText = "Done :-)"
						alert2.alertStyle = .informational
						alert2.icon = NSImage(contentsOfFile: self.icon)
						alert2.addButton(withTitle: "Great!")
						alert2.beginSheetModal(for: self.view.window!, completionHandler: nil)
					}
				}
			}
		}
	}
}
