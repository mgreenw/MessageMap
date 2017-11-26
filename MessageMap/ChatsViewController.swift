//
//  ChatsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SnapKit
import RealmSwift

// Define Constants
let chatsViewWidth = 250

class ChatsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	
	@IBOutlet weak var tableView:NSTableView!
	let realm = try! Realm()
	var chatsSorted: [Chat]!
	let dateFormatter = DateFormatter()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		dateFormatter.dateFormat = "MM/dd/yy"
		let delegate = NSApplication.shared.delegate
		
		let chats = realm.objects(Chat.self)
		func chatDateSort(chatOne: Chat, chatTwo: Chat) -> Bool {
			guard let chatOneDate = chatOne.lastDateBefore(date: Date()) else {
				return false
			}
			guard let chatTwoDate = chatTwo.lastDateBefore(date: Date()) else {
				return false
			}
			
			return chatOneDate > chatTwoDate
		}
		chatsSorted = chats.sorted ( by: chatDateSort )
		
		// Set the initial view constraints using SnapKit
		self.view.snp.makeConstraints { (make) -> Void in
			make.width.greaterThanOrEqualTo(chatsViewWidth)
		}
    }
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		let chats = realm.objects(Chat.self)
		return chats.count
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 68.0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		
		
		let result:ChatTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "chatRow"), owner: self) as! ChatTableCellView
		
		let chat = chatsSorted[row]
		
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
		
		if let message = chat.lastMessageBefore(date: date) {
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
