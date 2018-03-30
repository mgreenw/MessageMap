//
//  MessagesViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
//import SnapKit
//import RealmSwift

// Define Constants
let minMessagesViewWidth = 400

class MessagesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate  {

	@IBOutlet weak var tableView:NSTableView!
	var chat: Chat?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		//self.tableView.usesAutomaticRowHeights = true
		
		let delegate = NSApplication.shared.delegate as! AppDelegate
		delegate.messagesViewController = self
		
		// Set the initial view constraints using SnapKit
//		self.view.snp.makeConstraints { (make) -> Void in
//			make.width.greaterThanOrEqualTo(minMessagesViewWidth)
//		}
    }
	
	func setChat(chat: Chat) {
		self.chat = chat
		tableView.reloadData()
	}

	
	func numberOfRows(in tableView: NSTableView) -> Int {
		if let c = chat {
			return c.messages.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		
		
		let result:MessageTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "messageRow"), owner: self) as! MessageTableCellView
		if let c = chat {
			let message = c.messages[row]
			result.text.stringValue = message.text ?? ""
			if message.fromMe {
				result.text.alignment = NSTextAlignment.right
			} else {
				result.text.alignment = NSTextAlignment.left
			}
		}
		
		return result;
	}
    
}

class MessageTableCellView: NSTableCellView {
	@IBOutlet weak var text: NSTextField!
}
