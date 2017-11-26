//
//  Models.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift


struct Landmark: Codable {
	var name: String
	var foundingYear: Int
	
	// Landmark now supports the Codable methods init(from:) and encode(to:),
	// even though they aren't written as part of its declaration.
}

class Chat: Object {
	let people = List<Person>()
	let messages = LinkingObjects(fromType: Message.self, property: "chat")
	@objc dynamic var isArchived = false
	@objc dynamic var displayName: String?
	
	func lastMessageBefore(date: Date) -> Message? {
		let sortedMessages = messages.sorted(byKeyPath: "date", ascending: false)
		return sortedMessages.first
	}
	
	func lastDateBefore(date: Date) -> Date? {
		let sortedMessages = messages.sorted(byKeyPath: "date", ascending: false)
		return sortedMessages.first?.date
	}
}

class Person: Object {
	@objc dynamic var isMe = false
	@objc dynamic var firstName = ""
	@objc dynamic var lastName = ""
	let messages = LinkingObjects(fromType: Message.self, property: "sender")
	
	func fullName() -> String {
		return firstName + " " + lastName
	}
}

class Message: Object {
	@objc dynamic var sender: Person?
	@objc dynamic var text: String?
	@objc dynamic var date = Date(timeIntervalSince1970: 1)
	let attachments = LinkingObjects(fromType: Attachment.self, property: "message")
	@objc dynamic var fromMe = false
	@objc dynamic var chat: Chat?
}

class Handle: Object {
	@objc dynamic var person: Person?
	@objc dynamic var handle = ""
	@objc dynamic var service: Service?
	@objc dynamic var country = ""
}

class Service: Object {
	@objc dynamic var name = ""
}

class Attachment: Object {
	@objc dynamic var message: Message?
	
}
