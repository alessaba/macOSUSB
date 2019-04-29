//
//  AppDelegate.swift
//  macOSUSB
//
//  Created by Alessandro Saba on 06/01/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
    
    @IBAction func downloadMacOs(_ sender: Any) {
        let appStoreLink = URL(string: "https://itunes.apple.com/la/app/macos-mojave/id1398502828?ls=1&mt=12")
        NSWorkspace.shared.open(appStoreLink!)
    }
    
    
}
