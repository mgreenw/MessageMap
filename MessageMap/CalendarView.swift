//
//  CalendarView.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/14/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

class CalendarView: NSView {
	let monthHeight: CGFloat = 30
	let dayWidth: CGFloat = 40
	var daySpacing: CGFloat = 2
	var days = [CalendarDay]()
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setup(rect: frameRect)
		
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
        for _ in 0...6 {
            let day = CalendarDay(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            self.days.append(day)
            self.addSubview(day)
        }
		setup(rect: self.bounds)
	}
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
        setup(rect: dirtyRect)
	}
	
	func setup(rect: NSRect) {
		let dayDim = (rect.height - monthHeight - (daySpacing * 7)) / 7
		print(dayDim)
		for i in 0...6 {
            let day = self.days[i]
            day.frame = NSRect(x: dayDim, y: (CGFloat(i) * dayDim) + (CGFloat(i+1) * daySpacing), width: dayDim, height: dayDim)
		}
	}
	
}
