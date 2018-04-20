//
//  Store.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift

class Store {

	// Initialize shared store that all classes will have access to
	static var shared = Store()
	
	var chat: Chat? = nil
	var filteredMessages = [Int]()
	var messages = [Message]()
	var chats = [Chat]()
	
	let realm = try! Realm()
	
	private var sortedChats = [Chat]()
	
	// chat id to set of the days in the chat that contain messages
	var daysInChat = [String: Set<Int>]()
	
	var chatListeners = [() -> Void]()
	var messageListeners = [() -> Void]()
	
	var filters: [Filter]! = [Filter(name: "Day", type: .day, generateWithout: true, transform: { message in
		let messageDay = DayID(year: message.year, month: message.month, day: message.dayOfMonth)
		return messageDay.int
	}), Filter(name: "Hour", type: .hour, generateWithout: false, transform: { message in
		return message.hour
	}), Filter(name: "Weekday", type: .weekday, generateWithout: false ,transform: { message in
		return message.weekday
	}), Filter(name: "WeekdayHour", type: .weekdayHour, generateWithout: true, transform: { message in
		return (message.hour * 10) + message.weekday
	})]
		
	init() {
		print("Init Store")
		newMessagesAdded()
	}
	
	// This function is used to ensure that the shared Filter singleton has been initialized
	func startStore() {
		print("Starting filter")
	}
	
	func addChatsChangedListener(_ listener: @escaping () -> Void) {
		chatListeners.append(listener)
	}
	
	func addMessagesChangedListener(_ listener: @escaping () -> Void) {
		messageListeners.append(listener)
	}
	
	func refilter() {
		
		for filter in filters {
			filter.messagesWithout = []
		}
		
		let prevMessages = filteredMessages
		let prevChats = chats
		
		// Filter chats by daysInChat
		// This does not yet take into account hour filters or weekday filters
		let dayFilters = filters[FilterType.day.rawValue]
		if dayFilters.filters.count > 0 {
			chats = sortedChats.filter { chat in
				daysInChat[chat.id]!.intersection(dayFilters.filters).count > 0
			}
		} else {
			chats = sortedChats
		}
		
		if chats != prevChats {
			for listener in chatListeners {
				listener()
			}
		}
		
		// Get the chat if it does
		if let chatSafe = chat {
			// Setup a list of predicates to filter the messages by
			let filtersToUse = filters.filter { $0.filters.count > 0 }
			let filtersToGenerate = filters.filter { $0.generateWithout }
			
			// Get the messages and filter them by the predicates!
			messages = Array(chatSafe.sortedMessages)
			filteredMessages = []
			
			let dayFilter = filters[FilterType.day.rawValue]
			
			for (index, message) in messages.enumerated() {
				var rejectionCount = 0
				var previousRejection: Filter = dayFilter
				for filter in filtersToUse {
					// If current filter says "No", but every other filter says yes, add it to the "messagesWithoutFilter"
					if !filter.predicate(filter.transform(message)) {
						rejectionCount += 1
						previousRejection = filter
					}
				}
				if rejectionCount == 0 {
					filteredMessages.append(index)
					for filter in filters {
						if filter.generateWithout {
							filter.messagesWithout.append(index)
						}
					}
					
				} else if rejectionCount == 1 {
					previousRejection.messagesWithout.append(index)
				}
			}

		} else {
			print("No chat selected")
			messages = Array(realm.objects(Message.self).sorted(byKeyPath: "date"))
			let fullIndexArray = messages.count > 0 ? Array(0...messages.count-1) : []
			filteredMessages = fullIndexArray
			for filter in filters {
				if filter.generateWithout {
					filter.messagesWithout = fullIndexArray
				}
			}
		}

		if filteredMessages != prevMessages {
			for listener in messageListeners {
				listener()
			}
		}
	}
	
	func newMessagesAdded() {
		// Recreate data structures to help filter speed
		sortedChats = Array(realm.objects(Chat.self).filter("messages.@count > 0").sorted(byKeyPath: "lastMessageDate", ascending: false))
		
		daysInChat.removeAll()
		for chat in sortedChats {
			let days = Set(chat.messages.map { message in
				DayID(year: message.year, month: message.month, day: message.dayOfMonth).int
			})
			daysInChat[chat.id] = days
		}
		
		refilter()
	}
	
	func setChat(to chat: Chat?) {
		self.chat = chat
		refilter()
	}
	
	func addFilter(_ filterType: FilterType, by: [Int]) {
		let filter = filters[filterType.rawValue]
		filter.filters = filter.filters.union(by)
		refilter()
	}
	
	func removeFilter(_ filterType: FilterType, by: [Int]) {
		let filter = filters[filterType.rawValue]
		filter.filters = filter.filters.subtracting(by)
		refilter()
	}
	
	func removeAllFiltersFor(_ filterType: FilterType) {
		let filter = filters[filterType.rawValue]
		filter.filters.removeAll()
		refilter()
	}
	
	func setFilter(_ filterType: FilterType, to: [Int]) {
		let filter = filters[filterType.rawValue]
		filter.filters = Set(to)
		refilter()
	}
	
	func count() -> Int {
		return filteredMessages.count
	}
	
	func message(at index: Int) -> Message? {
		if let messageIndex = filteredMessages[safe: index] {
			return messages[messageIndex]
		}
		return nil
	}
	
	func enumerateMessages(_ action: (Message) -> Void) {
		for index in 0..<filteredMessages.count {
			action(messages[filteredMessages[index]])
		}
	}
	
	func countForFilter(_ filterType: FilterType) -> Int {
		return filters[filterType.rawValue].messagesWithout.count
	}
	
	func messageForFilter(_ filterType: FilterType, at index: Int) -> Message? {
		if let messageIndex = filters[filterType.rawValue].messagesWithout[safe: index] {
			return messages[safe: messageIndex]
		}
		return nil
	}
	
	func enumerateMessagesForFilter(_ filterType: FilterType, _ action: (Message) -> Void) {
		let filter = filters[filterType.rawValue]
		for index in 0..<filter.messagesWithout.count {
			action(messages[filter.messagesWithout[index]])
		}
	}
}
