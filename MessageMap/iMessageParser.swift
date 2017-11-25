//
//  iMessageParser.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SQLite
import RealmSwift
import Contacts

class iMessageParser: NSObject {
	let home = FileManager.default.homeDirectoryForCurrentUser
	let fileManager = FileManager.default
	
	// Define generic "ROWID" column
	let idCol = Expression<Int64>("ROWID")
	
	// Define table and columns for "chat" table
	let chatTable = Table("chat")
	let displayNameCol = Expression<String>("display_name")
	let isArchivedCol = Expression<Int64>("is_archived")
	
	// Define table and columns for "handle" table
	let handleTable = Table("handle")
	let handleCol = Expression<String>("id")
	let countryCol = Expression<String>("country")
	
	// Define table and columns for "message" table
	let messageTable = Table("message")
	let textCol = Expression<String>("text")
	let handleIdCol = Expression<Int>("handle_id")
	let isFromMeCol = Expression<Int>("is_from_me")
	let dateCol = Expression<Int>("date")
	let otherHandleIdCol = Expression<Int>("other_handle")
	
	// Define table and columns for "chat_message_join" table
	let chatMessageJoinTable = Table("chat_message_join")
	let chatIdCol = Expression<Int>("chat_id")
	let messageIdCol = Expression<Int>("message_id")
	
	// Define table and columns for "chat_handle_join" table
	let chatHandleJoinTable = Table("chat_handle_join")

	override init() {
		let realm = try! Realm()
		
		try! realm.write {
			realm.deleteAll()
		}
		
		print("Realm Path : \(realm.configuration.fileURL?.absoluteURL)")
		let store = CNContactStore()
		let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
		let keysToFetch = keys.map {$0 as CNKeyDescriptor}
		
		func sanitizeEmail(_ email: String) -> String {
			let sanitized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
			return sanitized
		}
		
		func sanitizePhone(_ phone: String) -> String {
			let nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+"]
			var num = phone.filter({ nums.contains(String($0)) })
			if !num.hasPrefix("+") {
				num = "+1" + num
			}
			
			return num
		}
		
		var personDict = [String:Person]()
		
		let me = Person()
		me.isMe = true
		
		if let meContact = try? store.unifiedMeContactWithKeys(toFetch: keysToFetch) {
			me.firstName = meContact.givenName
			me.lastName = meContact.familyName
			
			let emailAddresses = meContact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = meContact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			
			for email in emailAddresses {
				personDict[email] = me
			}
			
			for phone in phoneNumbers {
				personDict[phone] = me
			}
			
		} else {
			print("Cannot get 'me' contact.")
			me.firstName = "My"
			me.lastName = "Self"
		}
		
		try! realm.write {
			realm.add(me)
		}
		
		
		try? store.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact: CNContact, bool) in
			
			let newPerson = Person()
			newPerson.firstName = contact.givenName
			newPerson.lastName = contact.familyName
			
			let emailAddresses = contact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = contact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			
			for email in emailAddresses {
				personDict[email] = newPerson
			}
			
			for phone in phoneNumbers {
				personDict[phone] = newPerson
			}
			
