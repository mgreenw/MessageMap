//
//  MessagesViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/3/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

class MessagesViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {

	@IBOutlet weak var collectionView: NSCollectionView!
	private let cellId = "messageCell"
	let realm = try! Realm()
	@IBOutlet var progress: NSProgressIndicator!
	var chat: Chat?
	var messages: Results<Message>!
	var dayFilter = [(year: Int, month: Int, day: Int)]()

	let panelWidth = 465.0

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.window?.isOpaque = false

		messages = realm.objects(Message.self)

		let delegate = NSApplication.shared.delegate as! AppDelegate
		delegate.messagesViewController = self

		collectionView.backgroundColors.append(NSColor.white)
		collectionView.register(MessageItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
	}

	func setChat(chat: Chat) {
		self.chat = chat
		getMessages()
		self.collectionView.reloadData()
	}
	
	func setDayFilter(_ filter: [(year: Int, month: Int, day: Int)]) {
		self.dayFilter = filter
		getMessages()
		self.collectionView.reloadData()
	}
	
	func getMessages() {
		guard let chatSafe = chat else {
			return
		}
		let predicate = dayFilter.map({ filter in
			return "(year = \(filter.year) AND month = \(filter.month) AND dayOfMonth = \(filter.day))"
		}).joined(separator: " OR ")
		
		self.messages = chatSafe.sortedMessages.filter(predicate)
	}

	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		if chat != nil {
			return self.messages.count ?? 0
		}
		return 0
	}

	func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item: MessageItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! MessageItem

		let message = messages[indexPath.item]

		if let messageText = message.text {
			item.messageTextField.stringValue = messageText
			item.profileImageView.image = nil

			if message.fromMe {

				item.profileImageView.isHidden = true
				item.messageTextField.textColor = NSColor.white
				switch message.service {
				case .iMessage:
					item.messageBubble.fillColor = NSColor(red: 0, green: 137/255, blue: 249/255, alpha: 1.0)
				case .SMS:
					item.messageBubble.fillColor = NSColor(red: 29/255, green: 191/255, blue: 74/255, alpha: 1.0)
				case .Facebook:
					item.messageBubble.fillColor = NSColor(red: 23/255, green: 135/255, blue: 251/255, alpha: 1.0)
				case .Unknown:
					item.messageBubble.fillColor = NSColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)
				}
				item.messageTextField.frame = CGRect(x: message.textFieldX, y: 2.0, width: message.textFieldWidth, height: message.textFieldHeight)
				item.messageBubble.frame = CGRect(x: message.bubbleX, y: 0.0, width: message.bubbleWidth, height: message.bubbleHeight)

			} else {

				item.profileImageView.isHidden = false
				if let photo = message.sender?.photo {
					item.profileImageView.image = NSImage(data: photo)
				}
				item.messageTextField.textColor = NSColor.black
				
				
				
				item.messageBubble.fillColor = NSColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)

				item.messageTextField.frame = CGRect(x: 46.0, y: 2.0, width: message.textFieldWidth, height: message.textFieldHeight)
				item.messageBubble.frame = CGRect(x: 40.0, y: 0.0, width: message.bubbleWidth, height: message.bubbleHeight)
			}
		} else {
			item.messageTextField.stringValue = "Error"
		}

		return item
	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {

		// Use precalculated height
		return CGSize(width: panelWidth, height: messages[indexPath.item].layoutHeight)
	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
		return NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
	}

}
