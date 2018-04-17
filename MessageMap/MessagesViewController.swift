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
	var dayFilter = [(year: Int, month: Int, day: Int)]()
	let dateFormatter:DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "M/d/yy, h:mm:ss a"
		return formatter
	}()

	let panelWidth = 465.0

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.window?.isOpaque = false

		let delegate = NSApplication.shared.delegate as! AppDelegate
		delegate.messagesViewController = self
		
		Store.shared.addMessagesChangedListener(messagesChanged)

		collectionView.backgroundColors.append(NSColor.white)
		collectionView.register(MessageItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
	}
	
	func messagesChanged() {
		self.collectionView.reloadData()
	}

	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if Store.shared.chat != nil {
			return Store.shared.count()
		}
		return 0
	}

	func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item: MessageItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! MessageItem
		let message = Store.shared.message(at: indexPath.item)!

		if let messageText = message.text {
			item.messageTextField.stringValue = messageText
			item.profileImageView.image = nil
			
			item.view.toolTip = dateFormatter.string(from: message.date)

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

				
				if let photo = message.sender?.photo {
					item.profileImageView.image = NSImage(data: photo)
				}
				item.messageTextField.textColor = NSColor.black
				
				
				item.messageBubble.fillColor = NSColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)
				
				if Store.shared.chat!.participants.count > 1 {
					item.profileImageView.isHidden = false
					item.messageTextField.frame = CGRect(x: 46.0, y: 2.0, width: message.textFieldWidth, height: message.textFieldHeight)
					item.messageBubble.frame = CGRect(x: 40.0, y: 0.0, width: message.bubbleWidth, height: message.bubbleHeight)
				} else {
					
					// Not positive if this is the best value, may want to change this
					item.profileImageView.isHidden = true
					item.messageTextField.frame = CGRect(x: 26.0, y: 2.0, width: message.textFieldWidth, height: message.textFieldHeight)
					item.messageBubble.frame = CGRect(x: 20.0, y: 0.0, width: message.bubbleWidth, height: message.bubbleHeight)
				}
				
			}
		} else {
			item.messageTextField.stringValue = "Error"
		}

		return item
	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {

		// Use precalculated height
		return CGSize(width: panelWidth, height: Store.shared.message(at: indexPath.item)!.layoutHeight)
	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
		return NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
	}

}
