//
//  Extensions.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/10/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

extension Date {

	var day: Int {
		return Calendar.current.component(.day, from: self)
	}

	var month: Int {
		return Calendar.current.component(.month, from: self)
	}

	var shortMonthYear: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "LLL yyyy"
		return dateFormatter.string(from: self)
	}

	var year: Int {
		return Calendar.current.component(.year, from: self)
	}

	var hour: Int {
		return Calendar.current.component(.hour, from: self)
	}

	var minute: Int {
		return Calendar.current.component(.minute, from: self)
	}

	var daysInMonth: Int {
		return Calendar.current.range(of: .day, in: .month, for: self)!.count
	}

	var weekday: Int {
		return Calendar.current.component(.weekday, from: self)
	}

	var firstDayOfTheMonth: Date {
		return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
	}

	func getNextMonth() -> Date? {
		return Calendar.current.date(byAdding: .month, value: 1, to: self)
	}

	func getPreviousMonth() -> Date? {
		return Calendar.current.date(byAdding: .month, value: -1, to: self)
	}

	func add(months: Int) -> Date? {
		return Calendar.current.date(byAdding: .month, value: months, to: self)
	}

	func startOfDay() -> Date {
		return Calendar.current.startOfDay(for: self)
	}

	func getNextDay() -> Date {
		return Calendar.current.date(byAdding: .day, value: 1, to: self)!
	}

	func add(days: Int) -> Date {
		return Calendar.current.date(byAdding: .day, value: days, to: self)!
	}
	
	func add(weeks: Int) -> Date {
		return Calendar.current.date(byAdding: .day, value: 7 * weeks, to: self)!
	}
}

extension NSView {
	func addConstraintsWithFormat(format: String, views: NSView...) {

		var viewsDict = [String: NSView]()
		for (index, view) in views.enumerated() {
			let key = "v\(index)"
			viewsDict[key] = view
			view.translatesAutoresizingMaskIntoConstraints = false
		}

		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDict))

	}
}

extension Array where Element: Comparable {
	func containsSameElements(as other: [Element]) -> Bool {
		return self.count == other.count && self.sorted() == other.sorted()
	}
}

extension Array where Element: Person {
	func unique() -> [Person] {

		// Great solution from here https://stackoverflow.com/questions/27624331/unique-values-of-array-in-swift
		var seen: [String: Bool] = [:]
		return self.filter { seen.updateValue(true, forKey: $0.id) == nil }
	}
}

extension Collection where Indices.Iterator.Element == Index {
	
	/// Returns the element at the specified index iff it is within bounds, otherwise nil.
	subscript (safe index: Index) -> Iterator.Element? {
		return indices.contains(index) ? self[index] : nil
	}
}



// Adapted from this article: https://medium.com/@jackywangdeveloper/swift-the-right-way-to-add-target-in-uibutton-in-using-closures-877557ed9455
typealias NSControlTargetClosure = (NSControl) -> ()
class ClosureWrapper: NSObject {
	var closure: NSControlTargetClosure = { button in
		
	}
	var attachTo: NSControl = NSControl()
	init(attachTo: NSControl, closure: @escaping NSControlTargetClosure) {
		super.init()
		self.closure = closure
		self.attachTo = attachTo
		objc_setAssociatedObject(attachTo, "[\(arc4random())]", self, .OBJC_ASSOCIATION_RETAIN)
	}
	
	@objc func invoke() {
		closure(attachTo)
	}
}
extension NSControl {
	func addAction(action: @escaping NSControlTargetClosure) {
		let sleeve = ClosureWrapper(attachTo: self, closure: action)
		self.target = sleeve
		self.action = #selector(ClosureWrapper.invoke)
	}
}
