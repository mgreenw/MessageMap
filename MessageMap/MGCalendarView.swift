//
//  CalendarView.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/14/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

/////////////////////////////
//// MGCalendarView
/////////////////////////////

// MARK: MGCalendarView

protocol MGCalendarViewDataSource: AnyObject {
	func dateRange(for calendarView: MGCalendarView) -> (Date, Date)
	func colorRange(for calendarView: MGCalendarView) -> (NSColor, NSColor)
	func calendarView(_ calendarView: MGCalendarView, valueFor year: Int, month: Int, day: Int) -> Double
}

// @objc needed to make funcs optional
@objc protocol MGCalendarViewDelegate: AnyObject {
	@objc optional func calendarViewSelectionDidChange(_ notification: Notification)
}

class MGCalendarView: NSView {
	
	weak var delegate: MGCalendarViewDelegate?
	weak var dataSource: MGCalendarViewDataSource?
	
	private var startDate: Date = Date()
	private var endDate: Date = Date()
	private var startColor: NSColor = NSColor.white
	private var endColor: NSColor = NSColor.white
	private var weeks: [Week] = [Week]()
	private var maxValue = 0.0
	
	let dayLabelWidth: CGFloat = 35.0
	
	var selectionStartPoint: NSPoint? = nil
	var selectionEndPoint: NSPoint? = nil
	var previousSelection: NSRect? = nil
	
	var rowHeight: CGFloat!
	var headerHeight: CGFloat! = 23.0 {
		willSet (newHeaderHeight) {
			// This ensures we do not get a feedback look from setRowHeight()
			// if it changes headerHight
			if newHeaderHeight != headerHeight {
				setRowHeight()
			}
		}
	}
	
