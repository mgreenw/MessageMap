//
//  MGPunchcardView.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/20/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

protocol MGPunchcardViewDataSource: AnyObject {
	func punchcardView(_ punchcardView: MGPunchcardView, valueFor weekday: Int, hour: Int) -> Double?
}

// @objc needed to make funcs optional
protocol MGPunchcardViewDelegate: AnyObject {
	func calendarViewSelectionDidChange(_ notification: Notification)
}

class MGPunchcardView: NSView {
	weak var delegate: MGPunchcardViewDelegate?
	weak var dataSource: MGPunchcardViewDataSource?
	
	private var maxValue: Double = 0.0
	
	var punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
	
	let weekdayLabelWidth: CGFloat = 30.0
	let hourLabelHeight: CGFloat = 30.0
	
	let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	let hours = ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11",]
	
	func reloadPunchcard() {
		punchcardValues = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
		maxValue = 0.0
		for weekday in 0...6 {
			for hour in 0...23 {
				let value = dataSource?.punchcardView(self, valueFor: weekday, hour: hour) ?? 0.0
				maxValue = max(value, maxValue)
				punchcardValues[weekday][hour] = value
			}
		}
		
		self.setNeedsDisplay(self.frame)
	}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		let weekdayHeight = (self.frame.height - hourLabelHeight) / 7
		let weekdaySubdivision = weekdayHeight / 9
		let maxRadius = weekdaySubdivision * 3
		let maxArea = CGFloat.pi * pow(maxRadius, 2)
		
		let hourWidth = (self.frame.width - weekdayLabelWidth) / 24
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		let color = NSColor(white: 0.0, alpha: 1.0)
		let font = NSFont.boldSystemFont(ofSize: 12.0)
		let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : font,
														NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): color,
														NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue): paragraphStyle]
		
		// draw hour labels
		for (index, hour) in hours.enumerated() {
			let x = weekdayLabelWidth + (CGFloat(index) * hourWidth)
			let hourString = hour as NSString
			hourString.draw(in: NSRect(x: x, y: 0, width: hourWidth, height: hourLabelHeight), withAttributes: attributes)
		}
		
		for (weekdayIndex, day) in weekDays.enumerated() {
			let y = hourLabelHeight + (CGFloat(weekdayIndex) * weekdayHeight)
			
			NSColor(white: 0.6, alpha: 1.0).setStroke()
			
			// draw horizontal lines
			let path = NSBezierPath()
			path.move(to: NSPoint(x: 0, y: y))
			path.line(to: NSPoint(x: self.frame.width, y: y))
			path.stroke()
			
			// Draw the weekday label string
			let dayString = day as NSString
			dayString.draw(in: NSRect(x: 0, y: y, width: weekdayLabelWidth, height: weekdayHeight), withAttributes: attributes)
			
			// draw tick marks and the size of the
			let circleY = y + (weekdaySubdivision * 5)
			
			for (hourIndex, hour) in hours.enumerated() {
				
				// draw the tick mark
				let x = weekdayLabelWidth + (CGFloat(hourIndex) * hourWidth) + (hourWidth / 2)
				let tick = NSBezierPath()
				tick.move(to: NSPoint(x: x, y: y))
				tick.line(to: NSPoint(x: x, y: y + weekdaySubdivision))
				tick.stroke()
				
				let value = punchcardValues[weekdayIndex][hourIndex]
				print("Value: \(value)")
				let area = (CGFloat(value) / CGFloat(maxValue)) * maxArea
				
				let radius = sqrt(area/CGFloat.pi)
				
				NSColor.black.setFill()
				
				let circle = NSBezierPath()
				circle.appendArc(withCenter: NSPoint(x: x, y: circleY), radius: radius, startAngle: 0, endAngle: 360)
				
				circle.fill()
			}
			
			
			
		}
		
		// draw
		
		
    }
    
}
