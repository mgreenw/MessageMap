//
//  Filter.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/15/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Foundation

// A list of the current filters
// Should exactly match Store.shared.filters by index
enum FilterType: Int {
	case day = 0
	case hour = 1
	case weekday = 2
	case weekdayHour = 3
	case person = 4
}

class Filter {
	var name: String
	var type: FilterType

    // A function that generates a hash from a message for a specific filter
	var hash: (Message) -> Int

    // A set of hashes representing the messages to filter
    // If empty, do not use this filter
	var filters = Set<Int>()

    // Index of messages including messages that are filtered by all other filters
    // EXCEPT for the messages filtered by the current filter
	var filteredMessages = [Int]()

	var newFilteredMessages = [Int]()

    // Whether this filter should generate its own 'filteredMessages', which is a costly process
	var generateFilteredMessages: Bool

	init(name: String, type: FilterType, generateWithout: Bool, hash: @escaping (Message) -> Int) {
		self.name = name
		self.type = type
		self.hash = hash
		self.generateFilteredMessages = generateWithout
	}

    // Check if the filters contains the specific hash
    func predicate(_ value: Int) -> Bool {
        return self.filters.contains(value)
    }
}
