const remote = require('electron').remote;

// Initialize our local messagemap database
let sqlite3 = require('sqlite3').verbose();
const url = remote.getGlobal('dataPath') + '/messagemap.db';


const createStatement = "CREATE TABLE IF NOT EXISTS attachments\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    message_id INTEGER NOT NULL,\n" +
    "    path TEXT NOT NULL,\n" +
    "    CONSTRAINT attachments_messages_id_fk FOREIGN KEY (message_id) REFERENCES messages (id)\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS chat_people\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    chat_id INTEGER NOT NULL,\n" +
    "    person_id INTEGER NOT NULL,\n" +
    "    CONSTRAINT chat_people_chats_id_fk FOREIGN KEY (chat_id) REFERENCES chats (id),\n" +
    "    CONSTRAINT chat_people_people_id_fk FOREIGN KEY (person_id) REFERENCES people (id)\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS chats\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    archived BOOLEAN NOT NULL,\n" +
    "    display_name TEXT\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS handles\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    handle TEXT NOT NULL,\n" +
    "    person_id INTEGER NOT NULL,\n" +
    "    CONSTRAINT handles_people_id_fk FOREIGN KEY (handle) REFERENCES people (id)\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS messages\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    sender_id INTEGER NOT NULL,\n" +
    "    date INTEGER NOT NULL,\n" +
    "    from_me BOOLEAN NOT NULL,\n" +
    "    chat_id INTEGER NOT NULL,\n" +
    "    text TEXT,\n" +
    "    year INTEGER NOT NULL,\n" +
    "    month INTEGER NOT NULL,\n" +
    "    day_of_week INTEGER NOT NULL,\n" +
    "    hour INTEGER NOT NULL,\n" +
    "    minute INTEGER NOT NULL,\n" +
    "    day_of_month INTEGER DEFAULT 0 NOT NULL,\n" +
    "    CONSTRAINT messages_people_id_fk FOREIGN KEY (sender_id) REFERENCES people (id),\n" +
    "    CONSTRAINT messages_chats_id_fk FOREIGN KEY (chat_id) REFERENCES chats (id)\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS meta\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    key TEXT NOT NULL,\n" +
    "    value TEXT NOT NULL\n" +
    ");\n" +
    "CREATE TABLE IF NOT EXISTS people\n" +
    "(\n" +
    "    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n" +
    "    first_name TEXT NOT NULL,\n" +
    "    last_name TEXT,\n" +
    "    is_me BOOLEAN DEFAULT FALSE NOT NULL\n" +
    ");";

let defaultMode = sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE;
let db = new sqlite3.Database(url, defaultMode, function (err) {
    if (err) {
        console.log('Error opening database:', err, err.stack);
        return;
    }
    console.log('Database was opened successfully');
    createTables(emptyFunction);
});


function createTables(callback) {
    db.exec(createStatement, function (err) {
        if (err) {
            console.log('Error creating database tables:', err, err.stack);
            return;
        }
        console.log("Successfully created all database tables");
        callback(err);
    });
}

const emptyFunction = function () {
};

db.on('trace', function (sql) {
    //console.log(sql);
});

////////////////////////////
//////// META ///////////
////////////////////////////

function serialize(callback) {
    db.serialize(callback);
}

function parallelize(callback) {
    db.parallelize(callback);
}

function getMeta(key, callback) {
    db.get("SELECT value from meta WHERE key = ?", [key], callback);
}

function setMeta(key, value, callback) {
    db.get("SELECT id, value from meta WHERE key = ?", [key], function (err, row) {
        if (err || row === undefined) {
            db.run("INSERT INTO meta (key, value) VALUES (?, ?)", [key, value], callback)
        } else {
            db.run("UPDATE meta SET value = ? WHERE id = ?", [value, row.id], callback);
        }
    });
}

////////////////////////////
//////// INSERTS ///////////
////////////////////////////

// Insert Person Prepared statement
let personStatement = db.prepare("INSERT INTO people (first_name, last_name, is_me) VALUES (?, ?, ?)");

function insertPerson(firstName, lastName, isMe, callback = emptyFunction) {
    personStatement.run([firstName, lastName, isMe ? 1 : 0], callback);
}

// Insert Chat Prepared statement
let chatInsertStmt = db.prepare("INSERT into chats (archived, display_name) VALUES (?, ?)");

function insertChat(isArchived, displayName, callback = emptyFunction) {
    chatInsertStmt.run([isArchived, displayName], callback);
}

