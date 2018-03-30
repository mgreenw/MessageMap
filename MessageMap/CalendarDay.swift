//
//  CalendarDay.swift
//  MessageMap
//
//  Created by Max Greenwald on 12/3/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

class CalendarDay: NSButton {

	let color = NSColor.blue

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.toolTip = "This is a day"
		
		let area = NSTrackingArea.init(rect: frameRect, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
		self.addTrackingArea(area)
	}
	
	required init(coder decoder: NSCoder) {
		super.init(coder: decoder)!
	}
	
    override func draw(_ dirtyRect: NSRect) {
		let path = NSBezierPath(rect: dirtyRect)
		color.setStroke()
		path.stroke()
    }
	
	override func mouseEntered(with event: NSEvent) {
		print("Entered")
	}
	
	override func mouseExited(with event: NSEvent) {
		print("exited")
	}
    
}
