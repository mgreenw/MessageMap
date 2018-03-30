//
//  Store.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation

class Store: NSObject, Codable {
	
	// Initialize shared store that all classes will have access to
	static var shared = Store()
	
	
	
	// Initialize arrays to hold all of the data
	// Handled by iMessage Parser
	var chats = [Chat]()
	var people = [Person]()
	var messages = [Message]()
	var attachments = [Attachment]()
	
	// Time Arrays
	// Handled locally
	var years = [Year]()
	var months = [Month]()
	var weekdays = [Weekday]()
	var days = [Day]()
	var hours = [Hour]()
	var minutes = [Minute]()
	
	private var yearsDict = [Int: Year]()
	private var monthsDict = [Int: Month]()
	private var weekdaysDict = [Int: Weekday]()
	private var hoursDict = [Int: Hour]()
	private var minutesDict = [Int: Minute]()
	
	// Initialze the handles to make handle strings to people
	var handles = [String:Person]()
	
	// This is me! First name and last name will be updated in the Contact Parser
	var me: Person = Person(firstName: "Me", lastName: nil, isMe: true)
	
	override init() {
		super.init()
		months.reserveCapacity(13)
		weekdays.reserveCapacity(8)
		hours.reserveCapacity(24)
		minutes.reserveCapacity(60)
		for i in 1...12 { months.insert(Month(month: i), at: i-1)}
		for i in 1...7 { weekdays.insert(Weekday(weekday: i), at: i-1)}
		for i in 0...23 { hours.insert(Hour(hour: i), at: i) }
		for i in 0...59 { minutes.insert(Minute(minute: i), at: i)}
	}
	
	func sortData() {
		
		let initialDate = Date(timeIntervalSinceReferenceDate: 0)
		chats = chats.sorted(by: { ($0.lastMessageDate ?? initialDate) > ($1.lastMessageDate ?? initialDate) })
		
		var alreadyMatched = [Chat]()
		for (index, chat) in chats.enumerated() {
			for i in index + 1..<chats.count {
				
				if !alreadyMatched.contains(chat) {
					let otherChat = chats[i]
					
					if chat.hasSamePeople(as: otherChat) {
						chat.combine(with: otherChat)
						alreadyMatched.append(otherChat)
					}
				}
			}
		}
		
		chats = chats.filter { !alreadyMatched.contains($0) }
		
		// Sort chat messages and people
		for chat in chats {
			chat.messages = chat.messages.sorted(by: {$0.date < $1.date})
			chat.people = chat.people.sorted(by: { ($0.firstName ?? "") < ($1.firstName ?? "") })
		}
		
	}
	
	func add(person: Person) {
		self.people.append(person)
	}
	
	func add(handleName: String, person: Person) {
		self.handles[handleName] = person
	}
	
	func add(chat: Chat) {
		self.chats.append(chat)
	}
	
	
	func add(message: Message) {
		self.messages.append(message)
		
		// Add To Year
//		let yearInt = message.date.year
//		if let year = yearsDict[yearInt] {
//			year.add(message: message)
//		} else {
//			let year = Year(year: yearInt)
//			year.add(message: message)
//			yearsDict[yearInt] = year
//		}
//
//		months[message.date.month-1].add(message: message)
//
//		// Add To Weekday
//		weekdays[message.date.weekday-1].add(message: message)
//
//		// Add To Hour
//		hours[message.date.hour].add(message: message)
//
//		// Add To Minute
//		minutes[message.date.minute].add(message: message)
	}
}
