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

protocol ParserDelegate: AnyObject {
	// Progress updators
	func setShortProgressMessage(to text: String) -> Void
	func setProgressSection(to text: String) -> Void
	func incrementProgress(by amount: Double) -> Void
}

class iMessageParser {
	let realm = try! Realm()
	
	let home = FileManager.default.homeDirectoryForCurrentUser
	let fileManager = FileManager.default

	// Initialize the temporary Chats Dictionary
	var chatsDict = [Int:Chat]() // Maps a chatId to a Chat
	var handlesDict = [Int:Person]() // Maps a handleID to a Person
	var messagesDict = [Int:Message]() // Maps a messageId to a Message
	var chatMessageJoinDict = [Int:Chat]() // Maps a messageId to a Chat
	
	var attachmentsDict = [Int:Attachment]() // Maps an attachmentId to an attachment
	var attachmentMessageJoinDict = [Int:Attachment]() // Maps a messageId to an Attachment

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
	
	let attachmentTable = Table("attachment")
	let filenameCol = Expression<String>("filename")
	let utiCol = Expression<String>("uti")
	let mimeTypeCol = Expression<String>("mime_type")
	let transferNameCol = Expression<String>("transfer_name")

	let attachmentMessageJoinTable = Table("message_attachment_join")
	let attachmentIdCol = Expression<Int>("attachment_id")
	
	// Define table and columns for "chat_message_join" table
	let chatMessageJoinTable = Table("chat_message_join")
	let chatIdCol = Expression<Int>("chat_id")
	let messageIdCol = Expression<Int>("message_id")

	// Define table and columns for "chat_handle_join" table
	let chatHandleJoinTable = Table("chat_handle_join")
	
	weak var delegate: ParserDelegate?
		
	func parseDatabase(_ iMessageURL: URL, completion: () -> Void) {
		print(iMessageURL.path)
		
		delegate?.setProgressSection(to: "Query iMessage Database")
		delegate?.setShortProgressMessage(to: "Ensure database file exists")
		guard fileManager.fileExists(atPath: iMessageURL.path) == true else {
			print("iMessage database cannot be located. Exiting")
			return
		}

		delegate?.setShortProgressMessage(to: "Connect to database")
		guard let db = try? Connection(iMessageURL.path, readonly: true) else {
			print("Failed to connect to iMessage database")
			return
		}
		
		delegate?.incrementProgress(by: 1)
		
		print("Initialized iMesasge database")

		////////////////////////////////////////
		////////// QUERY THE DATABASE //////////
		////////////////////////////////////////
		
		delegate?.setShortProgressMessage(to: "Query for Chats")
		let chatsCount = try! db.scalar(chatTable.count)
		guard let chats = try? db.prepare(chatTable.select(idCol, displayNameCol, isArchivedCol)) else {
			print("Failed to get chats table")
			return
		}

		delegate?.setShortProgressMessage(to: "Query for Handles")
		let handlesCount = try! db.scalar(handleTable.count)
		guard let handles = try? db.prepare(handleTable.select(idCol, handleCol, countryCol)) else {
			print("Failed to get handles table")
			return
		}

		delegate?.setShortProgressMessage(to: "Query for Messages")
		let messagesCount = try! db.scalar(messageTable.count)
		guard let messages = try? db.prepare(messageTable.select(idCol, textCol, handleIdCol, isFromMeCol, dateCol)) else {
			print("Failed to get handles table")
			return
		}
		
		delegate?.setShortProgressMessage(to: "Querying for Attachments")
		let attachmentsCount = try! db.scalar(attachmentTable.count)
		guard let attachments = try? db.prepare(attachmentTable.select(idCol, filenameCol, utiCol, mimeTypeCol, transferNameCol)) else {
			print("Failed to get attachments table")
			return
		}
		
		delegate?.setShortProgressMessage(to: "Querying for Attachment -> Message links")
		let attachmentMessageJoinsCount = try! db.scalar(attachmentMessageJoinTable.count)
		guard let attachmentMessageJoins = try? db.prepare(attachmentMessageJoinTable.select(messageIdCol, attachmentIdCol)) else {
			print("Failed to get message_attachment_join table")
			return
		}

		delegate?.setShortProgressMessage(to: "Query for Chat -> Message links")
		let chatMessageJoinsCount = try! db.scalar(chatMessageJoinTable.count)
		guard let chatMessageJoins = try? db.prepare(chatMessageJoinTable.select(chatIdCol, messageIdCol)) else {
			print("Failed to get chat_message_join table")
			return
		}

		delegate?.setShortProgressMessage(to: "Query for Chat -> Handle links")
		let chatHandleJoinsCount = try! db.scalar(chatHandleJoinTable.count)
		guard let chatHandleJoins = try? db.prepare(chatHandleJoinTable.select(chatIdCol, handleIdCol)) else {
			print("Failed to get chat_handle_join table")
			return
		}
		delegate?.incrementProgress(by: 4)

		////////////////////////////////////////
		//////// MAKE THE DATA OBJECTS /////////
		////////////////////////////////////////

		//////// HANDLES /////////
		
		delegate?.setProgressSection(to: "Process Handles")
		
		var progressCount = 10.0 / Double(handlesCount)
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

				try! realm.write {
					realm.add(newHandle)
					realm.add(newPerson)
				}
			}
			
