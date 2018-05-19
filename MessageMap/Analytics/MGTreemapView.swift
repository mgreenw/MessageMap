//
//  MGTreemapView.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/25/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

protocol MGTreemapViewDataSource: AnyObject {
	func numberOfValues(for treemapView: MGTreemapView) -> Int
	func treemapView(_ treemapView: MGTreemapView, valueForIndex index: Int) -> Double
	func treemapView(_ treemapView: MGTreemapView, photoForIndex index: Int) -> Data?
	func treemapView(_ treemapView: MGTreemapView, labelForIndex index: Int) -> String
}

// @objc needed to make funcs optional
protocol MGTreemapViewDelegate: AnyObject {
	func treemapViewSelectionDidChange(_ notification: Notification)
}

class MGTreemapView: NSView {
	weak var delegate: MGPunchcardViewDelegate?
	weak var dataSource: MGTreemapViewDataSource?
	
	class Element {
		let value: CGFloat
		let label: String
		let photo: Data?
		
		var frame: CGRect = NSZeroRect
		
		init(value: CGFloat, label: String, photo: Data?) {
			self.value = value
			self.label = label
			self.photo = photo
		}
		
		func getArea() -> CGFloat {
			return self.frame.width * self.frame.height
		}
		
		func draw() {
			let path = NSBezierPath(rect: frame)
			NSColor.black.setStroke()
			path.stroke()
		}
	}
	
	func addElement(value: Double, label: String, photo: Data?) {
		var element = Element(value: CGFloat(value), label: label, photo: photo)
		elements.append(element)
	}
	
	var elements = [Element]()
	
	func reloadTreemap() {
		guard let data = dataSource else {
			print("No data source set, returning")
			return
		}
		
		elements = []
		
		let numberOfElements = data.numberOfValues(for: self)
		print("number of elements: \(numberOfElements)")
		
		for index in 0..<numberOfElements {
			let value = data.treemapView(self, valueForIndex: index)
			let photo = data.treemapView(self, photoForIndex: index)
			let label = data.treemapView(self, labelForIndex: index)
			
			addElement(value: value, label: label, photo: photo)
		}
		
		elements = elements.sorted(by: {elementOne, elementTwo in
			elementOne.value > elementTwo.value
		})
		
		print(self.frame)
		DispatchQueue.main.async {
			self.setNeedsDisplay(NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
		}
	}
	
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		
		print("Draw treemap")
		print(dirtyRect)
				
		var x: CGFloat = 0.0
		var y: CGFloat = 0.0
		var width: CGFloat = self.frame.width
		var height: CGFloat = self.frame.height
		
		var horizontal: Bool = (height < width);
		var rowStart: Int = 0
		var currRowWidth: CGFloat = 0.0
		
		let ratio: CGFloat = (width * height) / sumArea(elements)
		
		for (currChild, element) in elements.enumerated() {
			
			let currRow = Array(elements[rowStart..<currChild + 1])
			if currChild < (elements.count - 1) {
				let nextRow = Array(elements[rowStart..<currChild + 2])
				let _ = updateRowBounds(row: nextRow, x: x, y: y, width: width, height: height, ratio: ratio)
				
				let shortSide: CGFloat = min(width, height)
				
				let nextRatio = worst(row: nextRow, rowWidth: shortSide)
				
				currRowWidth = updateRowBounds(row: currRow, x: x, y: y, width: width, height: height, ratio: ratio)
				let currRatio: CGFloat = worst(row: currRow, rowWidth: shortSide)
				
				if (currRatio > nextRatio) {
					continue
				}
				
			} else {
				currRowWidth = updateRowBounds(row: currRow, x: x, y: y, width: width, height: height, ratio: ratio)
			}
			
			if (horizontal) {
				x = x + currRowWidth
				width = width - currRowWidth
			} else {
				y = y + currRowWidth
				height = height - currRowWidth
			}
			
			horizontal = (height < width)
			rowStart = currChild + 1
		}
		
		for element in elements {
			element.draw()
		}
    }

	
	

	
	
	func worst(row: [Element], rowWidth: CGFloat) -> CGFloat {
		let wSquared: CGFloat = rowWidth * rowWidth
		let rowArea = sumPixelArea(row)
		let rowAreaSquared = rowArea * rowArea
		return max(((wSquared * row[0].getArea()) / rowAreaSquared), (rowAreaSquared / (wSquared * row[row.count - 1].getArea())))
	}
	

	
	func updateRowBounds(row: [Element], x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, ratio: CGFloat) -> CGFloat {
		let horizontal: Bool = height < width
		
		let rowArea = sumArea(row)
		let rowWidth = calculateRowWidth(rowArea: rowArea, ratio: ratio, width: width, height: height)
		
		for (i, element) in row.enumerated() {
			let rectToRowRatio: CGFloat = element.value / rowArea
			
			if (horizontal) {
				element.frame = NSRect(x: x,
									   y: (i < 1) ? y : (row[i-1].frame.minY + row[i-1].frame.height),
									   width: rowWidth,
									   height: rectToRowRatio * height)
			} else {
				element.frame = NSRect(x: (i < 1) ? x : (row[i-1].frame.minX + row[i-1].frame.width),
									   y: y,
									   width: rectToRowRatio * width,
									   height: rowWidth)
			}
		}
		
		return rowWidth
	}
	
	func calculateRowWidth(rowArea: CGFloat, ratio: CGFloat, width: CGFloat, height: CGFloat) -> CGFloat {
		let horizontal: Bool = height < width
		return ratio * (rowArea / (horizontal ? height : width));
	}
	
	private func sumArea(_ row: [Element]) -> CGFloat {
		return row.reduce(0.0, { result, element in
			return result + CGFloat(element.value)
		})
	}
	
	private func sumPixelArea (_ row: [Element]) -> CGFloat {
		return row.reduce(0.0, { result, element in
			return result + CGFloat(element.getArea())
		})
	}
}

