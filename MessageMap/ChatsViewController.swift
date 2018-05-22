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

class ChatsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, StoreListener {

	@IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progress: NSProgressIndicator!
	let dateFormatter = DateFormatter()
	let realm = try! Realm()
	var selectedChat: Chat? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		Store.shared.addListener(self)

		self.tableView.delegate = self
		self.tableView.dataSource = self
		dateFormatter.dateFormat = "MM/dd/yy"
		
		messagesDidChange()

    }
	
	// MARK: Store Listener
	func messagesMightChange() {
		
	}
	
	func messagesDidChange() {
		self.tableView.reloadData()
		if let selected = selectedChat {
			if let index = Store.shared.filteredChats.index(of: selected){
				tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			}
		}
	}
	
	func messagesDidNotChange() {
		
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		return Store.shared.filteredChats.count
	}

	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 68.0
	}

	override func viewDidAppear() {
//		self.tableView.selectRowIndexes([0], byExtendingSelection: false)
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		if selectedChat == Store.shared.filteredChats[tableView.selectedRow] {
			// Clear selected chat
		} else {
			self.view.window!.makeFirstResponder(self.tableView)
			let chat = Store.shared.filteredChats[tableView.selectedRow]
			Store.shared.setChat(to: chat)
			selectedChat = chat
		}
		
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		let cell: ChatTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "chatRow"), owner: self) as! ChatTableCellView
		let chat = Store.shared.filteredChats[row]

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
