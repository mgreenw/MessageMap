//
//  MessageItem.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/4/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

class MessageItem: NSCollectionViewItem {

	let messageTextField: NSTextField = {
		let textField = NSTextField()
		textField.font = NSFont.systemFont(ofSize: 13.0)
		textField.isEditable = false
		textField.isSelectable = true
		textField.backgroundColor = NSColor.clear
		textField.isBordered = false
		return textField
	}()

	let messageBubble: NSBox = {
		let bubble = NSBox()
		bubble.boxType = NSBox.BoxType.custom
		bubble.borderType = NSBorderType.noBorder
		bubble.fillColor = NSColor(white: 0.92, alpha: 1.0)
		bubble.cornerRadius = 12
		return bubble
	}()

	let profileImageView: NSImageView = {
		let imageView = NSImageView()
		imageView.imageScaling = .scaleAxesIndependently // In place of .scaleAspectFill
		imageView.wantsLayer = true
		imageView.layer?.masksToBounds = true
		imageView.canDrawSubviewsIntoLayer = true
		imageView.layer?.cornerRadius = 15

		//imageView.image = NSImage(named: NSImage.Name(rawValue: "Seal_of_the_United_States_Department_of_Justice.svg"))
		return imageView
	}()
	
	let nameTextField: NSTextField = {
		let textField = NSTextField()
		textField.font = NSFont.systemFont(ofSize: 11.0)
		textField.textColor = NSColor(red: 142.0/255.0, green: 131.0/255.0, blue: 141.0/255.0, alpha: 1.0)
		textField.isEditable = false
		textField.isSelectable = false
		textField.alignment = .left
		textField.backgroundColor = NSColor.clear
		textField.isBordered = false
		return textField
	}()
	
	let dateTextField: NSTextField = {
		let textField = NSTextField()
		textField.font = NSFont.boldSystemFont(ofSize: 11.0)
		textField.textColor = NSColor(red: 131.0/255.0, green: 131.0/255.0, blue: 136.0/255.0, alpha: 1.0)
		textField.isEditable = false
		textField.isSelectable = false
		textField.alignment = .center
		textField.backgroundColor = NSColor.clear
		textField.isBordered = false
		return textField
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.addSubview(messageBubble)
		self.view.addSubview(messageTextField)
		self.view.addSubview(profileImageView)
		self.view.addSubview(nameTextField)
		self.view.addSubview(dateTextField)

		self.view.addConstraintsWithFormat(format: "H:|-8-[v0(28)]", views: profileImageView)
		self.view.addConstraintsWithFormat(format: "V:[v0(28)]|", views: profileImageView)
	}

}
