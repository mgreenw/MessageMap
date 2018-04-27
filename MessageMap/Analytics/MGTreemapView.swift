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
	
	class Element: NSBox {
		var value: CGFloat = 0.0
		var label: String = ""
		var photo: Data? = nil
		
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
		}
		
		required init?(coder decoder: NSCoder) {
			super.init(coder: decoder)
		}
		
		func getArea() -> CGFloat {
			return self.frame.width * self.frame.height
		}
	}
	
	func addElement(value: Double, label: String, photo: Data?) {
		let element = Element(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
		element.value = CGFloat(value)
		element.label = label
		element.photo = photo
		element.titlePosition = .noTitle
		elements.append(element)
		self.addSubview(element)
	}
	
	var elements = [Element]()
	
	func reloadTreemap() {
		guard let data = dataSource else {
			print("No data source set, returning")
			return
		}
		
		elements = []
		
		let numberOfElements = data.numberOfValues(for: self)
		
		for index in 0..<numberOfElements {
			let value = data.treemapView(self, valueForIndex: index)
			let photo = data.treemapView(self, photoForIndex: index)
			let label = data.treemapView(self, labelForIndex: index)
			
			addElement(value: value, label: label, photo: photo)
		}
		
		self.setNeedsDisplay(self.frame)
	}
	
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		
		
		
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
		
    }
	
	
	//		// If we are drawing a horizontal row, update the current x points. If not, update the y points.
	//		if (horizontal) {
	//			currX = currX + currRowWidth;
	//			currWidth = currWidth - currRowWidth ;
	//		} else {
	//			currY = currY + currRowWidth;
	//			currHeight = currHeight - currRowWidth;
	//		}
	//
	//
	//		// Find the new horizontal
	//		horizontal = (currHeight < currWidth);
	//
	//		// Increment rowStart to the new row starting child
	//		rowStart = currChild + 1;
	//
	//	}
	//
	//	String name = "";
	//	boolean shouldFilter = false;
	//	for (TreemapPerson p: this.people) {
	//		p.render();
	//		if (clicked && p.contain(mouseX, mouseY)) {
	//			name = p.person.name;
	//			shouldFilter = true;
	//			p.selected = true;
	//			for (TreemapPerson p2: this.people) {
	//				if (p2 != p) p2.selected = false;
	//			}
	//		}
	//	}
	//
	//	if (shouldFilter) {
	//		cm.filterByPerson(name);
	//	}
	//	clicked = false;
	//
	//}
	//
	//// worst
	////   - finds the worst aspect ratio in the row
	//private float worst(List<TreemapPerson> row, float rowWidth) {
	//
	//	// Calculate rowWidth^2, rowArea^2, and the sum pixelRowArea for the row
	//	float wSquared = rowWidth * rowWidth;
	//	float rowArea = sumPixelArea(row);
	//	float rowAreaSquared = rowArea * rowArea;
	//
	//	// Complete the "worst" caluculation to find the worst aspect ratio of all nodes in the row
	//	return max(((wSquared * row.get(0).getArea()) / rowAreaSquared), (rowAreaSquared / (wSquared * row.get(row.size() - 1).getArea())));

	//
	//// updateRowBounds
	////   - Update the w and h values of each node in a row using the rowWidth
	//private float updateRowBounds(List<TreemapPerson> row, float x, float y, float w, float h, float ratio) {
	//
	//	boolean horizontal = (h < w);
	//
	//	// Get the row sumArea and rowWidth
	//	float rowArea = sumArea(row);
	//	float rowWidth = rowWidth(rowArea, ratio, w, h);
	//
	//	// Iterate over each child in the row
	//	for (int i = 0; i < row.size(); i++) {
	//
	//		// Get the rect area to row area ratio, and update the node bounds if horizontal or not, accoringly
	//		TreemapPerson rect = row.get(i);
	//		float rectToRowRatio = rect.person.totalMessageLength / rowArea;
	//
	//		if (horizontal) {
	//			rect.viewX = x;
	//			rect.viewY = (i < 1) ? y : (row.get(i-1).viewY + row.get(i-1).viewHeight);
	//			rect.viewWidth = rowWidth;
	//			rect.viewHeight = rectToRowRatio * h;
	//
	//		} else {
	//			rect.viewX = (i < 1) ? x : (row.get(i-1).viewX + row.get(i-1).viewWidth);
	//			rect.viewY = y;
	//			rect.viewWidth = rectToRowRatio * w;
	//			rect.viewHeight = rowWidth;
	//		}
	//		rect.set(rect.viewX, rect.viewY, rect.viewWidth, rect.viewHeight);
	//	}
	//
	//	return rowWidth;
	//}
	//
	//// sumArea
	////   - Get the sum of all the areas in a row list
	//
	//
	//// sumPixelArea
	////   - Get the sum of all the actual w*h pixels in a row

	
	

	
	
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

