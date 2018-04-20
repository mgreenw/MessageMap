//
//  AnalyticsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/20/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

class AnalyticsViewController: NSViewController, MGPunchcardViewDataSource {

	@IBOutlet var punchcardView: MGPunchcardView!
	// Array of weekday (0-6) and hours (0-23)
	var punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
	
    override func viewDidLoad() {
        super.viewDidLoad()
		print("Analytics view did load")
		Store.shared.addMessagesChangedListener(messagesChanged)
		
		punchcardView.dataSource = self
		
		messagesChanged()
        // Do view setup here.
    }
	
	func messagesChanged() {
		print("Punchcard messages changed")
		punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
		
		Store.shared.enumerateMessagesForFilter(FilterType.weekdayHour, { message in
			
			// The value added will change depending on the filter type
			punchcardValues[message.weekday-1][message.hour] += 1.0
		})
		
		punchcardView.reloadPunchcard()
	}

	func punchcardView(_ punchcardView: MGPunchcardView, valueFor weekday: Int, hour: Int) -> Double? {
		return punchcardValues[weekday][hour]
	}
	
}
