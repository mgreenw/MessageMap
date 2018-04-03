//
//  Queries.swift
//  MessageMap
//
//  Created by Max Greenwald on 3/31/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Foundation
import RealmSwift

let realm = try! Realm()

func getMe() -> Person {
	if let me = realm.objects(Person.self).filter("isMe = True").first {
		return me
	} else {
		let me = Person()
		me.isMe = true
		try! realm.write {
			realm.add(me)
		}
		return me
	}
}



