//
//  iMessageParser.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import SQLite
//import RealmSwift
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
//		let realm = try! Realm()
//
//		try! realm.write {
//			realm.deleteAll()
//		}
		
//		print("Realm Path : \(realm.configuration.fileURL?.absoluteURL)")
		
		let delegate = NSApplication.shared.delegate as! AppDelegate
		
		
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
		
		let me: Person
		
		if let meContact = try? store.unifiedMeContactWithKeys(toFetch: keysToFetch) {
			me = Person(firstName: meContact.givenName, lastName: meContact.familyName)
			me.isMe = true
			
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
			me = Person(firstName: "My", lastName: "Self")
		}
		
		Store.shared.me = me
		
		try? store.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact: CNContact, bool) in
			
			let newPerson = Person(firstName: contact.givenName, lastName: contact.familyName)
			
			let emailAddresses = contact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = contact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			
			for email in emailAddresses {
				personDict[email] = newPerson
			}
			
			for phone in phoneNumbers {
				personDict[phone] = newPerson
			}
			
			Store.shared.people.append(newPerson)
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
		
		#if DEBUG
			db.trace { print($0) }
		#endif

		print("Initialized iMesasge database")

		guard let chats = try? db.prepare(chatTable.select(idCol, displayNameCol, isArchivedCol)) else {
			print("Failed to get chats table")
			return
		}
		
		guard let handles = try? db.prepare(handleTable.select(idCol, handleCol, countryCol)) else {
			print("Failed to get handles table")
			return
		}
		
		guard let messages = try? db.prepare(messageTable.select(idCol, textCol, handleIdCol, isFromMeCol, dateCol)) else {
			print("Failed to get handles table")
			return
		}
		
		guard let chatMessageJoins = try? db.prepare(chatMessageJoinTable.select(chatIdCol, messageIdCol)) else {
			print("Failed to get chat_message_join table")
			return
		}
		
		guard let chatHandleJoins = try? db.prepare(chatHandleJoinTable.select(chatIdCol, handleIdCol)) else {
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
			
			if handleName.contains("@") {
				handleName = sanitizeEmail(handleName)
			} else {
				handleName = sanitizePhone(handleName)
			}
			
			let person: Person
			
			if let p = personDict[handleName] {
				person = p
			} else {
				
				// If we do not have a person yet for this handle, make one
				let newPerson = Person(firstName: handleName, lastName: nil)
				personDict[handleName] = newPerson
				person = newPerson
				Store.shared.people.append(newPerson)
			}
			
			let newHandle = Handle(person: person, handle: handleName, country: country)
			handlesDict[id] = newHandle
			Store.shared.handles.append(newHandle)
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
			
			let newChat = Chat(displayName: displayName)
			newChat.isArchived = isArchived == 1 ? true : false
			
			chatsDict[id] = newChat
			Store.shared.chats.append(newChat)
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
					chat.add(person: person)
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
			
			let sender: Person
			
			if (isFromMe == 1) {
				sender = me
			} else {
				if let person = handlesDict[handleId]?.person {
					sender = person
				} else {
					guard let otherHandleId = try? message.get(otherHandleIdCol) else {
						print("Could not get message's 'other_handle' column, therefore skipping")
						continue
					}
					
					if let person = handlesDict[otherHandleId]?.person {
						sender = person
					} else {
						sender = Person(firstName: "Not Sure...", lastName: nil)
						print("No handle for this message. Weird... Handle ID: \(handleId)")
					}
				}
			}
			
			date = date/1000000000
			let actualDate = Date(timeIntervalSinceReferenceDate: TimeInterval(date))
			
			let chat = chatMessageJoinDict[id] ?? Chat(displayName: "Unknown Chat")
			

			let newMessage = Message(sender: sender, chat: chat, date: actualDate, text: text == "" ? nil : text)
			newMessage.fromMe = isFromMe == 1 ? true : false
	
			messagesDict[id] = newMessage
			chat.add(message: newMessage)
			sender.add(message: newMessage)
			Store.shared.messages.append(newMessage)
		}
		
		
		print("Done!!")
		print("Messages:")
		print(Store.shared.messages.count)
		print("People:")
		print(Store.shared.people.count)
		print("Chats:")
		print(Store.shared.chats.count)
		Store.shared.sortData()

		delegate.chatsViewController.tableView.reloadData()
	}
}
