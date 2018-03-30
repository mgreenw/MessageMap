//
//  Models.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift

class Person: Object {
	@objc dynamic var firstName: String? = nil
	@objc dynamic var lastName: String? = nil
	@objc dynamic var isMe = false
	let messages = LinkingObjects(fromType: Message.self, property: "sender")
	let chats = LinkingObjects(fromType: Chat.self, property: "participants")
}

class Chat: Object {
	@objc dynamic var archived = false
	@objc dynamic var displayName = ""
	let messages = LinkingObjects(fromType: Message.self, property: "chat")
	let participants = List<Person>()
}

class Message: Object {
	@objc dynamic var sender: Person?
	@objc dynamic var chat: Chat?
	@objc dynamic var date = Date()
	@objc dynamic var fromMe = false
	@objc dynamic var text: String? = nil
	@objc dynamic var year = 0
	@objc dynamic var month = 0
	@objc dynamic var hour = 0
	@objc dynamic var minute = 0
	@objc dynamic var dayOfWeek = 0
	@objc dynamic var dayOfMonth = 0
}

class Handle: Object {
	@objc dynamic var handle = ""
	@objc dynamic var person: Person?
}

class Attachment: Object {
	@objc dynamic var message: Message?
	@objc dynamic var path = ""
}

class Meta: Object {
	@objc dynamic var key = ""
	@objc dynamic var value: Any?
}

//
//class ExactlyEqual: Equatable {
//	static func == (one: ExactlyEqual, two: ExactlyEqual) -> Bool {
//		return one === two
//	}
//}
//
//class Chat: ExactlyEqual, Codable {
//    var people = [Person]()
//    var messages = [Message]()
//    var isArchived = false
//    var displayName: String?
//    var lastMessageDate: Date?
//
//    init(displayName: String? = nil) {
//		super.init()
//        self.displayName = displayName
//    }
//
//    func combine(with otherChat: Chat) {
//        otherChat.messages = otherChat.messages.sorted(by: {$0.date < $1.date})
//        self.messages = self.messages.sorted(by: {$0.date < $1.date})
//        if let otherLast = otherChat.messages.last {
//            if let selfLast = self.messages.last {
//                self.displayName = selfLast.date > otherLast.date ? self.displayName :  otherChat.displayName
//            } else {
//                self.displayName = otherChat.displayName
//            }
//        }
//
//        for message in otherChat.messages {
//            self.add(message: message)
//        }
//
//        self.messages = self.messages.sorted(by: {$0.date < $1.date})
//    }
//
//    func add(message: Message) {
//        self.messages.append(message)
//        if let lastDate = lastMessageDate {
//            if message.date > lastDate {
//                lastMessageDate = message.date
//            }
//        } else {
//            lastMessageDate = message.date
//        }
//    }
//
//    func add(person: Person) {
//        if (self.people.contains(where: {(p: Person) -> Bool in return p === person })) {
//            print("Can't add same person twice to a chat")
//        } else {
//            self.people.append(person)
//        }
//    }
//
//    func hasSamePeople(as other: Chat) -> Bool {
//
//        // Check that the arrays have the same length
//        if other.people.count != self.people.count {return false}
//
//        for person in other.people {
//            if !(self.people.contains(where: {(p: Person) -> Bool in return p === person })) {
//                return false
//            }
//        }
//        return true
//    }
//}
//
//class Person: ExactlyEqual, Codable{
//    var isMe = false
//    var firstName: String?
//    var lastName: String?
//    var messages = [Message]()
//    var lastMessageDate: Date?
//
//    init(firstName: String?, lastName: String?, isMe: Bool = false) {
//		super.init()
//        self.firstName = firstName
//        self.lastName = lastName
//        self.isMe = isMe
//    }
//
//    func fullName() -> String {
//        return (firstName ?? "") + " " + (lastName ?? "")
//    }
//
//    func add(message: Message) {
//        self.messages.append(message)
//        if let lastDate = lastMessageDate {
//            if message.date > lastDate {
//                lastMessageDate = message.date
//            }
//        }
//    }
//}
//
//class Message: ExactlyEqual, Codable {
//    var sender: Person!
//    var text: String? = nil
//    var date: Date!
//    var attachments = [Attachment]()
//    var fromMe = false
//    var chat: Chat!
//
//    init(sender: Person, chat: Chat, date: Date, text: String? = nil) {
//		super.init()
//        self.sender = sender
//        self.chat = chat
//        self.date = date
//        self.text = text
//    }
//}
//
//class Attachment: ExactlyEqual, Codable {
//
//	override init() {
//		super.init()
//	}
//
//}
//
///*
//TIME
//*/
//
//class Time: ExactlyEqual {
//	var messages = [Message]()
//	var people = [Person]()
//	var chats = [Chat]()
//
//	override init() {
//		super.init()
//	}
//
//	func add(message: Message) {
//		self.messages.append(message)
//
//		if (!self.people.contains(message.sender)) {
//			self.people.append(message.sender)
//		}
//
//		if (!self.chats.contains(message.chat)) {
//			self.chats.append(message.chat)
//		}
//	}
//}
//
//class Year: Time, Codable {
//
//	var year: Int
//
//	init(year: Int) {
//
//		assert(year > 2000 && year <= 3000)
//		self.year = year
//		super.init()
//	}
//}
//
//class Month: Time, Codable {
//	var month: Int
//
//	init(month: Int) {
//
//		assert(month <= 12 && month >= 1)
//		self.month = month
//		super.init()
//	}
//}
//
//class Weekday: Time, Codable {
//	var weekday: Int
//
//	init(weekday: Int) {
//
//		assert(weekday <= 7 && weekday >= 1)
//		self.weekday = weekday
//		super.init()
//	}
//}
//
//class Day: Time, Codable {
//	var date: Date!
//}
//
//class Hour: Time, Codable {
//	var hour: Int
//
//	init(hour: Int) {
//
//		assert(hour < 24 && hour >= 0)
//		self.hour = hour
//		super.init()
//	}
//}
//
//class Minute: Time, Codable {
//	var minute: Int
//
//	init(minute: Int) {
//
//		assert(minute < 60 && minute >= 0)
//		self.minute = minute
//		super.init()
//	}
//}
//
//class MutableOrderedSet: NSMutableOrderedSet, Codable {
//    enum CodingKeys: String, CodingKey {
//        case valueArray
//    }
//
//    public required convenience init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        let arr = try values.decode(Array<Any>.self, forKey: .valueArray)
//        self.init()
//        self.addObjects(from: arr)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.array, forKey: .valueArray)
//    }
//}
//
//extension Date {
//
//    var yesterday: Date {
//        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
//    }
//    var tomorrow: Date {
//        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
//    }
//    var noon: Date {
//        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
//    }
//    var month: Int {
//        return Calendar.current.component(.month,  from: self)
//    }
//    var day: Int {
//        return Calendar.current.component(.day,  from: self)
//    }
//    var weekday: Int {
//        return Calendar.current.component(.weekday,  from: self)
//    }
//    var year: Int {
//        return Calendar.current.component(.year,  from: self)
//    }
//	var minute: Int {
//		return Calendar.current.component(.minute, from: self)
//	}
//	var hour: Int {
//		return Calendar.current.component(.hour, from: self)
//	}
//    var isLastDayOfMonth: Bool {
//        return tomorrow.month != month
//    }
//}

