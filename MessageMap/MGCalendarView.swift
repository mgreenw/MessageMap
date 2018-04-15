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
	func calendarView(_ calendarView: MGCalendarView, valueFor year: Int, month: Int, day: Int) -> Double?
}

// @objc needed to make funcs optional
protocol MGCalendarViewDelegate: AnyObject {
	func calendarViewSelectionDidChange(_ notification: Notification)
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

	var selectionStart: Day?
	var selectionEnd: Day?
	private var selectedDays: Set<Day> = Set<Day>()
	public var selection: [DayID] {
		return selectedDays.map { day in
			DayID(year: day.year, month: day.month, day: day.day)
		}
	}

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
		super.init(frame: frameRect)
		setup()
	}

	func setup() {
		setRowHeight()
	}

	override func mouseDown(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)
		if isInsideContent(point: mousePoint) {
			if let day = translate(point: mousePoint) {
				selectionStart = day
				selectionEnd = day
			}
			
			if let invalidated = selectionInvalidatedRect() {
				self.setNeedsDisplay(invalidated.insetBy(dx: rowHeight * -3.0, dy: -10.0))
			}
		}
	}

	override func mouseDragged(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)
		
		if isInsideContent(point: mousePoint) {
			let endDay = translate(point: mousePoint)
			if endDay != selectionEnd {
				selectionEnd = endDay
				if let invalidated = selectionInvalidatedRect() {
					self.setNeedsDisplay(invalidated.insetBy(dx: rowHeight * -3.0, dy: -10.0))
				}
			}
		}
	}

	override func mouseUp(with event: NSEvent) {
		let mousePoint = self.convert(event.locationInWindow, from: nil)
		if isInsideContent(point: mousePoint) {
			selectionEnd = translate(point: mousePoint)
			
			if let start = selectionStart, let end = selectionEnd {
				
				// Complete the selection!
				setRangeSelected(from: start, to: end)
			}
		}
		
		if let invalidated = selectionInvalidatedRect() {
			self.setNeedsDisplay(invalidated.insetBy(dx: rowHeight * -3.0, dy: -10.0))
		}
		selectionStart = nil
		selectionEnd = nil
	}

	func selectionInvalidatedRect() -> NSRect? {
		guard let startDay = selectionStart else {
			return nil
		}
		guard let endDay = selectionEnd else {
			return nil
		}
		
		let startPoint = translate(week: startDay.weekIndex, day: startDay.index)
		let endPoint = translate(week: endDay.weekIndex, day: endDay.index)

		let finalSelectionRect: NSRect? = NSRect(x: min(startPoint.x, endPoint.x), y: 0.0, width: fabs(startPoint.x - endPoint.x), height: frame.height)
		return finalSelectionRect
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		guard let source = dataSource else {
			print("Tried to draw, but no data source. Returning.")
			return
		}

//		print("Draw MGCalendarView: \(dirtyRect)")

		drawDayElements(in: dirtyRect)

		// Draw grid and header
		drawCalendarGrid(in: dirtyRect)

		
		drawSelectionInProgress(in: dirtyRect)
		drawSelectedDays(in: dirtyRect)
		drawHeader(in: dirtyRect)

	}
	
	func drawSelectedDays(in rect: NSRect) {
		let path = NSBezierPath()
		NSColor(white: 0.8, alpha: 0.4).setFill()
		NSColor(white: 0.4, alpha: 0.8).setStroke()
		path.lineWidth = 2.0
		
		func pathLine(from: NSPoint, to: NSPoint) {
			path.move(to: from)
			path.line(to: to)
		}
		
		for day in selectedDays {
			
			let dayIndex = day.index
			let weekIndex = day.weekIndex
			
//			 TODO: Clean this up...
			if let left = add(weeks: -1, toDay: dayIndex, inWeek: weekIndex), left.selected {} else {
				pathLine(from: translate(week: weekIndex, day: dayIndex), to: translate(week: weekIndex, day: dayIndex - 1))
			}

			if let right = add(weeks: 1, toDay: dayIndex, inWeek: weekIndex), right.selected {} else {
				pathLine(from: translate(week: weekIndex + 1, day: dayIndex), to: translate(week: weekIndex + 1, day: dayIndex - 1))
			}

			if let up = add(days: -1, toDay: dayIndex, inWeek: weekIndex), up.selected, dayIndex > 0 {} else {
				pathLine(from: translate(week: weekIndex, day: dayIndex - 1), to: translate(week: weekIndex + 1, day: dayIndex - 1))
			}

			if let down = add(days: 1, toDay: dayIndex, inWeek: weekIndex), down.selected, dayIndex < 6 {} else {
				pathLine(from: translate(week: weekIndex, day: dayIndex), to: translate(week: weekIndex + 1, day: dayIndex))
			}
		}
		
//		print(shapes)
		
		path.stroke()
		path.fill()
	}
	
	func drawSelectionInProgress(in rect: NSRect) {
		if let path = pathForCurrentSelection() {
			NSColor(white: 0.8, alpha: 0.4).setFill()
			NSColor(white: 0.4, alpha: 0.8).setStroke()
			path.stroke()
			path.fill()
		}
	}
	
	func pathForCurrentSelection() -> NSBezierPath? {
		guard let firstDay = selectionStart else { return nil }
		guard let lastDay = selectionEnd else { return nil }

		var numberOfDays = (lastDay.weekIndex - firstDay.weekIndex) * 7 + (lastDay.index - firstDay.index)
		let backwards = numberOfDays < 0
		
		// Not ideal, need to clean this
		let startWeek = backwards ? lastDay.weekIndex : firstDay.weekIndex
		let startDay = backwards ? lastDay.index : firstDay.index
		let endWeek = backwards ? firstDay.weekIndex : lastDay.weekIndex
		let endDay = backwards ? firstDay.index : lastDay.index
		
		numberOfDays = abs(numberOfDays) + 1
		let contiguous = numberOfDays > 7
		
		let path = NSBezierPath()
		path.lineWidth = 2.0
		
		if contiguous {
			// Draw a contiguous selection
			path.move(to: NSPoint(x: translate(week: startWeek), y: translate(day: startDay - 1)))
			path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: 6)))
			path.line(to: NSPoint(x: translate(week: endWeek), y: translate(day: 6)))
			path.line(to: NSPoint(x: translate(week: endWeek), y: translate(day: endDay)))
			path.line(to: NSPoint(x: translate(week: endWeek + 1), y: translate(day: endDay)))
			path.line(to: NSPoint(x: translate(week: endWeek + 1), y: translate(day: -1)))
			path.line(to: NSPoint(x: translate(week: startWeek + 1), y: translate(day: -1)))
			path.line(to: NSPoint(x: translate(week: startWeek + 1), y: translate(day: startDay - 1)))
			path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: startDay - 1)))
		} else {
			// Draw a non-contiguous selection
			path.move(to: NSPoint(x: translate(week: startWeek), y: translate(day: startDay - 1)))
			path.line(to: NSPoint(x: translate(week: startWeek+1), y: translate(day: startDay - 1)))
			
			if endWeek > startWeek {
				// Two sections
				path.line(to: NSPoint(x: translate(week: startWeek+1), y: translate(day: 6)))
				path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: 6)))
				path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: startDay - 1)))
				
				path.move(to: NSPoint(x: translate(week: endWeek), y: translate(day: -1)))
				path.line(to: NSPoint(x: translate(week: endWeek+1), y: translate(day: -1)))
				path.line(to: NSPoint(x: translate(week: endWeek+1), y: translate(day: endDay)))
				path.line(to: NSPoint(x: translate(week: endWeek), y: translate(day: endDay)))
				path.line(to: NSPoint(x: translate(week: endWeek), y: translate(day: -1)))
			} else {
				// One section
				path.line(to: NSPoint(x: translate(week: startWeek+1), y: translate(day: endDay)))
				path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: endDay)))
				path.line(to: NSPoint(x: translate(week: startWeek), y: translate(day: startDay - 1)))
			}
		}
		
		return path
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
		// Horizontal -> -1 gets the top of the first day
		for index in -1...6 {
			let path = NSBezierPath()
			let lineY = translate(day: index)
			let minX = translate(week: 0)
			path.move(to: NSPoint(x: max(rect.minX, minX), y: lineY))
			path.line(to: NSPoint(x: rect.maxX, y: lineY))
			NSColor(white: 0.75, alpha: 1.0).setStroke()
			path.lineWidth = 0.5
			path.stroke()
		}

		let headerY = self.frame.height - self.headerHeight

		// Vertical
		for index in 0...weeks.count {
			let path = NSBezierPath()
			let lineX = translate(week: index)
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
		let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : font,
													   NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): color,
													   NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue): paragraphStyle]

		let halfRowHeight = rowHeight / 2.0

		let firstWeek = max(Int((rect.minX / rowHeight).rounded(FloatingPointRoundingRule.down)-4), 0)
		let lastWeek = min(Int((rect.maxX / rowHeight).rounded(FloatingPointRoundingRule.up)+4), weeks.count - 1)

		for weekIndex in firstWeek...lastWeek {
			let week = weeks[weekIndex]
			let x = translate(week: weekIndex)

			if week.containsFirstDayOfMonth {
				let text = week[6].date.shortMonthYear as NSString
				text.draw(in: NSRect(x: x, y: frame.height - headerHeight, width: rowHeight * 4, height: headerHeight), withAttributes: attributes)
			}
			
			for (dayIndex, day) in week.days.enumerated() {
				let dayRect = NSRect(x: x, y: translate(day: dayIndex), width: rowHeight, height: rowHeight)
				let fillPath = NSBezierPath(rect: dayRect)

				let noMessagesColor = NSColor(red: 235.0/255.0, green: 237.0/255.0, blue: 240.0/255.0, alpha: 1.0)

				if day.value != 0.0 {
					let percentage = CGFloat((day.value / maxValue) / 1.5 + 0.15)
					NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: percentage).setFill()
					
					fillPath.fill()

					let text = "\(day.day)" as NSString
					//					text.draw(in: dayRect, withAttributes: attributes)
				} else {

					// Allows the calendar to look like the days before
					// had no texts and the upcoming days are white
					noMessagesColor.setFill()
					fillPath.fill()

				}

			}
		}
	}

	public func reloadValues() {
		print("Reload Calendar Values")
		guard let source = dataSource else {
			print("No MGCalendarViewDataSource set")
			return
		}

		// Reset the maxValue before fetching new values
		maxValue = 0.0
		
		// Fetch the value for each day in the week
		for week in weeks {
			for day in week.days {
				let value = source.calendarView(self, valueFor: day.year, month: day.month, day: day.day) ?? 0.0
				maxValue = max(maxValue, value)
				day.value = value
			}
		}
		
		// Set the frame of the view to have the correct width for the number of weeks
		self.frame = NSRect(x: 0.0, y: 0.0, width: translate(week: weeks.count) - 1.0, height: self.frame.height)
		self.setNeedsDisplay(self.frame)
	}

	public func reloadCalendar() {

		print("Reload Calendar")
		guard let source = dataSource else {
			print("No MGCalendarViewDataSource set")
			return
		}

		// Call the data source and get the approprate values
		(startDate, endDate) = source.dateRange(for: self)
		(startColor, endColor) = source.colorRange(for: self)

		let numberOfDays = Calendar.current.dateComponents([.day], from: startDate.startOfDay(), to: endDate.startOfDay()).day!
		let firstWeekday = startDate.weekday

		var numberOfWeeks = (numberOfDays / 7) // Round down is intentional
		let extraWeek = firstWeekday - 1 + (numberOfDays % 7) > 7
		numberOfWeeks += extraWeek ? 2 : 1
		
		// Reset class variables
		weeks.removeAll()
		maxValue = 0.0

		// Setup the weeks
		for index in 0..<numberOfWeeks {
			
			// Create the week and add it to the week array
			let week = Week(index: index, dateInWeek: startDate.add(weeks: index))
			weeks.append(week)
		}
	}
	
	private func translate(week: Int, day: Int) -> NSPoint {
		return NSPoint(x: translate(week: week), y: translate(day: day))
	}
	
	private func translate(week: Int) -> CGFloat {
		return dayLabelWidth + (CGFloat(week) * rowHeight)
	}
	
	private func translate(day: Int) -> CGFloat {
		// Subtract from 6 to reverse the dayIndex for grid alignment
		return CGFloat(6 - day) * rowHeight
	}
	
	// Returns (weekIndex, dayIndex)
	private func translate(point: NSPoint) -> Day? {
		let dayIndex = 6 - Int((point.y / rowHeight).rounded(.down))
		if let weekIndex = translate(x: point.x) {
			return dayFor(week: weekIndex, day: dayIndex)
		}
		return nil
	}
	
	// Returns week index if applicable
	private func translate(x: CGFloat) -> Int? {
		let index: Int = Int(((x - dayLabelWidth) / rowHeight).rounded(.down))
		if let _ = weeks[safe: index] {
			return index
		}
		return nil
	}
	
	private func dayFor(week weekIndex: Int, day dayIndex: Int) -> Day? {
		if let week = weeks[safe: weekIndex] {
			if let day = week.days[safe: dayIndex] {
				return day
			}
		}
		return nil
	}

	public func contentRect() -> NSRect {
		return NSRect(x: translate(week: 0), y: 0.0, width: translate(week: weeks.count), height: translate(day: -1))
	}
	
	private func isInsideContent(point: NSPoint) -> Bool {
		return contentRect().contains(point)
	}
	
	func add(days: Int, toDay dayIndex: Int, inWeek weekIndex: Int) -> Day? {
		let weeksToAdd = days / 7
		let extraWeek = abs(dayIndex + (days % 7)) > 7
		let newWeek = weekIndex + weeksToAdd + ((weeksToAdd < 0 ? -1 : 1) * (extraWeek ? 1 : 0))
		var newDay = (dayIndex + days) % 7
		newDay = newDay < 0 ? newDay + 7 : newDay
		
		if let day = dayFor(week: newWeek, day: newDay) {
			return day
		}
		return nil
	}
	
	func add(weeks: Int, toDay dayIndex: Int, inWeek weekIndex: Int) -> Day? {
		return add(days: 7 * weeks, toDay: dayIndex, inWeek: weekIndex)
	}

	func setSelected(day: Day) {
		day.selected = true
		selectedDays.insert(day)
		selectionChanged()
	}
	
	func setDeselected(day: Day) {
		day.selected = false
		selectedDays.remove(day)
		selectionChanged()
	}
	
	func setRangeSelected(from: Day, to: Day) {
		iterateDaysBetween(from, and: to, with: { day in
			day.selected = true
			selectedDays.insert(day)
		})
		selectionChanged()
	}
	
	func setRangeDeselected(from: Day, to: Day) {
		iterateDaysBetween(from, and: to, with: { day in
			day.selected = false
			selectedDays.remove(day)
		})
		selectionChanged()
	}
	
	public func setAllDeselected() {
		iterateDaysBetween(weeks[0][0], and: weeks.last![6], with: { day in
			day.selected = false
			selectedDays.remove(day)
		})
		selectionChanged()
	}
	
	private func selectionChanged() {
		delegate?.calendarViewSelectionDidChange(Notification(name: Notification.Name(rawValue: "selectionDidChange")))
	}
	
	func iterateDaysBetween(_ from: Day, and to: Day, with task: (Day) -> Void) {
		if from == to { task(from) }
		let positive = from.date < to.date
		let start = positive ? from : to
		let end = positive ? to : from
		
		if start.weekIndex < end.weekIndex {
			for dayIndex in start.index...6 {
				
				if let day = dayFor(week: start.weekIndex, day: dayIndex) {
					task(day)
				}
			}
		
		
			for weekIndex in (start.weekIndex + 1)..<end.weekIndex {
				for dayIndex in 0...6 {
					if let day = dayFor(week: weekIndex, day: dayIndex) {
						task(day)
					}
				}
			}
		
		
			for dayIndex in 0...end.index {
				if let day = dayFor(week: end.weekIndex, day: dayIndex) {
					task(day)
				}
			}
		} else {
			for dayIndex in start.index...end.index {
				if let day = dayFor(week: start.weekIndex, day: dayIndex) {
					task(day)
				}
			}
		}
	}
}

