//
//  Store.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift

typealias DayHash = Int

class Store {
    
    // Store's private realm instance
    let realm = try! Realm()

    // Shared Store: allows entire application to use the same filters
	static var shared = Store()
	
    // The chat selected by the user, if applicable
	var selectedChat: Chat? = nil
    
    // All of the messages, sorted by date
    var allMessages = [Message]()
    
    // Array of indexes of message in allMessages
	var filteredMessages = [Int]()
    
    // Array of chats from all filters
    var filteredChats = [Chat]()
    
    // Array of all chat's, sorted by date
	private var sortedChats = [Chat]()
	
    // Functions that will get called when the filteredChats list changes
	private var chatListeners = [() -> Void]()
    
    // Functions that will get called when the filteredMessages list changes
	private var messageListeners = [() -> Void]()
	
    // Set the filters, in the order defined in the FilterType enum
	let filters: [Filter]! = [Filter(name: "Day", type: .day, generateWithout: true, hash: { message in
        return message.dayHash
	}), Filter(name: "Hour", type: .hour, generateWithout: false, hash: { message in
		return message.hour
	}), Filter(name: "Weekday", type: .weekday, generateWithout: false , hash: { message in
		return message.weekday
	}), Filter(name: "WeekdayHour", type: .weekdayHour, generateWithout: true, hash: { message in
		return (message.hour * 10) + message.weekday
	})]
		
    // As soon as the store is initialized, begin the refilter process
	init() {
		newMessagesAdded()
	}
	
	
	func addChatsChangedListener(_ listener: @escaping () -> Void) {
		chatListeners.append(listener)
	}
	
	func addMessagesChangedListener(_ listener: @escaping () -> Void) {
		messageListeners.append(listener)
	}
	
	func refilter() {
//		DispatchQueue.global(qos: .userInitiated).async {
			self.refilterAsync()
//		}
	}
	
	func refilterAsync() {
        
        /*
         The goal here is to avoid unnecessary double filtering. We want to store a list of the
         filtered messages for the selected chat, and a list of filtered chats that contain
         at least one message that passes all of the filter
         */
		
		let realmAsync = try! Realm()
		
		sortedChats = Array(realmAsync.objects(Chat.self).filter("messages.@count > 0").sorted(byKeyPath: "lastMessageDate", ascending: false))
		
        // Reset 'filteredMessages' for each filter
        for filter in filters {
            filter.newFilteredMessages = []
        }
		
		var newFilteredMessages = [Int]()
		var newAllMessages = [Message]()
        
        // Setup a list of predicates to filter the messages by
        let filtersToUse = filters.filter { $0.filters.count > 0 }
        
        let newFilteredChats = sortedChats.filter { chat in
            
            // Iterate through all the messages in a chat:
            // If a single message passes every filter, then include the chat in filteredChats
            chatMessages: for message in chat.messages {
                
                // Iterate through all the filters, and check if the message passes the filter's predicate
                for filter in filtersToUse {
                
                    // If the message fails one filter, then go to the next chat message
                    if !filter.predicate(filter.hash(message)) {
                        continue chatMessages
                    }
                }
                
                // The chat includes a message that passes all the filters, so include it in filteredChats
                return true
            }
            
            // The chat has no messages that pass the filter, so do not include it in filteredChats
            return false
        }
       
		// Set all messages to be the selected chat's messages, otherwise all messages,
		// in either case sorted by date
		if let chat = selectedChat {
			newAllMessages = Array(chat.sortedMessages)
		} else {
			newAllMessages = Array(realmAsync.objects(Message.self).sorted(byKeyPath: "date"))
		}
			
		// Iterate through all messages, and filter out messages that don't match a filter in use
		messages: for (index, message) in newAllMessages.enumerated() {
			var previousRejection: Filter? = nil
			for filter in filtersToUse {
				// If current filter says "No", but every other filter says yes, add it to the "messagesWithoutFilter"
				if !filter.predicate(filter.hash(message)) {
					
					// If the previous rejection has already been set for this
					// message, then there are more than two rejections.
					// In this case, the message will not be a part of any
					// set, so go to the next message
					if previousRejection != nil {
						 continue messages
					}
					
					// If there is no previous rejection, set the current filter
					// to be the previous rejection
					previousRejection = filter
				}
			}
			
			// If there has been exactly one rejection from a filter...
			if let rejection = previousRejection {
				
				// Add the message to the filteredMessages array for that filter
				rejection.newFilteredMessages.append(index)
				
			// If there were no rejections from any filters...
			} else {
				
				// Add the message to the global filteredMessages, and add it
				// to the filtered messages for all the filters
				newFilteredMessages.append(index)
				for filter in filters {
					if filter.generateFilteredMessages {
						filter.newFilteredMessages.append(index)
					}
				}
			}
		}
		
		// Begin syncronous calls...
//		DispatchQueue.main.sync {
		self.allMessages = newAllMessages
		
		for filter in self.filters {
			filter.filteredMessages = filter.newFilteredMessages
		}
		
		if newFilteredChats != self.filteredChats {
			self.filteredChats = newFilteredChats
			for listener in self.chatListeners {
				listener()
			}
			
			print("Chats not equal")
		}
		
		if newFilteredMessages != self.filteredMessages {
			self.filteredMessages = newFilteredMessages
			
			for listener in self.messageListeners {
				listener()
			}
		}
		

//		}
	}
	
	func newMessagesAdded() {
		// Recreate data structures to help filter speed
		refilter()
	}
	
	func setChat(to chat: Chat?) {
		self.selectedChat = chat
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
			return allMessages[messageIndex]
		}
		return nil
	}
	
	func enumerateMessages(_ action: (Message) -> Void) {
		for index in 0..<filteredMessages.count {
			action(allMessages[filteredMessages[index]])
		}
	}
	
	func countForFilter(_ filterType: FilterType) -> Int {
		return filters[filterType.rawValue].filteredMessages.count
	}
	
	func messageForFilter(_ filterType: FilterType, at index: Int) -> Message? {
		if let messageIndex = filters[filterType.rawValue].filteredMessages[safe: index] {
			return allMessages[safe: messageIndex]
		}
		return nil
	}
	
	func enumerateMessagesForFilter(_ filterType: FilterType, _ action: (Message) -> Void) {
		let filter = filters[filterType.rawValue]
		for index in 0..<filter.filteredMessages.count {
			action(allMessages[filter.filteredMessages[index]])
		}
	}
}
