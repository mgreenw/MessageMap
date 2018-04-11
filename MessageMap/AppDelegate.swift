//
//  AppDelegate.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/12/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var chatsViewController: ChatsViewController!
	var messagesViewController: MessagesViewController!
	var calendarViewControler: CalendarViewController!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		
	}
  
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	
}

