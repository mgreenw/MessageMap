//
//  ChatsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift
//import SnapKit

// Define Constants
let chatsViewWidth = 250

class ChatsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	
	@IBOutlet weak var tableView:NSTableView!
    @IBOutlet weak var progress: NSProgressIndicator!
	let dateFormatter = DateFormatter()
	let delegate = NSApplication.shared.delegate as! AppDelegate
	let realm = try! Realm()
	
	var chats: Results<Chat>!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		delegate.chatsViewController = self
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		dateFormatter.dateFormat = "MM/dd/yy"
		
    }
	
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		print("Reload chat table")
		chats = realm.objects(Chat.self).filter("messages.@count > 0").sorted(byKeyPath: "lastMessageDate", ascending: false)
		return chats.count
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 68.0
	}
	
	
//	func tableViewSelectionDidChange(_ notification: Notification) {
//		delegate.messagesViewController.setChat(chat: Store.shared.chats[tableView.selectedRow])
//	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
		
		let result:ChatTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "chatRow"), owner: self) as! ChatTableCellView
		let chat = chats[row]
		
		if let displayName = chat.displayName {
			result.name.stringValue = displayName
		} else {
			if chat.participants.count == 0 {
				result.name.stringValue = chat.messages.count == 0 ? "Myself and none" : "Myself"
				print(chat.messages)
			} else if chat.participants.count == 1 {
				let person = chat.participants[0]
				result.name.stringValue = "\(person.firstName ?? "") \(person.lastName ?? "")"
			} else {
				result.name.stringValue = chat.participants.map({ "\($0.firstName ?? "") \($0.lastName ?? "")" }).joined(separator: " & ")
			}
		}

		let _ = Date()

		if let message = chat.sortedMessages.last {
			result.date.stringValue = dateFormatter.string(from: message.date)
			result.text.stringValue = message.text ?? "Attachment: {} images"
		} else {
			result.date.stringValue = "Never"
		}

//        let graph = result.graph
//        var segments = [Segment]()
//        let meSegment = Segment(color: .blue, value: CGFloat(chat.messages.filter { $0.sender == Store.shared.me }.count))
//        segments.append(meSegment)

//        for person in chat.participants {
//            let count = (chat.messages.filter { $0.sender == person }).count
//            let segment = Segment(color: .orange, value: CGFloat(count))
//            segments.append(segment)
//        }
//
//
//        graph?.segments = segments


		return result;
	}
    
}

class ChatTableCellView: NSTableCellView {
	
	@IBOutlet weak var image: NSImageView!
	@IBOutlet weak var name: NSTextField!
	@IBOutlet weak var text: NSTextField!
	@IBOutlet weak var date: NSTextField!
    @IBOutlet weak var graph: ChatGraph!
	
}
