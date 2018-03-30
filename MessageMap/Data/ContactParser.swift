//
//  ContactParser.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/26/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Foundation
import Contacts

class ContactParser {
	let contactStore = CNContactStore()
	let contactKeys = [CNContactGivenNameKey, CNContactFamilyNameKey,
					   CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
	
	func parse() {
		let keysToFetch = contactKeys.map {$0 as CNKeyDescriptor}

		if let meContact = try? contactStore.unifiedMeContactWithKeys(toFetch: keysToFetch) {
			
			let me: Person
			
			me = Store.shared.me
			me.firstName = meContact.givenName != "" ? meContact.givenName : nil
			me.lastName = meContact.familyName != "" ? meContact.familyName : nil
			
			let emailAddresses = meContact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = meContact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			
			for email in emailAddresses {
				Store.shared.handles[email] = me
			}
			
			for phone in phoneNumbers {
				Store.shared.handles[phone] = me
			}
			
			Store.shared.me = me
			
		}
		
		try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact: CNContact, bool) in
			
			let newPerson = Person(firstName: contact.givenName, lastName: contact.familyName)
			
			let emailAddresses = contact.emailAddresses.map {sanitizeEmail(String($0.value))}
			let phoneNumbers = contact.phoneNumbers.map {sanitizePhone($0.value.stringValue)}
			
			for email in emailAddresses {
				Store.shared.handles[email] = newPerson
			}
			
			for phone in phoneNumbers {
				Store.shared.handles[phone] = newPerson
			}
			
			Store.shared.people.append(newPerson)
		}
	}
}
