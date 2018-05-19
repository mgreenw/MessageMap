//
//  MGWordListViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 5/14/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa

class MGWordListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var tableView: NSTableView!
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return 0
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return nil
	}
}
