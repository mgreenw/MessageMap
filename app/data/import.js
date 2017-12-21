// Get the path for the iMessage database
const messages_db_path = process.env['HOME'] + "/Library/Messages/chat.db";

const remote = require('electron').remote;
const contactExportPath = remote.getGlobal('resourcesPath') + '/ContactExport';


let db = require('./database');
let t0 = performance.now();
let t1;

let people;
let handles = {}; // map from handle string to person
let handle_ids = {}; // map from handle id to handle string
let chats = {};
let chat_messages = {}; // message_id to chat id in the iMessage database
let messages = [];

let success;
let failure;

// Initialize the iMessage database
let sqlite3 = require('sqlite3').verbose();
let iMessage;
let me;

function ensureImport(successCallback, failCallback) {
    success = successCallback;
    failure = failCallback;
    db.createTables(function (err) {
        if (err) {
            failCallback("Could not create tables" + err + err.stack);
        } else {
            db.getMeta("initial-import-complete", function (err, row) {
                if (err) {
                    console.log('Error getting meta:', err, err.stack);
                    failCallback("Could not get meta" + err + err.stack);
                    return;
                }

                if (row) {
                    if (row.value === "1") {
                        console.log("Data import already complete");
                        success();
                    } else {
                        beginDataImport();
                    }
                } else {
                    console.log("Setting initial-import-complete to 0");
                    db.setMeta("initial-import-complete", "0", function() {
                        beginDataImport();
                    })
                }
            });
        }
    });

}

function beginDataImport() {
    console.log("Data import starting");
    iMessage = new sqlite3.Database(messages_db_path, sqlite3.OPEN_READWRITE, function () {

        // Once the database is open, get all contacts

        // Execute the "ContactExport" executable, which is written in Swift and gathers local MacOS contacts and saves
        // them to ./people.json" in an array
        const exec = require("child_process").exec;
        const child = exec(contactExportPath, (error, stdout, stderr) => {
            // console.log(`stdout: ${stdout}`);
            // console.log(`stderr: ${stderr}`);
            if (error !== null) {
                console.log(`ERROR IN ContactExport proces: exec error: ${error}`);
                console.log("Exiting import process");
                failure(error);
            } else {
                console.log(stdout);
                people = JSON.parse(stdout);
                importMessageData();
            }
        });
    });
}

function importMessageData() {
    // Make object of all handles with reference to the person
    for (let i = 0; i < people.length; i++) {
        let person = people[i];
        if (person.is_me) {
            me = person;
        }

        if (person.last_name.trim() === "") {
            person.last_name = null;
        }
        for (let h = 0; h < person.handles.length; h++) {
            let handle = person.handles[h];
            handles[handle] = person;
        }
    }

    iMessage.serialize(function () {

        iMessage.each("SELECT ROWID as id, id as handle, country FROM handle", function (err, row) {
            let handle = sanitize_handle(row.handle);

            handle_ids[row.id] = handle;

            if (!handles[handle]) {
                let person = {
                    first_name: handle,
                    last_name: null,
                    is_me: false,
                    handles: [handle]
                };
                people.push(person);
                handles[handle] = person;
            }
        }).each("SELECT ROWID as id, display_name, is_archived FROM chat", function (err, row) {
            if (err) {
                console.log("chat err:", err);
            }
            chats[row.id] = {
                display_name: row.display_name,
                is_archived: row.is_archived,
                handles: []
            };
        }).all("SELECT chat_id, message_id FROM chat_message_join", function (err, rows) {
            if (err) {
                console.log("chat message join err:", err);
            }
            rows.forEach(function (row) {
                chat_messages[row.message_id] = row.chat_id;
            });
        }).all("SELECT chat_id, handle_id FROM chat_handle_join", function (err, rows) {
            if (err) {
                console.log("chat hnadle join err:", err);
            }
            rows.forEach(function (row) {
                if (chats[row.chat_id]) {
                    chats[row.chat_id].handles.push(handle_ids[row.handle_id]);
                } else {
                    console.log("No chat for this chat -> handle id");
                }

            });
        }).all("SELECT ROWID as id, text, handle_id, is_from_me, date, other_handle FROM message", function (err, rows) {
            if (err) {
                console.log("message err:", err);
            }
            rows.forEach(function (row) {
                let sender_handle = "";
                if (handle_ids[row.handle_id]) {
                    sender_handle = handle_ids[row.handle_id];
                } else if (handle_ids[row.other_handle]) {
                    sender_handle = handle_ids[row.other_handle];
                } else {
                    sender_handle = "Unknown";
                    console.log("No handle available. Returning...");
                    return;
                }
                let date = row.date / 1000000;


                let referenceDate = new Date('01 January 1 00:00:00 UTC');
                let ourDate = new Date(date);
                let seconds = ourDate.getTime() + referenceDate.getTime();
                let finalDate = new Date(seconds);
                date = finalDate.getTime();

                messages.push({
                    chat_id: chat_messages[row.id],
                    date: date,
                    sender_handle: sender_handle,
                    from_me: row.is_from_me,
                    text: row.text,
                    year: finalDate.getFullYear(),
                    month: finalDate.getMonth(),
                    day_of_week: finalDate.getDay(),
                    hour: finalDate.getHours(),
                    minute: finalDate.getMinutes(),
                    day_of_month: finalDate.getDate()
                });
            });

            iMessage.close();
            insertPeople();
        });

    });
}


