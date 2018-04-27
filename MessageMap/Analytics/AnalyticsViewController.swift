//
//  AnalyticsViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/20/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

class AnalyticsViewController: NSViewController, MGPunchcardViewDataSource, MGTreemapViewDataSource {


	@IBOutlet var punchcardView: MGPunchcardView!
	@IBOutlet var treemapView: MGTreemapView!
	// Array of weekday (0-6) and hours (0-23)
	var punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
	
    override func viewDidLoad() {
        super.viewDidLoad()
		print("Analytics view did load")
		Store.shared.addMessagesChangedListener(messagesChanged)
		
		punchcardView.dataSource = self
		treemapView.dataSource = self
		messagesChanged()
        // Do view setup here.
    }
	
	func messagesChanged() {
		punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
		
		Store.shared.enumerateMessagesForFilter(FilterType.weekdayHour, { message in
			
			// The value added will change depending on the filter type
			punchcardValues[message.weekday-1][message.hour] += 1.0
		})
		
		punchcardView.reloadPunchcard()
		treemapView.reloadTreemap()
	}

	func punchcardView(_ punchcardView: MGPunchcardView, valueFor weekday: Int, hour: Int) -> Double? {
		return punchcardValues[weekday][hour]
	}
	
	let treemap = ["Julia", "John", "Cheryl", "Max"]
	let values = [500.0, 100.0, 50.0, 900.0]
	
	func numberOfValues(for treemapView: MGTreemapView) -> Int {
		return treemap.count
	}
	
	func treemapView(_ treemapView: MGTreemapView, valueForIndex index: Int) -> Double {
		return values[index]
	}
	
	func treemapView(_ treemapView: MGTreemapView, photoForIndex index: Int) -> Data? {
		return nil
	}
	
	func treemapView(_ treemapView: MGTreemapView, labelForIndex index: Int) -> String {
		return treemap[index]
	}
	
}
