//
//  CalendarViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/13/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import RealmSwift

class CalendarViewController: NSViewController, MGCalendarViewDelegate, MGCalendarViewDataSource {
	
	@IBOutlet var calendarView: MGCalendarView!
	let realm = try! Realm()
	var messages: Results<Message>!
	var chat: Chat? = nil
	var values = [String:Int]()
	let delegate = NSApplication.shared.delegate as! AppDelegate
	
	override func viewDidLoad() {
		calendarView.dataSource = self
		calendarView.delegate = self
		
		delegate.calendarViewControler = self
		print("view did load")
		messages = realm.objects(Message.self).sorted(byKeyPath: "date", ascending: true)
		values.removeAll()
		for message in messages {
			let dayID = "\(message.year)-\(message.month)-\(message.dayOfMonth)"
			if let dayValue = values[dayID] {
				values[dayID] = dayValue + 1
			} else {
				values[dayID] = 1
			}
		}
		
		calendarView.reloadCalendar()
	}
	
	func setChat(chat: Chat) {
		self.chat = chat
		values.removeAll()
		for message in chat.messages {
			let dayID = "\(message.year)-\(message.month)-\(message.dayOfMonth)"
			if let dayValue = values[dayID] {
				values[dayID] = dayValue + 1
			} else {
				values[dayID] = 1
			}
		}
		self.calendarView.reloadValues()
	}

	func dateRange(for calendarView: MGCalendarView) -> (Date, Date) {
		
		let now = Date()
		guard let first:Date = messages.first?.date else {
			print("Could not find the date of the first message sent")
			return (now, now)
		}
		
		guard let last:Date = messages.last?.date else {
			print("Could not find the date of the last message sent")
			return (now, now)
		}
		
		return (first, last)
	}
	
	func colorRange(for calendarView: MGCalendarView) -> (NSColor, NSColor) {
		return (NSColor.white, NSColor.red)
	}
	
	func calendarView(_ calendarView: MGCalendarView, valueFor year: Int, month: Int, day: Int) -> Double {
		let dayID = "\(year)-\(month)-\(day)"
		if let value = values[dayID] {
			return Double(value)
		} else {
			return 0.0
		}
	}
}






