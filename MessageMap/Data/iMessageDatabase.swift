////
////  iMessageDatabase.swift
////  MessageMap
////
////  Created by Max Greenwald on 4/16/18.
////  Copyright © 2018 Max Greenwald. All rights reserved.
////
//
//import Foundation
//import SQLite
//
//
//// Define generic "ROWID" column
//let idCol = Expression<Int64>("ROWID")
//
//// Define table and columns for "chat" table
//let chatTable = Table("chat")
//let displayNameCol = Expression<String>("display_name")
//let isArchivedCol = Expression<Int64>("is_archived")
//
//// Define table and columns for "handle" table
//let handleTable = Table("handle")
//let handleCol = Expression<String>("id")
//let countryCol = Expression<String>("country")
//
//// Define table and columns for "message" table
//let messageTable = Table("message")
//let textCol = Expression<String>("text")
//let handleIdCol = Expression<Int>("handle_id")
//let isFromMeCol = Expression<Int>("is_from_me")
//let serviceCol = Expression<String>("service")
//let dateCol = Expression<Int>("date")
//let otherHandleIdCol = Expression<Int>("other_handle")
//
//let attachmentTable = Table("attachment")
//let filenameCol = Expression<String>("filename")
//let utiCol = Expression<String>("uti")
//let mimeTypeCol = Expression<String>("mime_type")
//let transferNameCol = Expression<String>("transfer_name")
//
//let attachmentMessageJoinTable = Table("message_attachment_join")
//let attachmentIdCol = Expression<Int>("attachment_id")
//
//// Define table and columns for "chat_message_join" table
//let chatMessageJoinTable = Table("chat_message_join")
//let chatIdCol = Expression<Int>("chat_id")
//let messageIdCol = Expression<Int>("message_id")
//
//// Define table and columns for "chat_handle_join" table
//let chatHandleJoinTable = Table("chat_handle_join")
