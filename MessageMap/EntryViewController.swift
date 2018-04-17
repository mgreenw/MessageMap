//
//  EntryViewController.swift
//  MessageMap
//
//  Created by Max Greenwald on 4/3/18.
//  Copyright © 2018 Max Greenwald. All rights reserved.
//

import Cocoa
import Contacts
import RealmSwift

class EntryViewController: NSViewController, ParserDelegate {

	let debug = false // Set this to true to recreate database

	@IBOutlet var progress: NSProgressIndicator!
	@IBOutlet var programDescription: NSTextField!
	@IBOutlet var progressSection: NSTextField!
	@IBOutlet var progressIndividual: NSTextField!
	@IBOutlet var continueButton: NSButton!

	let contactStore = CNContactStore()
	let defaults = UserDefaults.standard
	var databaseURL: URL?

	// Allows us to reuse components for multiple states
	enum EntryState {
		case welcome
		case selectingDatabase
		case promptingContactUsage
		case approvingContactUsage
		case parsingData
		case finishedParsingData
	}

	var state: EntryState!

    override func viewDidLoad() {
        super.viewDidLoad()

		if defaults.bool(forKey: "dataImportComplete") {
			print("Data import is complete, skipping database selecting")
			setState(to: .promptingContactUsage)
//			// Debug -> Reset data
//			if debug {
//				setState(to: .welcome)
//			} else {
//				setState(to: .finishedParsingData)
//			}
		} else {
			setState(to: .welcome)
		}
	}

	// Entry States UI Updates
	
	func setState(to newState: EntryState) {
		switch newState {
		case .welcome:
			DispatchQueue.main.async {
				self.progress.isHidden = true
				self.progress.doubleValue = 0.0
				self.progressSection.isHidden = true
				self.progressIndividual.isHidden = true
				self.continueButton.isEnabled = true
				self.continueButton.title = "Choose Database File"
				self.programDescription.stringValue = "Welcome!  MessageMap uses your Contacts and iMessages stored on your local Mac and aggregates it into a local database for viewing. MessageMap never connects to the Internet and will always ask you before using any of your personal information."
				self.programDescription.isHidden = false
			}
		case .selectingDatabase:
			self.progress.doubleValue = 0.0
		case .promptingContactUsage:
			if CNContactStore.authorizationStatus(for: CNEntityType.contacts) == CNAuthorizationStatus.authorized {
				parseDatabase()
			} else {
				
				DispatchQueue.main.async {
					self.progress.isHidden = true
					self.progress.doubleValue = 0.0
					self.progressSection.isHidden = true
					self.progressIndividual.isHidden = true
					self.continueButton.title = "Allow Contact Access"
					self.continueButton.isEnabled = true
					self.programDescription.stringValue = "MessageMap uses your Contacts to greatly improve your experince! It can, however, function without access to your Contacts - you decide!"
					self.programDescription.isHidden = false
				}
			}
		case .approvingContactUsage:
			self.progress.doubleValue = 0.0
		case .parsingData:
			DispatchQueue.main.async {
				self.progress.isHidden = false
				self.progress.doubleValue = 0.0
				self.progressSection.isHidden = false
				self.progressIndividual.isHidden = false
				self.continueButton.title = "Go to MessageMap"
				self.continueButton.isEnabled = false
				self.programDescription.stringValue = ""
				self.programDescription.isHidden = true
			}
		case .finishedParsingData:
			// Debug:
			switchToMainWindow()
			
			DispatchQueue.main.async {
				self.progress.isHidden = true
				self.progressSection.isHidden = true
				self.progressIndividual.isHidden = true
				self.continueButton.title = "Go to MessageMap"
				self.continueButton.isEnabled = true
				self.programDescription.stringValue = "Your Message history has been imported!"
				self.programDescription.isHidden = false
			}
		default:
			print("No state set, so setting to welcome state")
			setState(to: .welcome)
		}
		
		state = newState
	}

	// Continue Button Decision Making

	@IBAction func continueButtonPressed(sender: NSButton) {
		switch state {
		case .welcome:
			selectDatabase()
		case .promptingContactUsage:
			askToUseContacts {
				self.parseDatabase()
			}
		case .finishedParsingData:
			switchToMainWindow()
		default:
			print("Button should not be pressable at this time.")
		}

	}

	// Main Actions

	func selectDatabase() {
		setState(to: .selectingDatabase)
		
		if let _ = defaults.url(forKey: "iMessageURL") {
			setState(to: .promptingContactUsage)
			return
		}
		
		
		print("Choose database File")

		let home = FileManager.default.homeDirectoryForCurrentUser
		let iMessageURL = home.appendingPathComponent("Library/Messages/chat.db")

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
		openPanel.message = "The default iMessage database path on your Mac is \(iMessageURL.path).\n Choose either this database or a database from an iPhone's backup."

		openPanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) in
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

					self.databaseURL = chatDBURL
					self.setState(to: .promptingContactUsage)

				} else {
					self.setState(to: .welcome)
					print("Error: user did not select the chat db url")
				}
			} else {
				self.setState(to: .welcome)
				print("Cancelled Database selection Process")
			}
		})
	}

	func askToUseContacts(completion: @escaping () -> Void) {
		setState(to: .approvingContactUsage)

		contactStore.requestAccess(for: CNEntityType.contacts) { (isGranted, error) in

			if !isGranted {
				// Handle the error
				print("Denied access to contacts")

				// Store the denial in UserDefaults Todo
			}

			// Use the contacts!
			completion()
		}

	}

	// ParserDelegate
	func setShortProgressMessage(to text: String) {
		DispatchQueue.main.async {
			self.progressIndividual.stringValue = text
		}
	}
	func setProgressSection(to text: String) {
		DispatchQueue.main.async {
			self.progressSection.stringValue = text
		}
	}
	func incrementProgress(by amount: Double) {
		DispatchQueue.main.async {
			self.progress.increment(by: amount)
		}
	}

	func setProgress(to amount: Double) {
		DispatchQueue.main.async {
			print("Set to: \(amount)")
			self.progress.doubleValue = amount
		}
	}

	// Progress Updators
	func parseDatabase() {

		var newURL: URL? = self.databaseURL
		if let storedURL = defaults.url(forKey: "iMessageURL") {
			if let newURLSafe = newURL {
				if newURLSafe != storedURL {
					// Prompt the user to choose which database to use
				}
			} else {
				newURL = storedURL
			}
		}

		// Ensure the database url is set
		guard let url = newURL else {
			print("No database URL set, resetting...")

			// If it is not set, go back to the welcome state
			setState(to: .welcome)
			return
		}
		
		defaults.set(newURL, forKey: "iMessageURL")

		// Unhide progress elements
		setState(to: .parsingData)

		print("Before contact")

		DispatchQueue.global(qos: .userInitiated).async {
			let contactParser = ContactParser()
			contactParser.delegate = self
			contactParser.parse()
			print("After Contact")

			let messageParser = iMessageParser()
			messageParser.delegate = self
			messageParser.parseDatabase(url, completion: {
				print("After Message")

				let defaults = UserDefaults.standard
				defaults.set(true, forKey: "dataImportComplete")

				self.switchToMainWindow()
			})
		}
	}

	func switchToMainWindow() {

		// Open the main MessageMap Window
		DispatchQueue.main.async {
			let mainWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "main")) as! NSWindowController
			mainWindowController.showWindow(self)

			// Close the Welcome window
			self.view.window?.close()
		}
	}

}
