//
//  SplitViewControllers.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/4/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {
	
	@IBOutlet weak var chatMessageCalendarPane: NSSplitViewItem!
	@IBOutlet weak var graphsPane: NSSplitViewItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

class ChatMessageCalendarSplitViewController: NSSplitViewController {
	
	@IBOutlet weak var chatMessagePane: NSSplitViewItem!
	@IBOutlet weak var calendarPane: NSSplitViewItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		
		NSLayoutConstraint(item: calendarPane.viewController.view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 150).isActive = true
	}
	
}

class ChatMessageSplitViewController: NSSplitViewController {
	
	@IBOutlet weak var chatPane: NSSplitViewItem!
	@IBOutlet weak var messagePane: NSSplitViewItem!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		
		NSLayoutConstraint(item: chatPane.viewController.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 270).isActive = true
		NSLayoutConstraint(item: messagePane.viewController.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 465).isActive = true
	}
	
}