			try! realm.write {
				realm.add(newPerson)
			}
		}
		
		let iMessageURL = home.appendingPathComponent("/Library/Messages/chat.db")
		guard fileManager.fileExists(atPath: iMessageURL.path) == true else {
			print("iMessage database cannot be located. Exiting")
			return
		}

		guard let db = try? Connection(iMessageURL.path, readonly: true) else {
			print("Failed to connect to iMessage database")
			return
		}

		print("Initialized iMesasge database")

		guard let chats = try? db.prepare(chatTable) else {
			print("Failed to get chats table")
			return
		}
		
		guard let handles = try? db.prepare(handleTable) else {
			print("Failed to get handles table")
			return
		}
		
		guard let messages = try? db.prepare(messageTable) else {
			print("Failed to get handles table")
			return
		}
		
		guard let chatMessageJoins = try? db.prepare(chatMessageJoinTable) else {
			print("Failed to get chat_message_join table")
			return
		}
		
		guard let chatHandleJoins = try? db.prepare(chatHandleJoinTable) else {
			print("Failed to get chat_handle_join table")
			return
		}
		
		// Initialize the temporary Chats Dictionary
		var chatsDict = [Int:Chat]()
		var handlesDict = [Int:Handle]()
		var messagesDict = [Int:Message]()
		var chatMessageJoinDict = [Int:Chat]()
		
		// Iterate through all the handles and make new Handle Objects
		for handle in handles {
			guard let id = try? Int(handle.get(idCol)) else {
				print("Handle has no ROWID, therefore skipping.")
				continue
			}
			guard var handleName = try? handle.get(handleCol) else {
				print("Could not get handle's 'id' column, therefore skipping")
				continue
			}
			guard let country = try? handle.get(countryCol) else {
				print("Could not get handle's 'country' column, therefore skipping")
				continue
			}
			
			let newHandle = Handle()
			newHandle.country = country
			
			if handleName.contains("@") {
				handleName = sanitizeEmail(handleName)
			} else {
				handleName = sanitizePhone(handleName)
			}
			
			newHandle.handle = handleName
			
			if let person = personDict[handleName] {
				newHandle.person = person
			} else {
				
				// If we do not have a person yet for this handle, make one
				let newPerson = Person()
				newPerson.firstName = handleName
				personDict[handleName] = newPerson
				newHandle.person = newPerson
				
				try! realm.write {
					realm.add(newPerson)
				}
			}
			
			handlesDict[id] = newHandle
			
			try! realm.write {
				realm.add(newHandle)
			}
		}

		// Iterate through all the chats and make new Chat Objects
		for chat in chats {

			guard let id = try? Int(chat.get(idCol)) else {
				print("Chat has no ID, therefore skipping.")
				continue
			}
			
			var displayName = try? chat.get(displayNameCol)
			if displayName == "" {
				displayName = nil
			}
			
			guard let isArchived = try? Int(chat.get(isArchivedCol)) else {
				print("Could not get chat's 'is_archived' column, therefore skipping")
				continue
			}
			
			let newChat = Chat()
			newChat.displayName = displayName
			newChat.isArchived = isArchived == 1 ? true : false
			
			chatsDict[id] = newChat
			
			try! realm.write {
				realm.add(newChat)
			}
		}
		
		for chatMessageJoin in chatMessageJoins {
			guard let chatId = try? chatMessageJoin.get(chatIdCol) else {
				print("Could not get 'chat_message_join's chat_id column, therefore skipping")
				continue
			}
			guard let messageId = try? chatMessageJoin.get(messageIdCol) else {
				print("Could not get 'chat_message_join's message_id column, therefore skipping")
				continue
			}
			
			chatMessageJoinDict[messageId] = chatsDict[chatId]
		}
		
		for chatHandleJoin in chatHandleJoins {
			guard let chatId = try? chatHandleJoin.get(chatIdCol) else {
				print("Could not get 'chat_handle_join's chat_id column, therefore skipping")
				continue
			}
			guard let handleId = try? chatHandleJoin.get(handleIdCol) else {
				print("Could not get 'chat_handle_join's message_id column, therefore skipping")
				continue
			}
			
			if let person = handlesDict[handleId]?.person {
				if let chat = chatsDict[chatId] {
					try! realm.write {
						chat.people.append(person)
					}
					
				} else {
					print("Couldn't find chat with id \(chatId)")
				}
			} else {
				print("Couldn't find person with handle ID \(handleId)")
			}
		}
		
		// Iterate through all the messages and make new Message Objects
		for message in messages {
			guard let id = try? Int(message.get(idCol)) else {
				print("Handle has no ROWID, therefore skipping.")
				continue
			}
			let text = try? message.get(textCol)
			guard let handleId = try? message.get(handleIdCol) else {
				print("Could not get message's 'handle_id' column, therefore skipping")
				continue
			}
			
			guard let isFromMe = try? message.get(isFromMeCol) else {
				print("Could not get message's 'is_from_me' column, therefore skipping")
				continue
			}
			
			guard var date = try? message.get(dateCol) else {
				print("Could not get message's 'date' column, therefore skipping")
				continue
			}

			let newMessage = Message()
			newMessage.fromMe = isFromMe == 1 ? true : false
			newMessage.text = text == "" ? nil : text
			
			date = date/1000000000
			newMessage.date = Date(timeIntervalSinceReferenceDate: TimeInterval(date))
			if (newMessage.fromMe) {
				newMessage.sender = me
			} else {
				if let person = handlesDict[handleId]?.person {
					newMessage.sender = person
				} else {
					guard let otherHandleId = try? message.get(otherHandleIdCol) else {
						print("Could not get message's 'other_handle' column, therefore skipping")
						continue
					}
					
					if let person = handlesDict[otherHandleId]?.person {
						newMessage.sender = person
					} else {
						print("No handle for this message. Weird... Handle ID: \(handleId)")
					}
				}
			}
			
			newMessage.chat = chatMessageJoinDict[id]
			
			messagesDict[id] = newMessage

			
			try! realm.write {
				realm.add(newMessage)
			}
		}
		
		
		print("Done!!")
	}
}
