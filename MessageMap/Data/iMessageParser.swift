//
//  iMessageParser.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/16/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa
import Contacts
import SQLite

class iMessageParser {
	let home = FileManager.default.homeDirectoryForCurrentUser
	let fileManager = FileManager.default

	// Initialize the temporary Chats Dictionary
	var chatsDict = [Int:Chat]() // Maps a chatId to a Chat
	var handlesDict = [Int:Person]() // Maps a handleID to a Person
	var messagesDict = [Int:Message]() // Maps a messageId to a Message
	var chatMessageJoinDict = [Int:Chat]() // Maps a messageId to a Chat
	
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
	
	func parse() {

		////////////////////////////////////////
		////////// GET THE DATABASE ////////////
		////////////////////////////////////////
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

		////////////////////////////////////////
		////////// QUERY THE DATABASE //////////
		////////////////////////////////////////
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
		
		////////////////////////////////////////
		//////// MAKE THE DATA OBJECTS /////////
		////////////////////////////////////////
		
		//////// HANDLES /////////
		for handle in handles {
			guard let id = try? Int(handle.get(idCol)) else {
				print("Handle has no ROWID, therefore skipping.")
				continue
			}
			guard var handleName = try? handle.get(handleCol) else {
				print("Could not get handle's 'id' column, therefore skipping")
				continue
			}
			guard let _ = try? handle.get(countryCol) else {
				print("Could not get handle's 'country' column, therefore skipping")
				continue
			}
			
			// Sanitize the handle name, either an email or a phone number
			if handleName.contains("@") {
				handleName = sanitizeEmail(handleName)
			} else {
				handleName = sanitizePhone(handleName)
			}
			
			// If the person already exists, then set our person to be that one
			if let person = Store.shared.handles[handleName] {
				handlesDict[id] = person
			// If a person does not exist for that handle, 
			} else {
				
				// If we do not have a person yet for this handle, make one
				let newPerson = Person(firstName: handleName, lastName: nil)
				Store.shared.add(person: newPerson)
				Store.shared.add(handleName: handleName, person: newPerson)
				handlesDict[id] = newPerson
			}
		}

		//////// CHATS /////////
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
			Store.shared.add(chat: newChat)
		}
		
		//////// CHAT MESSAGE JOINS /////////
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
		
		//////// CHAT HANDLE JOINS /////////
		for chatHandleJoin in chatHandleJoins {
			guard let chatId = try? chatHandleJoin.get(chatIdCol) else {
				print("Could not get 'chat_handle_join's chat_id column, therefore skipping")
				continue
			}
			guard let handleId = try? chatHandleJoin.get(handleIdCol) else {
				print("Could not get 'chat_handle_join's message_id column, therefore skipping")
				continue
			}
			
			if let person = handlesDict[handleId] {
				if let chat = chatsDict[chatId] {
					chat.add(person: person)
				} else {
					print("Couldn't find chat with id \(chatId)")
				}
			} else {
				print("Couldn't find person with handle ID \(handleId)")
			}
		}
		
		//////// MESSAGES /////////
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
				sender = Store.shared.me
			} else {
				if let person = handlesDict[handleId] {
					sender = person
				} else {
					guard let otherHandleId = try? message.get(otherHandleIdCol) else {
						//print("Could not get message's 'other_handle' column, therefore skipping")
						continue
					}
					
					if let person = handlesDict[otherHandleId] {
						sender = person
					} else {
						sender = Person(firstName: "Not Sure...", lastName: nil)
						print("No handle for this message. Weird... Handle ID: \(handleId)")
					}
				}
			}
			
			// Weirdly, the iMessage database stores the dates with a
			// multiplier of 1000000000...so we convert here
			date = date/1000000000
			let actualDate = Date(timeIntervalSinceReferenceDate: TimeInterval(date))
			
			let chat = chatMessageJoinDict[id] ?? Chat(displayName: "Unknown Chat")

			let newMessage = Message(sender: sender, chat: chat, date: actualDate, text: text == "" ? nil : text)
			newMessage.fromMe = isFromMe == 1 ? true : false
	
			messagesDict[id] = newMessage
			chat.add(message: newMessage)
			sender.add(message: newMessage)
			Store.shared.add(message: newMessage)
		}
		
		// Print the statistics
		print("\n----------------\nDone parsing iMessages!\n")
		print("Messages:", Store.shared.messages.count)
		print("People:", Store.shared.people.count)
		print("Chats:", Store.shared.chats.count)
	}
}
