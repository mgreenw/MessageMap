//
//  ContactParser.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/26/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import Contacts
import RealmSwift

class ContactParser {
	let contactStore = CNContactStore()
	let contactKeys = [CNContactGivenNameKey, CNContactFamilyNameKey,
					   CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactIdentifierKey, CNContactThumbnailImageDataKey]

	weak var delegate: ParserDelegate?
	let realm = try! Realm()
	
	struct PersonToUpdate {
		var person: Person
		var firstName: String?
		var lastName: String?
		var identifier: String
		var photo: Data?
		var isMe: Bool
		var alreadyInDatabase: Bool
	}
	
	struct HandleToUpdate {
		var handle: Handle
		var person: Person
		var handleString: String
		var alreadyInDatabase: Bool
	}

	func parse() {
		var peopleToUpdate = [PersonToUpdate]()
		var handlesToUpdate = [HandleToUpdate]()

		delegate?.setProgressSection(to: "Import Contacts")
		delegate?.setShortProgressMessage(to: "Import 'me' contact")

		let keysToFetch = contactKeys.map {$0 as CNKeyDescriptor}
		realm.refresh()
		var alreadyInDatabase = false
		let me: Person
		if let meSafe = realm.objects(Person.self).filter("isMe = 1").first {
			me = meSafe
			alreadyInDatabase = true
		} else {
			me = Person()
		}
		
		var meIdentifier = me.contactID ?? ""
		
		if let meContact = try? contactStore.unifiedMeContactWithKeys(toFetch: keysToFetch) {

			meIdentifier = meContact.identifier
			
			let firstName = meContact.givenName != "" ? meContact.givenName : nil
			let lastName = meContact.familyName != "" ? meContact.familyName : nil

			let emailAddresses = meContact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = meContact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			let combinedHandles = emailAddresses + phoneNumbers
			
			let update = PersonToUpdate(person: me, firstName: firstName, lastName: lastName, identifier: meContact.identifier, photo: meContact.thumbnailImageData, isMe: true, alreadyInDatabase: alreadyInDatabase)
			peopleToUpdate.append(update)

			for handleStr in combinedHandles {
				let update: HandleToUpdate
				if let handle = realm.objects(Handle.self).filter("handle = '\(handleStr)'").first {
					update = HandleToUpdate(handle: handle, person: me, handleString: handleStr, alreadyInDatabase: true)
				} else {
					update = HandleToUpdate(handle: Handle(), person: me, handleString: handleStr, alreadyInDatabase: false)
				}
				handlesToUpdate.append(update)
			}
		}
		
		delegate?.incrementProgress(by: 1)

		try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact: CNContact, bool) in

			// Ensure that we do not add the "me" contact twice by accident
			if contact.identifier == meIdentifier {
				return
			}
			
			let person: Person

			var alreadyInDatabase = false
			if let potentialPerson = self.realm.objects(Person.self).filter(NSPredicate(format: "firstName = %@ AND lastName = %@", contact.givenName, contact.familyName)).first {
				person = potentialPerson
				alreadyInDatabase = true
			} else {
				person = Person()
			}

			self.delegate?.setShortProgressMessage(to: "Importing \(contact.givenName) \(contact.familyName)")

			let emailAddresses = contact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = contact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			let combinedHandles = emailAddresses + phoneNumbers
			
			let update = PersonToUpdate(person: person, firstName: contact.givenName, lastName: contact.familyName, identifier: contact.identifier, photo: contact.thumbnailImageData, isMe: false, alreadyInDatabase: alreadyInDatabase)
			peopleToUpdate.append(update)
			
			for handleStr in combinedHandles {
				let update: HandleToUpdate
				if let handle = self.realm.objects(Handle.self).filter("handle = '\(handleStr)'").first {
					update = HandleToUpdate(handle: handle, person: person, handleString: handleStr, alreadyInDatabase: true)
				} else {
					update = HandleToUpdate(handle: Handle(), person: person, handleString: handleStr, alreadyInDatabase: false)
				}
				handlesToUpdate.append(update)
			}

		}
		
		try! realm.write {
			for personToUpdate in peopleToUpdate {
				let person = personToUpdate.person
				person.firstName = personToUpdate.firstName
				person.lastName = personToUpdate.lastName
				person.contactID = personToUpdate.identifier
				person.photo = personToUpdate.photo
				person.isMe = personToUpdate.isMe
				
				if !personToUpdate.alreadyInDatabase {
					realm.add(person)
				}
			}
			
			for handleToUpdate in handlesToUpdate {
				let handle = handleToUpdate.handle
				handle.handle = handleToUpdate.handleString
				handle.person = handleToUpdate.person
				if !handleToUpdate.alreadyInDatabase {
					realm.add(handle)
				}
			}
		}
		
		

		delegate?.incrementProgress(by: 9)
	}
}
