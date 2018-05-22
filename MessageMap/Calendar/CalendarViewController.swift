//
//  CalendarViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

class CalendarViewController: NSViewController, MGCalendarViewDelegate, MGCalendarViewDataSource, StoreListener {

    @IBOutlet var scrollView: NSScrollView!
	@IBOutlet var calendarView: MGCalendarView!
	let realm = try! Realm()
	var values = [String:Int]()

	override func viewDidLoad() {
		calendarView.dataSource = self
		calendarView.delegate = self
        calendarView.scrollView = scrollView
		
		Store.shared.addListener(self)
		
		calendarView.reloadCalendar()
		messagesDidChange()
	}
	
	// MARK: Store Listener
	func messagesMightChange() {
		
	}
	
	func messagesDidChange() {
		values.removeAll()
		Store.shared.enumerateMessagesForFilter(FilterType.day, { message in
			let dayID = "\(message.year)-\(message.month)-\(message.dayOfMonth)"
			if let dayValue = values[dayID] {
				values[dayID] = dayValue + 1
			} else {
				values[dayID] = 1
			}
		})
		self.calendarView.reloadValues()
	}
	
	func messagesDidNotChange() {
		
	}

	func dateRange(for calendarView: MGCalendarView) -> (Date, Date) {

		let now = Date()
		
		print("Count:\(Store.shared.countForFilter(FilterType.day))")
		
		guard let firstMessage: Message = Store.shared.messageForFilter(FilterType.day, at: 0) else {
			print("Could not find the date of the first message sent")
			return (now, now)
		}

		// We always return "now" to ensure the calendar includes the current date
		return (firstMessage.date, now)
	}

	func colorRange(for calendarView: MGCalendarView) -> (NSColor, NSColor) {
		return (NSColor.white, NSColor.red)
	}

	func calendarView(_ calendarView: MGCalendarView, valueFor year: Int, month: Int, day: Int) -> Double? {
		let dayID = "\(year)-\(month)-\(day)"
		if let value = values[dayID] {
			return Double(value)
		} else {
			return nil
		}
	}
	
	func calendarViewSelectionDidChange(_ notification: Notification) {
		if calendarView.selection.count > 0 {
			Store.shared.setFilter(.day, to: calendarView.selection)
		}
	}
	
	@IBAction func clearSelection(sender: NSButton) {
		calendarView.setAllDeselected()
		Store.shared.removeAllFiltersFor(FilterType.day)
	}
}
