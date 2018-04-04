//
//  AppDelegate.swift
//  MessageMap
//
//  Created by Max Greenwald on 11/12/17.
//  Copyright © 2017 Max Greenwald. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var chatsViewController: ChatsViewController!
	var messagesViewController: MessagesViewController!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		
	}
    
//    func updateData() {
//        // Get all contacts
//        chatsViewController.progress.isHidden = false
//        chatsViewController.progress.startAnimation(nil)
//        DispatchQueue.global(qos: .userInitiated).async {
//            // Do some time consuming task in this background thread
//            // Mobile app will remain to be responsive to user actions
//            
//            print("Performing time consuming task in this background thread")
//            
//            let contactParser = ContactParser()
//            contactParser.parse()
//            
//            // Parse iMessages
//            let messageParser = iMessageParser()
//            messageParser.parse()
//            
//            // Make sure the store is sorted and up to date
//            
//            Store.shared.sortData()
//            
//            DispatchQueue.main.async {
//                // Task consuming task has completed
//                // Update UI from this block of code
//
//                self.chatsViewController.progress.isHidden = true
//                self.chatsViewController.progress.stopAnimation(nil)
//                print("Time consuming task has completed. From here we are allowed to update user interface.")
//                
//                // Refresh the chats table view with the new data
//                self.chatsViewController.tableView.reloadData()
//            }
//        }
//    }
//    
//    private func urlForDataStorage() -> URL? {
//        let fileManager = FileManager.default
//        guard let folder = fileManager.urls(for: .applicationSupportDirectory,
//                                            in: .userDomainMask).first else {
//                                                return nil
//        }
//        let appFolder = folder.appendingPathComponent("MessageMap")
//        var isDirectory: ObjCBool = false
//        let folderExists = fileManager.fileExists(atPath: appFolder.path,
//                                                  isDirectory: &isDirectory)
//        if !folderExists || !isDirectory.boolValue {
//            do {
//                try fileManager.createDirectory(at: appFolder,
//                                                withIntermediateDirectories: true,
//                                                attributes: nil)
//            } catch {
//                return nil
//            }
//        }
//        
//        let dataFileUrl = appFolder.appendingPathComponent("store.mm")
//        return dataFileUrl
//    }
//	
//	func saveStoreToFile() {
//	
//		guard let url = urlForDataStorage() else {
//			print("couldn't save because couldn't get url for data storage" )
//			return
//		}
//		
//		print("Saving to file", url.path)
//		let sharedStore = Store.shared
//		
//		let data = NSKeyedArchiver.archivedData(withRootObject: sharedStore.people[0])
//
//		do {
//			try data.write(to: url)
//		} catch {
//			print("Failed to write store to file")
//		}
//		
////		let encoder = JSONEncoder()
////		if let encoded = try? encoder.encode("Hell yea") {
////			do {
////				try encoded.write(to: url)
////			} catch {
////				print("Failed to write store to file")
////			}
////		}
//		UserDefaults.standard.set(true, forKey: "loadedData")
//		print("Data Saved")
//	}
//	
//	func readStoreFromFile() {
//		guard let url = urlForDataStorage() else {
//			print("couldn't save because couldn't get url for data storage")
//			return
//		}
//		
//		print("reading from file", url)
//		
////		if let data = NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? Store {
////			Store.shared = data
////			print("Successfully read data!")
////		} else {
////			print("Failed to read")
////		}
//		
//		let decoder = JSONDecoder()
//		guard let data = try? Data.init(contentsOf: url) else {
//			print("Could not read file")
//			return
//		}
//		if let decoded = try? decoder.decode(Store.self, from: data) {
//			Store.shared = decoded
//		}
//		UserDefaults.standard.set(true, forKey: "loadedData")
//		print("Data Saved")
//	}
//	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	
}

