//
//  MessagesViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/3/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift
import Quartz

class MessagesViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {

	@IBOutlet weak var collectionView: NSCollectionView!
	private let cellId = "messageCell"
	let realm = try! Realm()
	@IBOutlet var progress: NSProgressIndicator!
	var dayFilter = [(year: Int, month: Int, day: Int)]()
	var heightAdditions = [(quick: Bool, showHour: Bool, showName: Bool, attachments: Int)]()
	let dateFormatter:DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "M/d/yy, h:mm a" // Add :ss to add the milliseconds
		return formatter
	}()
	
	let panelWidth = 465.0

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.window?.isOpaque = false
		
		Store.shared.addMessagesChangedListener(messagesChanged)

		collectionView.backgroundColors.append(NSColor.white)
		collectionView.register(MessageItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
	}
	
	func messagesChanged() {
		// Generate new heights
		generateHeightAdditions()
		self.collectionView.reloadData()
	}
	
	func generateHeightAdditions() {
		var prevMessage: Message? = nil
		heightAdditions.removeAll()
		let groupChat = (Store.shared.selectedChat?.participants.count ?? 0) > 1
		Store.shared.enumerateMessages { message in
			if let prev = prevMessage {
				let interval = message.date.timeIntervalSince(prev.date)
				let quick = interval < 60
				let showHour = interval > 3600
				let differentSender = (prev.sender?.id != message.sender?.id)
				let showName: Bool = {
					if message.fromMe || (!groupChat) {
						return false
					}
					return showHour ? true : differentSender
				}()
				
				heightAdditions.append((quick: quick && (!showName) && !differentSender, showHour: showHour, showName: showName, attachments: message.attachments.count))
			} else {
				heightAdditions.append((quick: false, showHour: true, showName: groupChat && !message.fromMe, attachments: message.attachments.count))
			}
			
			prevMessage = message
		}
	}

	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if Store.shared.selectedChat != nil {
			return Store.shared.count()
		}
		return 0
	}


	func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item: MessageItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! MessageItem
		let message = Store.shared.message(at: indexPath.item)!
		item.nameTextField.isHidden = true
		item.dateTextField.isHidden = true

		
		if let messageText = message.text {
			item.messageTextField.stringValue = messageText
			item.profileImageView.image = nil
			
			let dateString = dateFormatter.string(from: message.date)
			item.view.toolTip = dateString
			let additionalHeight = heightAdditions[indexPath.item]

			if additionalHeight.showHour {
				item.dateTextField.isHidden = false
				item.dateTextField.frame = CGRect(x: 0.0, y: message.bubbleHeight + (additionalHeight.showName ? 15.0 : 0), width: panelWidth, height: 25.0)
				item.dateTextField.stringValue = dateString
			}
			
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
				
				for (index, attachment) in message.attachments.enumerated() {

					let attachmentButton = NSButton(title: attachment.transferName, target: nil, action: nil)
					attachmentButton.addAction(action: { button in

						let absoluteAttachmentPath =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(attachment.filename.replacingOccurrences(of: "~/", with: ""))
						
						if let delegate = NSApplication.shared.delegate as? AppDelegate {
							delegate.attachmentURL = absoluteAttachmentPath
						}
						if let sharedPanel = QLPreviewPanel.shared() {
							sharedPanel.updateController()
							sharedPanel.makeKeyAndOrderFront(self)
						}
					})
					attachmentButton.frame = NSRect(x: panelWidth-100.0, y: message.bubbleHeight + (Double(index) * 30.0), width: 90.0, height: 30.0)
					attachmentButton.toolTip = attachment.transferName
					item.view.addSubview(attachmentButton)
				}

			} else {
				
				if additionalHeight.showName {
					item.nameTextField.isHidden = false
					item.nameTextField.frame = CGRect(x: 46.0, y: message.bubbleHeight, width: 200.0, height: 15.0)
					item.nameTextField.stringValue = "\(message.sender!.firstName ?? "") \(message.sender!.lastName ?? "")"
				}
				
				
				if additionalHeight.quick {
					item.profileImageView.isHidden = true
				} else {
					if let photo = message.sender?.photo {
						item.profileImageView.isHidden = false
						item.profileImageView.image = NSImage(data: photo)
					} else {
						item.profileImageView.isHidden = true
					}
				}
				item.messageTextField.textColor = NSColor.black
				
				item.messageBubble.fillColor = NSColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0)
				
				if Store.shared.selectedChat!.participants.count > 1 {
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
		let heightAddition = heightAdditions[indexPath.item]
		let additionalHeight: Double = (heightAddition.showHour ? (heightAddition.showName ? 15.0 : 25.0) : 0.0) + (heightAddition.showName ? 25.0 : 0.0) + (heightAddition.quick ? 0.0 : 7.0) + (Double(heightAddition.attachments) * 50.0)
		return CGSize(width: panelWidth, height: Store.shared.message(at: indexPath.item)!.layoutHeight + additionalHeight)
	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
		return NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
	}
	
}
