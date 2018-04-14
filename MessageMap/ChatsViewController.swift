//
//  ChatsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

// Define Constants
let chatsViewWidth = 250

class ChatsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

	@IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progress: NSProgressIndicator!
	let dateFormatter = DateFormatter()
	let delegate = NSApplication.shared.delegate as! AppDelegate
	let realm = try! Realm()
	var dayFilter = [(year: Int, month: Int, day: Int)]()

	var chats: Results<Chat>!

    override func viewDidLoad() {
        super.viewDidLoad()

		delegate.chatsViewController = self

		self.tableView.delegate = self
		self.tableView.dataSource = self
		dateFormatter.dateFormat = "MM/dd/yy"

		chats = realm.objects(Chat.self).filter("messages.@count > 0").sorted(byKeyPath: "lastMessageDate", ascending: false)
    }
	
	func setDayFilter(_ filter: [(year: Int, month: Int, day: Int)]) {
		self.dayFilter = filter
		self.tableView.reloadData()
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		print("Reload chat table")
		chats = realm.objects(Chat.self).filter("messages.@count > 0").sorted(byKeyPath: "lastMessageDate", ascending: false)
		
//		if dayFilter.count > 0 {
//			let predicate = "SUBQUERY(messages, $message, " + dayFilter.map({ filter in
//				return "($message.year = \(filter.year) AND $message.month = \(filter.month) AND $message.dayOfMonth = \(filter.day))"
//			}).joined(separator: " OR ") + ").@count > 0"
//			
//			chats = chats.filter(predicate)
//		}
		
		return chats.count
	}

	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 68.0
	}

	override func viewDidAppear() {
//		self.tableView.selectRowIndexes([0], byExtendingSelection: false)
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		self.view.window!.makeFirstResponder(self.tableView)
		delegate.messagesViewController.setChat(chat: chats[tableView.selectedRow])
		delegate.calendarViewControler.setChat(chat: chats[tableView.selectedRow])
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		let cell: ChatTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "chatRow"), owner: self) as! ChatTableCellView
		let chat = chats[row]

		cell.image.image = nil

		cell.image.imageScaling = .scaleAxesIndependently // In place of .scaleAspectFill
		cell.image.wantsLayer = true
		cell.image.layer?.masksToBounds = true
		cell.image.canDrawSubviewsIntoLayer = true
		cell.image.layer?.cornerRadius = cell.image.frame.size.width / 2

		if let displayName = chat.displayName {
			cell.name.stringValue = displayName
		} else {
			if chat.participants.count == 0 {
				cell.name.stringValue = chat.messages.count == 0 ? "Myself and none" : "Myself"
			} else if chat.participants.count == 1 {
				let person = chat.participants[0]
				cell.name.stringValue = "\(person.firstName ?? "") \(person.lastName ?? "")"

				if let photo = chat.participants[0].photo {
					cell.image.image = NSImage(data: photo)
				}
			} else {

				cell.name.stringValue = chat.participants.map({ "\($0.firstName ?? "") \($0.lastName ?? "")" }).joined(separator: " & ")

				if let photo = chat.participants[0].photo {
					cell.image.image = NSImage(data: photo)
				}
			}
		}

		_ = Date()

		if let message = chat.sortedMessages.last {
			cell.date.stringValue = dateFormatter.string(from: message.date)
			cell.text.stringValue = message.text ?? "Attachment: {} images"
		} else {
			cell.date.stringValue = "Never"
		}

		return cell
	}

}

class ChatTableCellView: NSTableCellView {

	@IBOutlet var image: NSImageView!
	@IBOutlet var name: NSTextField!
	@IBOutlet var text: NSTextField!
	@IBOutlet var date: NSTextField!

	override var backgroundStyle: NSView.BackgroundStyle {
		didSet {
			if (backgroundStyle == NSView.BackgroundStyle.dark) {
				name.textColor = NSColor.white
				text.textColor = NSColor.white
				date.textColor = NSColor.white
			} else {
				name.textColor = NSColor.black
				text.textColor = NSColor(red: 118/255, green: 118/255, blue: 118/255, alpha: 1.0)
				date.textColor = NSColor(red: 118/255, green: 118/255, blue: 118/255, alpha: 1.0)
			}
		}
	}

}
