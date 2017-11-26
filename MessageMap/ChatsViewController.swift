//
//  ChatsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SnapKit
//import RealmSwift

// Define Constants
let chatsViewWidth = 250

class ChatsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	
	@IBOutlet weak var tableView:NSTableView!
	let dateFormatter = DateFormatter()
	var delegate: AppDelegate!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		delegate = NSApplication.shared.delegate as! AppDelegate
		delegate.chatsViewController = self
		
		print(Store.shared)
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		dateFormatter.dateFormat = "MM/dd/yy"

	
		// Set the initial view constraints using SnapKit
		self.view.snp.makeConstraints { (make) -> Void in
			make.width.greaterThanOrEqualTo(chatsViewWidth)
		}
    }
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return Store.shared.chats.count
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 68.0
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		delegate.messagesViewController.setChat(chat: Store.shared.chats[tableView.selectedRow])
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		
		
		let result:ChatTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "chatRow"), owner: self) as! ChatTableCellView
		
		let chat = Store.shared.chats[row]
		
		if let displayName = chat.displayName {
			result.name.stringValue = displayName
		} else {
			if chat.people.count == 0 {
				result.name.stringValue = "Myself"
			} else if chat.people.count == 1 {
				let person = chat.people[0]
				result.name.stringValue = person.fullName()
			} else {
				result.name.stringValue = chat.people.map({ $0.fullName() }).joined(separator: " & ")
			}
		}
		
		let date = Date()
		
		if let message = chat.messages.last {
			result.date.stringValue = dateFormatter.string(from: message.date)
			result.text.stringValue = message.text ?? "Attachment: {} images"
		} else {
			result.date.stringValue = "Never"
		}
		
		
//		if (result.backgroundStyle == NSView.BackgroundStyle.dark) {
//			result.text.textColor = NSColor.white
//			result.name.textColor = NSColor.white
//			result.date.textColor = NSColor.white
//		} else if (result.backgroundStyle == NSView.BackgroundStyle.light) {
//			result.text.textColor = NSColor.gray
//			result.name.textColor = NSColor.black
//			result.date.textColor = NSColor.gray
//		}
		

		return result;
	}
    
}

class ChatTableCellView: NSTableCellView {
	
	@IBOutlet weak var image: NSImageView!
	@IBOutlet weak var name: NSTextField!
	@IBOutlet weak var text: NSTextField!
	@IBOutlet weak var date: NSTextField!
	
}
