//
//  MessagesViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SnapKit
import RealmSwift

// Define Constants
let minMessagesViewWidth = 400

class MessagesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate  {

	@IBOutlet weak var tableView:NSTableView!
	let realm = try! Realm()
	var messages: Results<Message>! = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let me = realm.objects(Person.self).filter("isMe = true").first {
			let predicate = NSPredicate(format: "sender.firstName == %@ AND sender.lastName == %@", me.firstName, me.lastName)
			messages = realm.objects(Message.self).filter(predicate)
			
		} else {
			print("failed to get messages")
		}
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.usesAutomaticRowHeights = true
		
		// Set the initial view constraints using SnapKit
		self.view.snp.makeConstraints { (make) -> Void in
			make.width.greaterThanOrEqualTo(minMessagesViewWidth)
		}
    }

	
	func numberOfRows(in tableView: NSTableView) -> Int {
		print(messages.count)
		return messages.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		
		
		let result:MessageTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "messageRow"), owner: self) as! MessageTableCellView
		
		let message = messages[row]
		if let text = message.text {
			result.text.stringValue = text
		}
		
		return result;
	}
    
}

class MessageTableCellView: NSTableCellView {
	@IBOutlet weak var text: NSTextField!
}
