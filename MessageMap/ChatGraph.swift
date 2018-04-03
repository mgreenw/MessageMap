
//
//  ChatGraph.swift
//  MessageMap
//
//  Created by Max Greenwald on 12/5/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

struct Segment {
	
	// the color of a given segment
	var color: NSColor
	
	// the value of a given segment – will be used to automatically calculate a ratio
	var value: CGFloat
}

class ChatGraph: NSView {
	
	var segments = [Segment]() {
		didSet {
			setNeedsDisplay(self.frame) // re-draw view when the values get set
		}
	}
	var area: NSTrackingArea = NSTrackingArea()
	var tracking: Any? = nil
	var mouseInsideView = false
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
	}
	
	required init(coder decoder: NSCoder) {
		super.init(coder: decoder)!
	}
	
	override func draw(_ dirtyRect: NSRect) {
		drawPie(inFrame: dirtyRect)
	}
	
	func drawPie(inFrame rect: NSRect) {
		// radius is the half the frame's width or height (whichever is smallest)
		let radius = min(frame.size.width, frame.size.height) * 0.5
		
		// center of the view
		let viewCenter = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
		
		// enumerate the total value of the segments by using reduce to sum them
		let valueCount = segments.reduce(0, {$0 + $1.value})
		
		// the starting angle is -90 degrees (top of the circle, as the context is flipped). By default, 0 is the right hand side of the circle, with the positive angle being in an anti-clockwise direction (same as a unit circle in maths).
		var startAngle = -CGFloat.pi * 0.5
		
		for segment in segments { // loop through the values array
			
			// set fill color to the segment color
			segment.color.setFill()
			
			// update the end angle of the segment
			let endAngle = startAngle + 2 * .pi * (segment.value / valueCount)
			
			
//			print("Start:", startAngle, "End:", endAngle)
			
			// move to the center of the pie chart
			let arc = NSBezierPath()
			arc.move(to: viewCenter)
			
			// add arc from the center for each segment (anticlockwise is specified for the arc, but as the view flips the context, it will produce a clockwise arc)
			arc.appendArc(withCenter: viewCenter, radius: radius, startAngle: radToDeg(rad: startAngle), endAngle: radToDeg(rad: endAngle), clockwise: false)
//			print("Arc:", arc)
//			print(self.convert(mouseLocation, to: self))
			if arc.contains(self.convert(mouseLocation, to: self))	 {
//				print("CONTAINS LOCATION")
				NSColor.white.setFill()
			}
			
			// fill segment
			
			arc.fill()
			
			// update starting angle of the next segment to the ending angle of this segment
			startAngle = endAngle
		}
		
		area = NSTrackingArea.init(rect: self.frame, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
		self.addTrackingArea(area)
	}
	
	var mouseLocation: NSPoint {
		return NSEvent.mouseLocation
	}
	var location: NSPoint {
		return window!.mouseLocationOutsideOfEventStream
	}
	
	// TODO: Not sure why
	
//	override func mouseEntered(with event: NSEvent) {
//		mouseInsideView = true
//		do {
//			tracking = try NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
//
//				if self.mouseInsideView {
//					print("mouseLocation:", String(format: "%.1f, %.1f", self.mouseLocation.x, self.mouseLocation.y))
//					self.setNeedsDisplay(self.frame)
//
//
//				}
//				return $0
//			}
//		} catch {
//			print("Unable to add tracking...")
//		}
//		print(event.locationInWindow.x, "Entered")
//	}
//
//	override func mouseExited(with event: NSEvent) {
//
//		mouseInsideView = false
//		print(event.locationInWindow.x, "Exited")
//	}
//
	func radToDeg(rad: CGFloat) -> CGFloat {
		return rad * (CGFloat(180.0) / .pi)
	}
	
}
