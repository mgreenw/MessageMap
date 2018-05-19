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
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var idInt: Int = {
		return Int(Date().timeIntervalSince1970 * 10000000)
	}()
	@objc dynamic var firstName: String?
	@objc dynamic var lastName: String?
	@objc dynamic var isMe = false
	let messages = LinkingObjects(fromType: Message.self, property: "sender")
	let chats = LinkingObjects(fromType: Chat.self, property: "participants")
	let handles = LinkingObjects(fromType: Handle.self, property: "person")
	@objc dynamic var contactID: String?
	@objc dynamic var photo: Data?
}

class Chat: Object {
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var archived = false
	@objc dynamic var displayName: String?
	let messages = LinkingObjects(fromType: Message.self, property: "chat")

	let participants = List<Person>()
	var participantsCalculated: Array<Person> {
		return Array(messages.sorted(byKeyPath: "date", ascending: true).distinct(by: ["sender.id"])).map { $0.sender } .filter { $0?.isMe == false && $0 != nil } as! Array<Person>
	}
	let iMessageID = RealmOptional<Int>()
	@objc dynamic var lastMessageDate: Date?

	var lastMessageDateSafe: Date {
		if let date = self.lastMessageDate {
			return date
		}
		return Date.distantPast
	}

	var sortedMessages: Results<Message> {
		return messages.sorted(byKeyPath: "date")
	}
}

@objc enum Service: Int {
	case iMessage
	case SMS
	case Facebook
	case Unknown
}

class ChatJoin: Object {
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var service: Service = .iMessage
	@objc dynamic var originalChatID = 0
	@objc dynamic var chat: Chat?
}

class Message: Object {
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var sender: Person?
	@objc dynamic var chat: Chat?
	@objc dynamic var date = Date()
	@objc dynamic var fromMe = false
	@objc dynamic var text: String?
	@objc dynamic var attributedBody: String?
	@objc dynamic var year = 0
	@objc dynamic var month = 0
	@objc dynamic var hour = 0
	@objc dynamic var minute = 0
	@objc dynamic var weekday = 0
	@objc dynamic var dayOfMonth = 0
	@objc dynamic var service: Service = .iMessage
	let attachments = LinkingObjects(fromType: Attachment.self, property: "message")

	let iMessageID = RealmOptional<Int>()

	// Layout Precalculations
	@objc dynamic var textFieldX: Double = 0.0
	@objc dynamic var textFieldWidth: Double = 0.0
	@objc dynamic var textFieldHeight: Double = 0.0
	@objc dynamic var bubbleX: Double = 0.0
	@objc dynamic var bubbleWidth: Double = 0.0
	@objc dynamic var bubbleHeight: Double = 0.0
	@objc dynamic var layoutHeight: Double = 0.0
    
    var dayHash: Int {
        return year * 10000 + month * 100 + dayOfMonth
    }
}

class Handle: Object {
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var handle = ""
	@objc dynamic var person: Person?
	let iMessageID = RealmOptional<Int>()
}

class Attachment: Object {
	@objc dynamic var id = UUID().uuidString
	@objc dynamic var message: Message?
	@objc dynamic var filename = ""
	@objc dynamic var uti: String?
	@objc dynamic var mimeType: String?
	@objc dynamic var transferName = ""
	let iMessageID = RealmOptional<Int>()
}
