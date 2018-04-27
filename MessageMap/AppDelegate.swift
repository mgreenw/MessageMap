//
//  AppDelegate.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/12/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
        
	}

	func applicationWillTerminate(_ aNotification: Notification) {

	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
    // This function is called by the menu item "Update Databases" and accessed from anywhere by pressing Cmd-R
	@IBAction func updateDatabase(sender: NSMenuItem) {
		startDatabaseUpdate()
	}
	
    // Start a database update
    // TODO: Remove this functionality from the AppDelegate
	func startDatabaseUpdate() {
        
		// Use the async queue in order to not freeze the UI on the database update
		DispatchQueue.main.async {
            
            // Iterate through the available windows to find the entry and main windows
			for window in NSApplication.shared.windows {
                
                // Open the entry window and ensure it will start updating the database
				if let entry =  window.contentViewController as? EntryViewController {
                    
                    // Set the entry state to "Prompting Contact Usage" in order to start immediate database update
					entry.setState(to: EntryViewController.State.promptingContactUsage)
					entry.view.window?.makeKeyAndOrderFront(nil)
				}
				
                // Close the main window
				if let main = window.contentViewController as? MainSplitViewController {
					main.view.window?.close()
				}
			}
		}
	}
	
    // TODO: Remove this for production
    // This function is mainly used for debugging and should be removed for production
	@IBAction func realmDeleteAll(sender: NSMenuItem) {
        
        // Get the current realm and delete all objects
		let realm = try! Realm()
		try! realm.write {
			realm.deleteAll()
		}
		realm.refresh()
        
        // Update the database
		startDatabaseUpdate()
	}

}