class Week {
	var days:[Day] = [Day]()
	var index: Int! = 0
	
	init(index: Int, dateInWeek: Date) {
		self.index = index
		
		let firstDay: Date = dateInWeek.add(days: -1 * (dateInWeek.weekday - 1))
		for weekday in 0...6 {
			let day = Day(date: firstDay.add(days: weekday))
			day.week = self
			days.append(day)
		}
	}
	
	subscript(index: Int) -> Day {
		assert(index >= 0 && index < 7)
		return days[index]
	}
	
	var containsFirstDayOfMonth: Bool {
		return days.contains(where: { day in
			return day.day == 1
		})
	}
	
	var valueSum: Double {
		return days.reduce(into: 0, { sum, day in
			sum + day.value
		})
	}
}


class Day: CustomStringConvertible, Hashable {
	var date: Date!
	var day: Int { return date.day }
	var weekday: Int { return date.weekday }
	var month: Int { return date.month }
	var year: Int { return date.year }
	var index: Int { return weekday - 1 }
	var value: Double = 0.0
	var week: Week!
	var selected: Bool = false
	
	var weekIndex: Int {
		return week.index!
	}
	
	let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd"
		return formatter
	}()
	
	convenience init() {
		self.init(date: Date())
	}
	
	init(date: Date) {
		self.date = date
	}
	
	var description: String {
		return "Day(\(month)/\(day)/\(year) -> \(value)) @ (\(week.index!), \(index))" + (selected ? " & Selected" : "")
	}
	
	var hashValue: Int {
		if let hash = Int(dateFormatter.string(from: date)) {
			return hash
		} else {
			return 0
		}
	}
	
	static func == (lhs: Day, rhs: Day) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}