let handleStatement = db.prepare("INSERT INTO handles (handle, person_id) VALUES (?, ?)");

function insertHandle(handle, personId, callback = emptyFunction) {
    handleStatement.run([handle, personId], callback);
}

let chatPersonStatement = db.prepare("INSERT into chat_people (chat_id, person_id) VALUES (?, ?)");

function insertChatPerson(chatId, personId, callback = emptyFunction) {
    chatPersonStatement.run([chatId, personId], callback);
}

const messagesStatement = "INSERT INTO messages (sender_id, date, from_me, chat_id, text, year, month, day_of_week, hour, minute, day_of_month) VALUES ";
const messagePlaceholder = "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";


// Messages is an array of arrays, where each sub array contains message data in order of messagesStatement
function insertMessages(messages, numMessages, callback = emptyFunction) {
    let placeholders = [];
    for (let i = 0; i < numMessages; i++) {
        placeholders.push(messagePlaceholder);
    }

    let statement = messagesStatement + placeholders.join(",");
    db.run(statement, messages, callback);
}

////////////////////////////
//////// SELECTS ///////////
////////////////////////////

const chatsSelectStmt = "SELECT c.id, c.display_name, m.date, m.count AS message_count, m.id AS message_id, m.text AS message_text\n" +
    "FROM (\n" +
    "SELECT COUNT(*) AS count, id, text, date, chat_id, max(date) FROM messages ";

const secondPart = "GROUP BY chat_id) m\n" +
    "INNER JOIN chats c ON m.chat_id = c.id\n" +
    "ORDER BY m.date DESC";

function selectChats(days = [], callback = emptyFunction) {
    let currStatement = chatsSelectStmt;
    let currParams = [];
    if (days.length > 0) {
        currStatement += " WHERE ";
        days.forEach(function (day) {
            currStatement += "(year = ? and month = ? and day_of_month = ?) OR ";
            currParams.push(day[0], day[1], day[2]);
        });
        currStatement += "0\n";
    }

    currStatement += secondPart;
    db.all(currStatement, currParams, callback);
}

let peopleByChatSelectStmt = db.prepare("" +
    "SELECT p.first_name, p.last_name\n" +
    "FROM people p\n" +
    "INNER JOIN chat_people cp ON cp.person_id = p.id\n" +
    " WHERE cp.chat_id = ?;");

function selectPeopleByChat(id, callback = emptyFunction) {
    peopleByChatSelectStmt.all([id], callback);
}

const messageSelectStmt = "SELECT m.text, m.from_me, m.year, m.month, m.day_of_month, m.hour, m.minute, p.first_name FROM messages m JOIN people p ON p.id = m.sender_id WHERE m.chat_id = ? ";

function selectMessages(chatId, days, callback) {
    let currStatement = messageSelectStmt;
    let currParams = [chatId];

    if (days.length > 0) {

        currStatement += "AND (";
        days.forEach(function (day) {
            currStatement += "(m.year = ? and m.month = ? and m.day_of_month = ?) OR ";
            currParams.push(day[0], day[1], day[2]);
        });
        currStatement += "0)";
    }

    db.all(currStatement + " ORDER BY m.date ASC", currParams, callback);
}

const calendarMessagesStmt = "SELECT COUNT(id) AS num_messages, SUM(length(text)) AS num_words, year, month, day_of_week, day_of_month FROM messages ";
const calendarMessagesStmtTwo = " GROUP BY year, month, day_of_month ORDER BY year ASC, month ASC, day_of_month ASC";

function selectCalendarMessages(chat = null, callback = emptyFunction) {
    let statement = calendarMessagesStmt + (chat ? "WHERE chat_id = ?" : "") + calendarMessagesStmtTwo;
    db.all(statement, chat ? [chat] : [], callback);
}


module.exports = {
    database: db,
    serialize: serialize,
    parallelize: parallelize,

    // Meta
    getMeta: getMeta,
    setMeta: setMeta,

    // Insert Methods
    insertPerson: insertPerson,
    insertChat: insertChat,
    insertHandle: insertHandle,
    insertChatPerson: insertChatPerson,
    insertMessages: insertMessages,

    // Select Methods
    selectChats: selectChats,
    selectPeopleByChat: selectPeopleByChat,
    selectMessages: selectMessages,
    selectCalendarMessages: selectCalendarMessages,
    createTables: createTables,
};