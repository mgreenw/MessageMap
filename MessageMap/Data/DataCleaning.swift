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
