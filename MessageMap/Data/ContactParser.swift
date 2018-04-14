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

	func parse() {

		delegate?.setProgressSection(to: "Import Contacts")
		delegate?.setShortProgressMessage(to: "Import 'me' contact")

		let realm = try! Realm()
		let keysToFetch = contactKeys.map {$0 as CNKeyDescriptor}

		if let meContact = try? contactStore.unifiedMeContactWithKeys(toFetch: keysToFetch) {

			let me = getMe()

			try! realm.write {
				me.firstName = meContact.givenName != "" ? meContact.givenName : nil
				me.lastName = meContact.familyName != "" ? meContact.familyName : nil
				me.contactID = meContact.identifier
				me.photo = meContact.thumbnailImageData
			}

			let emailAddresses = meContact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = meContact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}

			let combinedHandles = emailAddresses + phoneNumbers

			for handleStr in combinedHandles {
				if let handle = realm.objects(Handle.self).filter("handle = '\(handleStr)'").first {
					handle.person = me
				} else {
					let handle = Handle()
					handle.handle = handleStr
					handle.person = me
					try! realm.write {
						realm.add(handle)
					}
				}
			}
		}

		delegate?.incrementProgress(by: 1)

		try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact: CNContact, bool) in

			let person: Person

			if let potentialPerson = realm.objects(Person.self).filter(NSPredicate(format: "firstName = %@ AND lastName = %@", contact.givenName, contact.familyName)).first {
				person = potentialPerson
			} else {
				person = Person()
				person.isMe = false

				try! realm.write {
					realm.add(person)
				}
			}

			self.delegate?.setShortProgressMessage(to: "Importing \(contact.givenName) \(contact.familyName)")

			try! realm.write {
				person.firstName = contact.givenName
				person.lastName = contact.familyName
				person.contactID = contact.identifier
				person.photo = contact.thumbnailImageData
			}
			let emailAddresses = contact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = contact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}

			let combinedHandles = emailAddresses + phoneNumbers

			for handleStr in combinedHandles {
				if let handle = realm.objects(Handle.self).filter("handle = '\(handleStr)'").first {
					try! realm.write {
						handle.person = person
					}
				} else {
					let handle = Handle()
					handle.handle = handleStr
					handle.person = person
					try! realm.write {
						realm.add(handle)
					}
				}
			}

		}

		delegate?.incrementProgress(by: 9)
	}
}
