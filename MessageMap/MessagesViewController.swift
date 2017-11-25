//
//  MessagesViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SnapKit

// Define Constants
let minMessagesViewWidth = 400

class MessagesViewController: NSViewController {


	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Set the initial view constraints using SnapKit
		self.view.snp.makeConstraints { (make) -> Void in
			make.width.greaterThanOrEqualTo(minMessagesViewWidth)
		}
    }
	
	
    
}
