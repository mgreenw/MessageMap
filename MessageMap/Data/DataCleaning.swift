//
//  DataCleaning.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/26/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift


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


extension Array where Element:Person {
	func unique() -> [Person] {
		
		// Great solution from here https://stackoverflow.com/questions/27624331/unique-values-of-array-in-swift
		var seen: [String: Bool] = [:]
		return self.filter { seen.updateValue(true, forKey: $0.id) == nil }
	}
}

func fixChatParticipants() {
	print("Fix Chat Participants")
	var toAdd = [Chat: [Person]]()
	
	for chat in realm.objects(Chat.self) {
		let potentialParticipants = chat.participantsCalculated + Array(chat.participants)
		toAdd[chat] = potentialParticipants.unique()
	}
	
	try! realm.write {
		for (chat, participants) in toAdd {
			chat.participants.removeAll();
			chat.participants.append(objectsIn: participants)
		}
	}
}

// Thanks to this answer: https://stackoverflow.com/questions/36714522/how-do-i-check-in-swift-if-two-arrays-contain-the-same-elements-regardless-of-th
extension Array where Element: Comparable {
	func containsSameElements(as other: [Element]) -> Bool {
		return self.count == other.count && self.sorted() == other.sorted()
	}
}

func mergeChatDuplicates() {
	print("Begin Merging chat duplicates")
	
	let chats = realm.objects(Chat.self)
	let people = realm.objects(Person.self)
	
	var peopleDict = [String: Int]()
	var participantChatsMap = [String: [String]]() // Maps a
	
	for (index, person) in people.enumerated() {
		peopleDict[person.id] = index // Important, need this
	}
	
	for chat in chats {
		// Take an array of integers representing participants in PeopleIDs and turn them into strings like "10-13-40-900", where the ints are sorted
		let participantsString = Array(chat.participants.map { peopleDict[$0.id]! }).sorted().map { String($0) }.joined(separator: "-")
		
		if let _ = participantChatsMap[participantsString] {
			participantChatsMap[participantsString]!.append(chat.id)
		} else {
			participantChatsMap[participantsString] = [chat.id]
		}
	}
	
	print("Found duplicate chats, merging...")

	
	let chatsToMerge = participantChatsMap.values.filter { $0.count > 1 }
	
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
}