	private func setRowHeight() {
		// This math ensures that rowHeight is always an integer
		// Mutates rowHeight and headerHeight
		self.rowHeight = (self.frame.height - self.headerHeight) / 7.0
		self.rowHeight.round()
		self.headerHeight = self.frame.height - (self.rowHeight * 7.0)
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		setup()
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame:frameRect);
		setup()
	}
	
	func setup() {
		setRowHeight()
	}
	
	public func reloadValues() {
		fetchValues()
	}
	
	public func reloadCalendar() {
		fetchData()
	}
	
	override func mouseDown(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)

		selectionStartPoint = mousePoint
		selectionEndPoint = mousePoint
	}
	
	override func mouseDragged(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)
		selectionEndPoint = mousePoint
		
		if let rect = selectionRect() {
			self.setNeedsDisplay(rect.insetBy(dx: -10.0, dy: -10.0))
			
			if let prevSelection = previousSelection {
				self.setNeedsDisplay(prevSelection.insetBy(dx: -10.0, dy: -10.0))
			}
		}
		
	}
	
	override func mouseUp(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)
		if let selection = selectionRect() {
			self.setNeedsDisplay(selection.insetBy(dx: -10.0, dy: -10.0))
		}
		if let prevSelection = previousSelection {
			self.setNeedsDisplay(prevSelection.insetBy(dx: -10.0, dy: -10.0))
		}
		selectionStartPoint = nil
		selectionEndPoint = nil
		
	}
	
	func selectionRect() -> NSRect? {
		guard let startPoint = selectionStartPoint else {
			return nil
		}
		guard let endPoint = selectionEndPoint else {
			return nil
		}

		let finalSelectionRect: NSRect? = NSRect(x: min(startPoint.x, endPoint.x), y: min(startPoint.y, endPoint.y), width: fabs(startPoint.x - endPoint.x), height: fabs(startPoint.y - endPoint.y))
		return finalSelectionRect
	}
	
	

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
		guard let source = dataSource else {
			print("Tried to draw, but no data source. Returning.")
			return
		}
		
		print("Draw MGCalendarView: \(dirtyRect)")
		
		drawDayElements(in: dirtyRect)
		
		// Draw grid and header
		drawCalendarGrid(in: dirtyRect)
		
		
		if let selection = selectionRect() {
			
			print("Draw selection: \(selection)")
			let selectionPath = NSBezierPath(rect: selection)
			NSColor(white: 0.4, alpha: 0.8).setStroke()
			selectionPath.lineWidth = 1.0
			selectionPath.stroke()
			NSColor(white: 0.8, alpha: 0.4).setFill()
			selectionPath.fill()
			previousSelection = selection
		}
		
		drawHeader(in: dirtyRect)

		
	}
	
	func drawHeader(in rect: NSRect) {
		let path = NSBezierPath()
		let headerY = self.frame.height - self.headerHeight
		path.move(to: NSPoint(x: rect.minX, y: headerY))
		path.line(to: NSPoint(x: rect.maxX, y: headerY))
		NSColor(white: 0.6, alpha: 1.0).setFill()
		path.lineWidth = 1.0
		path.fill()
	}
	
	func drawCalendarGrid(in rect: NSRect) {
		// Draw lines between the weekdays
		for index in 0...7 {
			let path = NSBezierPath()
			let lineY = CGFloat(index) * rowHeight
			path.move(to: NSPoint(x: rect.minX, y: lineY))
			path.line(to: NSPoint(x: rect.maxX, y: lineY))
			NSColor(white: 0.75, alpha: 1.0).setStroke()
			path.lineWidth = 0.5
			path.stroke()
		}
		
		let headerY = self.frame.height - self.headerHeight
		
		for index in 0...weeks.count {
			let path = NSBezierPath()
			let lineX = CGFloat(index) * rowHeight
			path.move(to: NSPoint(x: lineX, y: 0.0))
			path.line(to: NSPoint(x: lineX, y: headerY))
			NSColor(white: 0.75, alpha: 1.0).setStroke()
			path.lineWidth = 0.5
			path.stroke()
		}
	}
	
	func drawDayElements(in rect: NSRect) {
		// Draw text onto calendar days
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .left
		let color = NSColor(white: 0.0, alpha: 1.0)
		let font = NSFont.boldSystemFont(ofSize: 14.0)
		let attributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : font,
													   NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): color,
													   NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue): paragraphStyle]
		
		let halfRowHeight = rowHeight / 2.0
		
		let firstWeek = max(Int((rect.minX / rowHeight).rounded(FloatingPointRoundingRule.down)-4), 0)
		let lastWeek = min(Int((rect.maxX / rowHeight).rounded(FloatingPointRoundingRule.up)+4), weeks.count - 1)
		
		for weekIndex in firstWeek...lastWeek {
			let week = weeks[weekIndex]
			let x = CGFloat(weekIndex) * rowHeight
			
			if week.containsFirstDayOfMonth {
				let text = week.monthDate.shortMonthYear as NSString
				text.draw(in: NSRect(x: x, y: frame.height - headerHeight, width: rowHeight * 4, height: headerHeight), withAttributes: attributes)
			}
			for (dayIndex, day) in week.days.enumerated() {
				let y = CGFloat(6-dayIndex) * rowHeight // Subtract from 6 to reverse the dayIndex for grid alignment
				
				let dayRect = NSRect(x: x, y: y, width: rowHeight, height: rowHeight)
				let fillPath = NSBezierPath(rect: dayRect)
				
				let noMessagesColor = NSColor(red: 235.0/255.0, green: 237.0/255.0, blue: 240.0/255.0, alpha: 1.0)
				
				if let daySafe = day {
					if daySafe.value == 0.0 {
						noMessagesColor.setFill()
					} else {
						let percentage = CGFloat((daySafe.value / maxValue) / 1.5 + 0.15)
						NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: percentage).setFill()
					}
					
					fillPath.fill()
					
					
					let text = "\(daySafe.dayOfMonth)" as NSString
					//					text.draw(in: dayRect, withAttributes: attributes)
				} else {
					
					// Allows the calendar to look like the days before
					// had no texts and the upcoming days are white
					if weekIndex == 0 {
						noMessagesColor.setFill()
						fillPath.fill()
					}
					
					
				}
				
			}
		}
	}
	
	private func fetchValues() {
		
		print("Fetch VALUES ONLY")
		guard let source = dataSource else {
			print("No MGCalendarViewDataSource set")
			return
		}
		
		maxValue = 0.0
		
		for (weekIndex, week) in weeks.enumerated() {
			for dayIndex in 0...6 {
				var day = week.days[dayIndex]
				if let daySafe = day {
					let value = source.calendarView(self, valueFor: daySafe.year, month: daySafe.month, day: daySafe.dayOfMonth)
					
					if value > maxValue {
						maxValue = value
					}
					
					weeks[weekIndex].days[dayIndex]?.value = value
				}
				
			}
		}
		
		self.frame = NSRect(x: 0.0, y: 0.0, width: CGFloat(weeks.count) * rowHeight, height: self.frame.height)
		self.setNeedsDisplay(self.frame)
		
	}
	
	private func fetchData() {
		
		print("Fetch ALL DATA")
		guard let source = dataSource else {
			print("No MGCalendarViewDataSource set")
			return
		}
		
		// Call the data source and get the approprate values
		(startDate, endDate) = source.dateRange(for: self)
		(startColor, endColor) = source.colorRange(for: self)
		
		let calendar = Calendar.current
		
		let components = calendar.dateComponents([.day], from: startDate.startOfDay(), to: endDate.startOfDay())
		let numberOfDays = components.day!
		let firstWeekday = startDate.weekday
		
		var numberOfWeeks = (numberOfDays / 7) // Round down is intentional
		let extra = firstWeekday - 1 + (numberOfDays % 7)
		if extra > 7 {
			numberOfWeeks += 2
		} else if extra > 0 {
			numberOfWeeks += 1
		}
		
		weeks = Array(repeating: Week(), count: numberOfWeeks)
		maxValue = 0.0
		
		for dayNumber in 0...numberOfDays {
			if let date = startDate.startOfDay().add(days: dayNumber) {
				let value = dataSource?.calendarView(self, valueFor: date.year, month: date.month, day: date.day) ?? 0.0
				var day = Day(dayOfMonth: date.day, month: date.month, year: date.year, weekday: date.weekday, date: date, value: value)
				
				if value > maxValue {
					maxValue = value
				}
				
				let indexShift = dayNumber + firstWeekday - 1 // Subtract one to account for difference between array indexing (0-6) and day indexing (1-7)
				weeks[indexShift / 7].days[indexShift % 7] = day
			} else {
				print("Couldn't get date \(dayNumber) days after the calendar start")
			}
		}
		
		self.frame = NSRect(x: 0.0, y: 0.0, width: CGFloat(weeks.count) * rowHeight, height: self.frame.height)
		self.setNeedsDisplay(self.frame)
	}
	
	
}

struct Day {
	var dayOfMonth: Int
	var weekday: Int
	var month: Int
	var year: Int
	var date: Date
	var value: Double
	
	init(dayOfMonth: Int, month: Int, year: Int, weekday: Int, date: Date, value: Double) {
		self.dayOfMonth = dayOfMonth
		self.weekday = weekday
		self.month = month
		self.year = year
		self.date = date
		self.value = value
	}
	
	mutating func setValue(_ newValue: Double) {
		self.value = newValue
	}
}

struct Week {
	var days: [Day?] = Array(repeating: nil, count: 7)
	var monthDate: Date {
		for index in stride(from: 6, through: 0, by: -1) {
			if let day = days[index] {
				return day.date
			}
		}
		
		return Date()
	}
	var containsFirstDayOfMonth: Bool {
		return days.contains(where: { day in
			if let daySafe = day {
				return daySafe.dayOfMonth == 1
			}
			return false
		})
	}
}

// Draws the main content for a MGCalendarView inside an NSScrollView
class MGCalendarWeekdayView: NSView {
	weak var calendarView: MGCalendarView?
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		setup()
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame:frameRect);
		setup()
	}
	
	func setup() {
	}
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		print("Draw MGCalendarWeekdayView")
		
	}
}