			delegate?.setShortProgressMessage(to: "Import handle: \(handleName)")
			delegate?.incrementProgress(by: progressCount)
		}

		////// CHATS /////////
		print("Start chats")

		delegate?.setProgressSection(to: "Process Chats")
		progressCount = 5.0 / Double(chatsCount)
		
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
			
			delegate?.setShortProgressMessage(to: "Import chat \(displayName ?? "")")
			delegate?.incrementProgress(by: progressCount)
		}


		//////// CHAT MESSAGE JOINS /////////
		delegate?.setProgressSection(to: "Process Chat Messages")
		progressCount = 10.0 / Double(chatMessageJoinsCount)

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
			
			delegate?.setShortProgressMessage(to: "Join message \(messageId) with chat")
			delegate?.incrementProgress(by: progressCount)
		}

		print("Start chat handle joins")

		//////// CHAT HANDLE JOINS /////////
		delegate?.setProgressSection(to: "Process Chat Participants")
		
		progressCount = 10.0 / Double(chatHandleJoinsCount)
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
			delegate?.setShortProgressMessage(to: "Join handle \(handleId) with chat")
			delegate?.incrementProgress(by: progressCount)
		}
		
		
		//////// ATTACHMENTS ////////
		
		print("Start attachmets")
		
		delegate?.setProgressSection(to: "Process Attachments")
		progressCount = 5.0 / Double(attachmentsCount)
		
		for (index, attachment) in attachments.enumerated() {
			
			guard let id = try? Int(attachment.get(idCol)) else {
				print("Attachment has no ID, therefore skipping.")
				continue
			}
			
			guard let filename = try? attachment.get(filenameCol).trimmingCharacters(in: .whitespacesAndNewlines) else {
				print("Could not get attachment filename, therefore skipping.")
				continue
			}
			
			if filename == "" {
				print("Filename is empty, therefore skipping")
				continue
			}
			
			let uti = try? attachment.get(utiCol)
			let mimeType = try? attachment.get(mimeTypeCol)
			let transferName = try? attachment.get(transferNameCol)
			
			let newAttachment = Attachment()
			newAttachment.iMessageID.value = id
			newAttachment.filename = filename
			newAttachment.uti = uti
			newAttachment.mimeType = mimeType
			newAttachment.transferName = transferName ?? filename.components(separatedBy: "/").last ?? "UnknownFileAttachment"
			
			attachmentsDict[id] = newAttachment
			
			try! realm.write {
				realm.add(newAttachment)
			}
			
			if (index % 10 == 0) {
				delegate?.setShortProgressMessage(to: "Import attachment \(transferName ?? "")")
				delegate?.incrementProgress(by: progressCount * 10)
			}
		}

		print("Parse Messages")

		//////// MESSAGES /////////
		let me = getMe()

		// Bundled write transaction helpers
		var newMessages = [Message]()
		var chatLastMessageDate = [Chat: Date?]()
		delegate?.setProgressSection(to: "Process Messages")
		
		let size = CGSize(width: 250.0, height: 1500.0)
		let messagePaneWidth = 465.0
		let options = NSString.DrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)

		progressCount = (30.0 / Double(messagesCount)) * 10.0
		
		for (index, message) in messages.enumerated() {
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
			newMessage.year = actualDate.year
			newMessage.month = actualDate.month
			newMessage.dayOfMonth = actualDate.day
			newMessage.weekday = actualDate.weekday
			newMessage.hour = actualDate.hour
			newMessage.minute = actualDate.minute
			newMessage.text = text == "" ? nil : text
			newMessage.iMessageID.value = id

			let fromMe = isFromMe == 1 ? true : false
			newMessage.fromMe = fromMe
			
			// Do message layout precalculations
			let estimatedFrame = NSString(string: text ?? "").boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font : NSFont.systemFont(ofSize: 13.0)], context: nil)

			let width = Double(estimatedFrame.width)
			let height = Double(estimatedFrame.height)
			
			newMessage.textFieldWidth = width + 8
			newMessage.textFieldHeight = height + 5
			newMessage.bubbleWidth = width + 18
			newMessage.bubbleHeight = height + 11
			newMessage.layoutHeight = height + 11
			
			if fromMe {
				newMessage.textFieldX = messagePaneWidth - width - 35 + 6
				newMessage.bubbleX = messagePaneWidth - width - 35
			}

			messagesDict[id] = newMessage
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
			
			if index % 10 == 0 {
				delegate?.setShortProgressMessage(to: "Import message \((text ?? "").prefix(10))")
				delegate?.incrementProgress(by: progressCount)
			}
			
		}

		progressCount = 10.0 / Double(messagesCount)
		delegate?.setShortProgressMessage(to: "Write all messages to database")
		try! realm.write {
			
			
			for newMessage in newMessages {
				delegate?.incrementProgress(by: progressCount)
				realm.add(newMessage)
			}
			
			for (chat, lastMessageDate) in chatLastMessageDate {
				chat.lastMessageDate = lastMessageDate
			}
		}
		
		
		//////// ATTACHMENT MESSAGE JOINS /////////
		delegate?.setProgressSection(to: "Process Message Attachments")
		progressCount = 5.0 / Double(attachmentMessageJoinsCount)
		
		try! realm.write {
			
			for attachmentMessageJoin in attachmentMessageJoins {
				guard let attachmentId = try? attachmentMessageJoin.get(attachmentIdCol) else {
					print("Could not get 'message_attachment_join's attachment_id column, therefore skipping")
					continue
				}
				guard let messageId = try? attachmentMessageJoin.get(messageIdCol) else {
					print("Could not get 'message_attachment_join's message_id column, therefore skipping")
					continue
				}
				
				if let attachment = attachmentsDict[attachmentId] {
					if let message = messagesDict[messageId] {
						attachment.message = message
						
						delegate?.setShortProgressMessage(to: "Join message \(messageId) with attachment")
						delegate?.incrementProgress(by: progressCount)
						continue
					}
				}
				
				
				print("Error: could not find attachment in realm with iMessageID \(attachmentId)")

			}
			
		}
		
		// Clean the data
		delegate?.setProgressSection(to: "Cleanup...")
		
		fixChatParticipants()
		mergeChatDuplicates()

		// Print the statistics
		print("\n----------------\nDone parsing iMessages!\n")
		print("Messages:", realm.objects(Message.self).count)
		print("People:", realm.objects(Person.self).count)
		print("Chats:", realm.objects(Chat.self).count)
		
		completion()

	}
	
	func fixChatParticipants() {
		print("Fix Chat Participants")
		delegate?.setShortProgressMessage(to: "Ensure all chat participants are included")
		var toAdd = [Chat: [Person]]()
		
		let chats = realm.objects(Chat.self)
		
		let progressCount = 2.5 / Double(chats.count)
		for chat in chats {
			let potentialParticipants = chat.participantsCalculated + Array(chat.participants)
			toAdd[chat] = potentialParticipants.unique()
			delegate?.incrementProgress(by: progressCount)
		}
		
		try! realm.write {
			for (chat, participants) in toAdd {
				chat.participants.removeAll();
				chat.participants.append(objectsIn: participants)
				delegate?.incrementProgress(by: progressCount)
			}
		}
	}
	
	// Thanks to this answer: https://stackoverflow.com/questions/36714522/how-do-i-check-in-swift-if-two-arrays-contain-the-same-elements-regardless-of-th

	
	func mergeChatDuplicates() {
		delegate?.setShortProgressMessage(to: "Merge Chat Duplicates")
		print("Begin Merging chat duplicates")
		
		let chats = realm.objects(Chat.self)
		let people = realm.objects(Person.self)
		
		var peopleDict = [String: Int]()
		var participantChatsMap = [String: [String]]() // Maps a
		
		for (index, person) in people.enumerated() {
			peopleDict[person.id] = index // Important, need this
		}
		
		var progressCount = 2.5 / Double(chats.count)
		
		for chat in chats {
			// Take an array of integers representing participants in PeopleIDs and turn them into strings like "10-13-40-900", where the ints are sorted
			let participantsString = Array(chat.participants.map { peopleDict[$0.id]! }).sorted().map { String($0) }.joined(separator: "-")
			
			if let _ = participantChatsMap[participantsString] {
				participantChatsMap[participantsString]!.append(chat.id)
			} else {
				participantChatsMap[participantsString] = [chat.id]
			}
			
			delegate?.incrementProgress(by: progressCount)
		}
		
		print("Found duplicate chats, merging...")
		
		
		let chatsToMerge = participantChatsMap.values.filter { $0.count > 1 }
		
		progressCount = 5.0 / Double(chats.count)
		try! realm.write {
			
			for chatIDs in chatsToMerge {
				guard let parentID = chatIDs.first else {
					print("Parent chat ID is nil in merge, skipping")
					continue
				}
				guard let parentChat = realm.objects(Chat.self).filter("id = '\(parentID)'").first else {
					print("Couldn't find parent chat with id \(parentID) in merge, skipping.")
					continue
				}
				
				for childID in chatIDs.dropFirst() {
					guard let childChat = realm.objects(Chat.self).filter("id = '\(childID)'").first else {
						print("Couldn't find child chat with id \(childID) in merge, skipping.")
						continue
					}
					
					for message in childChat.messages {
						message.chat = parentChat
					}
					
					if childChat.lastMessageDateSafe > parentChat.lastMessageDateSafe {
						parentChat.lastMessageDate = childChat.lastMessageDate
					}
					
					childChat.archived = true
					childChat.displayName = "Old, merged into \(parentID)"
				}
			}
		}
		
		delegate?.incrementProgress(by: 5.0)
	}

}

