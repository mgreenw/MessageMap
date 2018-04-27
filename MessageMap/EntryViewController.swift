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

    // MARK: Class Properties
    
    // Describes MessageMap and how it will access user data
    @IBOutlet var programDescription: NSTextField!
    
    // Indicates progress of database update
	@IBOutlet var progress: NSProgressIndicator!
    
    // Shows the section header of the current progress
	@IBOutlet var progressSection: NSTextField!
    
     // Shows the individual task of the current progress
	@IBOutlet var progressIndividual: NSTextField!
    
    // Allows the user to "continue" to the next step of entry
	@IBOutlet var continueButton: NSButton!
    
    // Stores the iMessage Database URL that will be used
    private var databaseURL: URL?
    
    // A representation of the current state of the EntryViewController
    public enum State {
        case welcome
        case selectingDatabase
        case promptingContactUsage
        case approvingContactUsage
        case parsingData
        case finishedParsingData
    }
    
    // The current State (must be initialized in viewDidLoad)
    public var state: State!

    // MARK: Class Activities
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // If the data import is complete, immediatly start data update
		if UserDefaults.standard.bool(forKey: "dataImportComplete") {
			print("Initial Data Import is complete")
            
            // TODO: Change to promptingContactUsage for production
			setState(to: .finishedParsingData)
            
        // If the data import is not complete, welcome the user to the app and begin the data import process
		} else {
			setState(to: .welcome)
		}
	}

    // Set the state and complete the necessary UI changes for that state
	func setState(to newState: State) {
        
        // Set the newState
        state = newState
        
        // Exhaustive switch over newState to complete the UI update
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
			switchToMainWindow()
        }
	}

	// Complete the "continue" action based on the current state
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
			print("Continue button should not be accessible in this state")
		}

	}

    // MARK: State Actions
	func selectDatabase() {
        
        // Set the state to reflect the current action
		setState(to: .selectingDatabase)
		
        // Check if the user has already selected an iMessage Database URL
        // If they have, go right to the contact usage prompt
		if let _ = UserDefaults.standard.url(forKey: "iMessageURL") {
			setState(to: .promptingContactUsage)
			return
		}
		
        // Get the default URL for the iMessage Database
		let home = FileManager.default.homeDirectoryForCurrentUser
		let iMessageURL = home.appendingPathComponent("Library/Messages/chat.db")

        // Craft the NSOpenPanel to select the iMessage Database
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

        // Show the open panel
		openPanel.beginSheetModal(for: self.view.window!, completionHandler: { (result) in
            
            // Ensure the user selected the "Allow Acess" Button
			if result != NSApplication.ModalResponse.OK {
                print("Error: User cancelled the 'Select Database' Process")
                self.setState(to: .welcome)
                return
            }
            
            // Ensure the user selected a database file
            guard let chatDBURL = openPanel.urls.first else {
                print("Error: User did not select a file")
                self.setState(to: .welcome)
                return
            }
            
            // Set a bookmark for this url to be used in subsequent opens
            do {
                let bookmark = try chatDBURL.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch let error as NSError {
                print("Set Bookmark failed: \(error.description)")
            }

            // Set the database URL and continue with database parsing
            self.databaseURL = chatDBURL
            self.setState(to: .promptingContactUsage)
		})
	}

    // Ask the users if they would like to allow usage of their contacts
    // This will display the system "Allow Contact Usage" prompt
    // When done, complete the "Completion" action
	func askToUseContacts(completion: @escaping () -> Void) {
        
        // Set the state to reflect the current action
		setState(to: .approvingContactUsage)
        
        // Initialize the Store, which will immediatly ask for contact usage
        let contactStore = CNContactStore()
		contactStore.requestAccess(for: CNEntityType.contacts) { (isGranted, error) in

			if !isGranted {
				print("Cannot access contacts")
                // TODO: Store the denial in UserDefaults Todo
                // TODO: Display failure te user, and ask them to reconsider
			}

			// Complete the next action, regardless of success or failure
			completion()
		}
	}

    // Parse the database. Use either the database URL stored in UserDefaults or the database URL found by asking the user
	func parseDatabase() {

        // Check if there is a 'stored' URL in UserDefaults.
        // If there is, check if it is different then the one the user selected
		var databaseURL: URL? = self.databaseURL
		if let storedURL = UserDefaults.standard.url(forKey: "iMessageURL") {
			if let newURLSafe = databaseURL  {
                // If the user DID select a database file, compare the stored URL to the new URL
				if newURLSafe != storedURL {
                    // TODO: Prompt the user to choose which database to use
				}
			} else {
                
                // If the user DID NOT not select a database file, use the 'storedURL', which could be nil
				databaseURL = storedURL
			}
		}

		// Ensure the database url is set, else return to the welcome state
		guard let url = databaseURL else {
			setState(to: .welcome)
			return
		}
		
        // Set the 'stored' URL to be the URL we have chosen
		UserDefaults.standard.set(databaseURL, forKey: "iMessageURL")

        // Begin parsing data and set the UI Elements accordingly
		setState(to: .parsingData)

        // Use the async queue to allow the UI to continue to update
		DispatchQueue.global(qos: .userInitiated).async {
            
            // Parse the user's contacts
			let contactParser = ContactParser()
			contactParser.delegate = self
			contactParser.parse()

            // Parse the user's iMessages
			let messageParser = iMessageParser()
			messageParser.delegate = self
			messageParser.parseDatabase(url, completion: {
                
                // Save the fact that the data has been imported
                UserDefaults.standard.set(true, forKey: "dataImportComplete")
                
                // Switch to the main MessageMap window
				self.switchToMainWindow()
			})
		}
	}

	func switchToMainWindow() {

		// Open the main MessageMap Window
		DispatchQueue.main.async {
            
            // Instantiate a new 'main' window from the storyboard
            // and show the 'main' window
			let mainWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "main")) as! NSWindowController
			mainWindowController.showWindow(self)

			// Close the Entry window
			self.view.window?.close()
		}
	}
    
    // MARK: ParserDelegate
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

}
