//
//  Models.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
//import RealmSwift

class Store: Codable {
	static let shared = Store()
	
	var chats = [Chat]()
	var people = [Person]()
	var messages = [Message]()
	var handles = [Handle]()
	var attachments = [Attachment]()
	var me: Person?
	
	func sortData() {
		let initialDate = Date(timeIntervalSinceReferenceDate: 0)
		chats = chats.sorted(by: { ($0.lastMessageDate ?? initialDate) > ($1.lastMessageDate ?? initialDate) })
		
		var alreadyMatched = [Chat]()
		for (index, chat) in chats.enumerated() {
			for i in index + 1..<chats.count {
				
				if !alreadyMatched.contains(where: {(c: Chat) -> Bool in return c === chat }) {
					let otherChat = chats[i]
					
					if chat.hasSamePeople(as: otherChat) {
						chat.combine(with: otherChat)
						alreadyMatched.append(otherChat)
						print(index, i)
						print("Has same people:", chat.people.map { $0.fullName() }, otherChat.people.map { $0.fullName() })
						
					}
				}
			}
		}
		
		chats = chats.filter ({(chat: Chat) -> Bool in !alreadyMatched.contains(where: {(c: Chat) -> Bool in return c === chat })})
		
		// Sort chat messages and people
		for chat in chats {
			chat.messages = chat.messages.sorted(by: {$0.date < $1.date})
			chat.people = chat.people.sorted(by: { ($0.firstName ?? "") < ($1.firstName ?? "") })
		}
		
	}
}

class Chat: Codable {
	var people = [Person]()
	var messages = [Message]()
	var isArchived = false
	var displayName: String?
	var lastMessageDate: Date?
	
	init(displayName: String? = nil) {
		self.displayName = displayName
	}
	
	func combine(with otherChat: Chat) {
		otherChat.messages = otherChat.messages.sorted(by: {$0.date < $1.date})
		self.messages = self.messages.sorted(by: {$0.date < $1.date})
		if let otherLast = otherChat.messages.last {
			if let selfLast = self.messages.last {
				self.displayName = selfLast.date > otherLast.date ? self.displayName :  otherChat.displayName
			} else {
				self.displayName = otherChat.displayName
			}
		}
		
		for message in otherChat.messages {
			self.add(message: message)
		}
		
		self.messages = self.messages.sorted(by: {$0.date < $1.date})
	}
	
	func add(message: Message) {
		self.messages.append(message)
		if let lastDate = lastMessageDate {
			if message.date > lastDate {
				lastMessageDate = message.date
			}
		} else {
			lastMessageDate = message.date
		}
	}
	
	func add(person: Person) {
		if (self.people.contains(where: {(p: Person) -> Bool in return p === person })) {
			print("Can't add same person twice to a chat")
		} else {
			self.people.append(person)
		}
	}
	
	func hasSamePeople(as other: Chat) -> Bool {
		
		// Check that the arrays have the same length
		if other.people.count != self.people.count {return false}
		
		for person in other.people {
			if !(self.people.contains(where: {(p: Person) -> Bool in return p === person })) {
				return false
			}
		}
		return true
	}
}

class Person: Codable {
	var isMe = false
	var firstName: String?
	var lastName: String?
	var messages = [Message]()
	var lastMessageDate: Date?
	
	init(firstName: String?, lastName: String?) {
		self.firstName = firstName
		self.lastName = lastName
	}
	
	func fullName() -> String {
		return (firstName ?? "") + " " + (lastName ?? "")
	}
	
	func add(message: Message) {
		self.messages.append(message)
		if let lastDate = lastMessageDate {
			if message.date > lastDate {
				lastMessageDate = message.date
			}
		}
	}
}

class Message: Codable {
	var sender: Person!
	var text: String? = nil
	var date: Date!
	var attachments = [Attachment]()
	var fromMe = false
	var chat: Chat!
	
	init(sender: Person, chat: Chat, date: Date, text: String? = nil) {
		self.sender = sender
		self.chat = chat
		self.date = date
		self.text = text
	}
}

class Handle: Codable {
	var person: Person!
	var handle: String!
	var country: String!
	
	init(person: Person, handle: String, country: String) {
		self.person = person
		self.handle = handle
		self.country = country
	}
}

class Attachment: Codable {
	
}

class MutableOrderedSet: NSMutableOrderedSet, Codable {
	enum CodingKeys: String, CodingKey {
		case valueArray
	}
	
	public required convenience init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let arr = try values.decode(Array<Any>.self, forKey: .valueArray)
		self.init()
		self.addObjects(from: arr)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.array, forKey: .valueArray)
	}
}
