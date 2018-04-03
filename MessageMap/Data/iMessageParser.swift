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
import RealmSwift

class iMessageParser {
	let realm = try! Realm()
	
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
	
	

	func parse(completion: @escaping () -> Void) {

		////////////////////////////////////////
		////////// GET THE DATABASE ////////////
		////////////////////////////////////////
		
		
		let iMessageURL = home.appendingPathComponent("/Library/Messages/chat.db")
		
		let openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.canCreateDirectories = false
		openPanel.directoryURL = iMessageURL
		openPanel.allowedFileTypes = ["db"]
		openPanel.allowsOtherFileTypes = false
		openPanel.title = "Allow MessageMap to access your iMessage Chat Database"
		openPanel.prompt = "Allow Access"

		let accessoryVC = OpenDatabaseViewController()
		openPanel.accessoryView = accessoryVC.view
		openPanel.begin{ (result) in
			if result == NSApplication.ModalResponse.OK {
				if let chatDBURL = openPanel.urls.first {
					do {
						let bookmark = try chatDBURL.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
						let userDefaults = UserDefaults.standard
						userDefaults.set(bookmark, forKey: "bookmark")
						print("Security access worked!")
					} catch let error as NSError {
						print("Set Bookmark Fails: \(error.description)")
					}
					
					self.parseDatabase(chatDBURL, completion: completion)
				} else {
					print("Error: user did not select the chat db url")
				}
			} else {
				print("Cancelled Process")
			}
		}
		
	}
		
	func parseDatabase(_ iMessageURL: URL, completion: () -> Void) {
		print(iMessageURL.path)
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
			if let handle = realm.objects(Handle.self).filter("handle = '\(handleName)'" ).first {
				handlesDict[id] = handle.person
				try! realm.write {
					handle.iMessageID.value = id
				}
			} else {
				//If we do not have a person yet for this handle, make one
				let newHandle = Handle()
				newHandle.handle = handleName
				newHandle.iMessageID.value = id

				let newPerson = Person()
				newPerson.firstName = handleName
				newHandle.person = newPerson

				handlesDict[id] = newPerson

				print("Create new person: \(handleName)")

				try! realm.write {
					realm.add(newHandle)
					realm.add(newPerson)
				}
			}
		}

		print("Start chats")

		////// CHATS /////////
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
			newChat.archived = isArchived == 1 ? true : false
			newChat.iMessageID.value = id

			chatsDict[id] = newChat

			try! realm.write {
				realm.add(newChat)
			}
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


			if let chat = chatsDict[chatId] {
				chatMessageJoinDict[messageId] = chat
			} else {
				print("Error: could not find chat in realm with iMessageID \(chatId)")
			}

		}

		print("Start chat handle joins")

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
					try! realm.write {
						chat.participants.append(person)
					}
				} else {
					print("Couldn't find chat with id \(chatId)")
				}
			} else {
				print("Couldn't find person with handle ID \(handleId)")
			}
		}

		print("Parse Messages")

		//////// MESSAGES /////////
		let me = getMe()

		// Bundled write transaction helpers
		var newMessages = [Message]()
		var chatLastMessageDate = [Chat: Date?]()
		
		
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
						sender = Person()
						sender.firstName = "Not sure..."
						print("No handle for this message. Weird... Handle ID: \(handleId)")
					}
				}
			}

			// Weirdly, the iMessage database stores the dates with a
			// multiplier of 1000000000...so we convert here
			date = date/1000000000
			let actualDate = Date(timeIntervalSinceReferenceDate: TimeInterval(date))

			let chat: Chat
			if let potentialChat = chatMessageJoinDict[id] {
				chat = potentialChat
			} else {
				chat = Chat()
				try! realm.write {
					realm.add(chat)
				}
			}

			//let newMessage = Message(sender: sender, chat: chat, date: actualDate, text: text == "" ? nil : text)
			let newMessage = Message()
			newMessage.sender = sender
			newMessage.chat = chat
			
			if !chat.participants.contains(sender) {
				
			}
			
			newMessage.date = actualDate
			newMessage.text = text == "" ? nil : text
			newMessage.iMessageID.value = id

			newMessage.fromMe = isFromMe == 1 ? true : false

			//messagesDict[id] = newMessage
			newMessages.append(newMessage)
			
			// This is a bit awkward, but we need to do this 
			if let lastMessageDate = chatLastMessageDate[chat] {
				if let lastMessageDateSafe = lastMessageDate {
					if actualDate > lastMessageDateSafe {
						chatLastMessageDate[chat] = actualDate
					}
				}
			} else {
				chatLastMessageDate[chat] = actualDate
			}
		}

		try! realm.write {
			for newMessage in newMessages {
				realm.add(newMessage)
			}
			
			for (chat, lastMessageDate) in chatLastMessageDate {
				chat.lastMessageDate = lastMessageDate
			}
		}
		
		fixChatParticipants()
		mergeChatDuplicates()

		// Print the statistics
		print("\n----------------\nDone parsing iMessages!\n")
		print("Messages:", realm.objects(Message.self).count)
		print("People:", realm.objects(Person.self).count)
		print("Chats:", realm.objects(Chat.self).count)
		
		completion()

	}
}