function insertPeople() {
    console.log("Insert people");
    db.serialize(function () {
        for (let i = 0; i < people.length; i++) {
            let person = people[i];

            db.insertPerson(person.first_name, person.last_name, person.is_me, function (errs) {
                if (errs !== null) {
                    console.log("Errors");
                }

                person.id = this.lastID;
                for (let h = 0; h < person.handles.length; h++) {
                    let handle = person.handles[h];
                    db.insertHandle(handle, this.lastID, function () {
                        if (h === person.handles.length - 1 && i === people.length - 1) {
                            insertChats();
                        }
                    });

                }
            });
        }

    });
}

function insertChats() {

    db.serialize(function () {
        let chatKeys = Object.keys(chats);

        for (let i = 0; i < chatKeys.length; i++) {
            let chat = chats[chatKeys[i]];

            db.insertChat(chat.is_archived, chat.display_name, function (errs) {
                let chatId = this.lastID;
                chat.real_id = chatId;
                for (let h = 0; h < chat.handles.length; h++) {
                    let person = handles[chat.handles[h]];
                    let personId = person.id;

                    db.insertChatPerson(chatId, personId, function () {
                        if (i === chatKeys.length - 1 && h === chat.handles.length - 1) {
                            insertMessages();
                        }
                    });
                }
            });
        }
    });
}

function insertMessages() {

    console.log("Import messages");

    db.serialize(function () {

        let batchSize = 75;

        for (let i = 0; i < messages.length; i += batchSize) {

            let currBatchSize = Math.min(messages.length - i, batchSize);
            let currSendingSize = 0;
            let messageParams = [];

            for (let m = i; m < i + currBatchSize; m++) {

                let message = messages[m];
                let person = handles[message.sender_handle];
                let senderId = person.id;

                if (chats[message.chat_id]) {
                    let chat = chats[message.chat_id];

                    let chatId = chat.real_id;
                    let currParams = [message.from_me ? me.id : senderId, message.date, message.from_me ? 1 : 0, chatId, message.text, message.year, message.month, message.day_of_week, message.hour, message.minute, message.day_of_month];
                    messageParams.push.apply(messageParams, currParams);
                    currSendingSize += 1;

                } else {
                    console.log("Couldn't get chat...skipping");
                }
            }

            db.insertMessages(messageParams, currSendingSize, function (errs) {
                console.log(i, errs);
                if (i + batchSize >= messages.length) {

                    getChatPeople();
                }
            });
        }
    });

}

function getChatPeople() {

    let chatPeople = [];

    db.selectChats([], function (err, rows) {
        for (let i = 0; i < rows.length; i++) {
            let row = rows[i];
            db.database.all("SELECT person_id FROM chat_people WHERE chat_id = ?", [row.id], function (personErr, personRows) {
                let people = [];
                personRows.forEach(function (person) {
                    people.push(person.person_id);
                });
                chatPeople.push({
                    people: people,
                    chatId: row.id
                });

                if (i === rows.length - 1) {
                    mergeChatPeople(chatPeople);
                }

            });
        }

        console.log("done outer");
    });
}

function mergeChatPeople(chatPeople) {

    let toJoin = {};
    let alreadyMatched = [];
    for (let i = 0; i < chatPeople.length; i++) {
        if (!alreadyMatched.includes(i)) {
            let outerChatElems = chatPeople[i].people.sort().join(',');
            for (let j = i + 1; j < chatPeople.length; j++) {
                let innerChatElems = chatPeople[j].people.sort().join(',');

                if (innerChatElems === outerChatElems) {
                    toJoin[chatPeople[i].chatId] = chatPeople[j].chatId;
                    alreadyMatched.push(chatPeople[j].chatId);
                    break;
                }
            }
        }
    }

    for (let keys = Object.keys(toJoin), i = 0, end = keys.length; i < end; i++) {
        let idToJoinOnto = keys[i], idToJoin = toJoin[idToJoinOnto];
        // do what you need to here, with index i as position information

        db.database.run("UPDATE messages set chat_id = ? WHERE chat_id = ?", [idToJoinOnto, idToJoin], function (err) {
            db.database.run("DELETE FROM chat_people WHERE chat_id = ?", [idToJoin], function (newErr) {
                db.database.run("DELETE FROM chats WHERE id = ?", [idToJoin], function (finalErr) {
                    console.log("ERRORS::::");
                    console.log(err, newErr, finalErr);
                    if (i === end - 1) {
                        finish();
                    }
                })
            });
        });
    }
}

function finish() {
    let t1 = performance.now();
    console.log("Data import took " + (t1 - t0) + " milliseconds.");
    db.setMeta("initial-import-complete", "1", function (err) {
        console.log("Set Initial Import Error: ", err);
        console.log("initial-import-complete flag set. Data import complete.")
        success();
    });
}


function sanitize_handle(handle) {
    if (handle.includes("@")) {
        handle = sanitize_email(handle);
    } else {
        handle = sanitize_phone(handle);
    }
    return handle;
}

function sanitize_email(email) {
    return email.trim();
}

function sanitize_phone(phone) {
    let nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+"];
    let sanitized_phone = "";

    for (let i = 0; i < phone.length; i++) {
        let char = phone.charAt(i);
        if (nums.includes(char)) {
            sanitized_phone += char;
        }
    }

    if (!sanitized_phone.startsWith("+")) {
        sanitized_phone = "+1" + sanitized_phone;
    }
    return sanitized_phone;
}


module.exports = {
    ensureImport: ensureImport,
};
