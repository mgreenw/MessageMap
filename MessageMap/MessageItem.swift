//
//  MessageItem.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/4/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

extension NSView {
	func addConstraintsWithFormat(format: String, views: NSView...) {
		
		var viewsDict = [String: NSView]()
		for (index, view) in views.enumerated() {
			let key = "v\(index)"
			viewsDict[key] = view
			view.translatesAutoresizingMaskIntoConstraints = false
		}
		
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDict))
		
	}
}

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
		imageView.layer?.cornerRadius = 15
		imageView.image = NSImage(named: NSImage.Name(rawValue: "Seal_of_the_United_States_Department_of_Justice.svg"))
		return imageView
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.addSubview(messageBubble)
		self.view.addSubview(messageTextField)
		self.view.addSubview(profileImageView)
		
		self.view.addConstraintsWithFormat(format: "H:|-8-[v0(28)]", views: profileImageView)
		self.view.addConstraintsWithFormat(format: "V:[v0(28)]|", views: profileImageView)
	}
	
}

