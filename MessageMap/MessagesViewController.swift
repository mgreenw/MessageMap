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
	var chat: Chat? = nil
	var messages: Results<Message>!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		messages = realm.objects(Message.self)
		
		let delegate = NSApplication.shared.delegate as! AppDelegate
		delegate.messagesViewController = self
		
		collectionView.backgroundColors.append(NSColor.white)
		collectionView.register(MessageItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
		
	}
	
	func setChat(chat: Chat) {
		self.chat = chat
		self.messages = chat.sortedMessages
		self.collectionView.reloadData()
	}
	
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return chat?.messages.count ?? 0
	}
	
	func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		
		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath)
			
		guard let messageItem = item as? MessageItem else {print("Returning");return item}
		
		let message = messages[indexPath.item]
		
		if let messageText = message.text {
			messageItem.messageTextField.stringValue = messageText
			
			let size = CGSize(width: 250, height: 1000)
			let options = NSString.DrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
			let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font : NSFont.systemFont(ofSize: 13.0)], context: nil)
			
			if message.fromMe {
				
				messageItem.profileImageView.isHidden = true
				messageItem.messageTextField.textColor = NSColor.white
				messageItem.messageBubble.fillColor = NSColor(red: 0, green: 137/255, blue: 249/255, alpha: 1.0)

				
				messageItem.messageTextField.frame = CGRect(x: view.frame.width - estimatedFrame.width - 35 + 6, y: 2, width: estimatedFrame.width + 8, height: estimatedFrame.height + 5)
				messageItem.messageBubble.frame = CGRect(x: view.frame.width - estimatedFrame.width - 35, y: 0, width: estimatedFrame.width + 18, height: estimatedFrame.height + 5 + 6)
				
			} else {
				
				messageItem.profileImageView.isHidden = false
				messageItem.messageTextField.textColor = NSColor.black
				messageItem.messageBubble.fillColor = NSColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)

				
				messageItem.messageBubble.fillColor = NSColor(white: 0.92, alpha: 1.0)
				messageItem.messageTextField.frame = CGRect(x: 6 + 40, y: 2, width: estimatedFrame.width + 8, height: estimatedFrame.height + 5)
				messageItem.messageBubble.frame = CGRect(x: 40, y: 0, width: estimatedFrame.width + 18, height: estimatedFrame.height + 5 + 6)
			}
		} else {
			messageItem.messageTextField.stringValue = "Test"
		}
		
		return item
	}
	
	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		if let messageText = messages[indexPath.item].text {
			let size = CGSize(width: 250, height: 1000)
			let options = NSString.DrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
			let estimatedFrame = NSString(string: messageText).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font : NSFont.systemFont(ofSize: 13.0)], context: nil)
			
			return CGSize(width: view.frame.width, height: estimatedFrame.height + 5 + 6)
			
		}
		return CGSize(width: self.view.frame.width, height: 100)
	}
	
	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
		return NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
	}

    
}
