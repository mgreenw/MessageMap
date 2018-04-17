1) Check db exists
2) Query for chats, handles, messages, attachments, attachment_message_joins, chat_message_joins, chat_handle_joins that are not already stored in the database
3) Insert old handles into handlesDict
4) Process new handles, inserting into handlesDict
5) Process new chats, inserting into chatsDict
6) Import old chats into chatsDict
7) Process chat_message_joins using chatsDict, inserting into chatMessageJoinDict
8) Process chat_handle_joins using handlesDict and chatsDict 
9) Insert old attachments into attachmentsDict
10) Process new attachments, inserting into attachments Dict
11) Insert old messages into messagesDict
12) Get old chat lastMessageDates and insert int chatLastMessageDate
13) process new messages, inserting into messagesDict, using handlesDict and chatMessageJoinDict
14) Write new messages to the database
15) Join attachments with messages and write to database using messagesDict, attachmentsDict, and attachmentMessageJoins
16) Fix chat participants by ensuring that all the actual participants AND the ones that were already there are included
17) Merge chat duplicates by finding chats with the same participants and merging them, creating chats with "archived" and "joinedInto"
18) Call newMessagesAdded() on Store