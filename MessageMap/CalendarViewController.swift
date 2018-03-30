//
//  CalendarViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
//import SnapKit
//
//let calendarMinHeight = 150
//let calendarMaxHeight = 300


class CalendarViewController: NSViewController {
	
	var startDay = Date()
	var endDay = Date()
    override func viewDidLoad() {
        super.viewDidLoad()
				
//		// Set the initial view constraints using SnapKit
//		self.view.snp.makeConstraints { (make) -> Void in
//			make.height.lessThanOrEqualTo(calendarMaxHeight)
//			make.height.greaterThanOrEqualTo(calendarMinHeight)
//		}
    }
	
	@IBAction func buttonPressed(sender: CalendarDay) {
		print("calendar day pressed")
	}
	
}
