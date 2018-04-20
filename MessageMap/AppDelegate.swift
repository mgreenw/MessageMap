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

	var chatsViewController: ChatsViewController!
	var messagesViewController: MessagesViewController!
	var calendarViewControler: CalendarViewController!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		Store.shared.startStore()
	}

	func applicationWillTerminate(_ aNotification: Notification) {

	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	@IBAction func updateDatabase(sender: NSMenuItem) {
		startDatabaseUpdate()
	}
	
	func startDatabaseUpdate() {
		// Open the main MessageMap Window
		DispatchQueue.main.async {
			for window in NSApplication.shared.windows {
				if let entry =  window.contentViewController as? EntryViewController {
					entry.setState(to: EntryViewController.EntryState.promptingContactUsage)
					entry.view.window?.makeKeyAndOrderFront(nil)
				}
				
				if let main = window.contentViewController as? MainSplitViewController {
					main.view.window?.close()
				}
			}
		}
		print("Update databases!")
	}
	
	@IBAction func realmDeleteAll(sender: NSMenuItem) {
		let realm = try! Realm()
		try! realm.write {
			realm.deleteAll()
		}
		realm.refresh()
		startDatabaseUpdate()
	}

}
