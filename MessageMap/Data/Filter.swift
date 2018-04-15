//
//  Filter.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/15/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Foundation

struct DayID: Hashable, Equatable {
	var year: Int = 0
	var month: Int = 0
	var day: Int = 0
	
	var string: String {
		return "\(year)-\(month)-\(day)"
	}
	
	var int: Int {
		return year * 10000 + month * 100 + day
	}
}

enum FilterType: Int {
	case day = 0
	case hour = 1
	case weekday = 2
}


class Filter {
	var name: String
	var type: FilterType
	func predicate(_ value: Int) -> Bool {
		return self.filters.contains(value)
	}
	var transform: (Message) -> Int
	var filters = Set<Int>()
	var messagesWithout = [Int]()
	var generateWithout: Bool
	
	init(name: String, type: FilterType, generateWithout: Bool, transform: @escaping (Message) -> Int) {
		self.name = name
		self.type = type
		self.transform = transform
		self.generateWithout = generateWithout
	}
}
