CREATE TABLE attachments
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    message_id INTEGER NOT NULL,
    path TEXT NOT NULL,
    CONSTRAINT attachments_messages_id_fk FOREIGN KEY (message_id) REFERENCES messages (id)
);
CREATE TABLE chat_people
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    chat_id INTEGER NOT NULL,
    person_id INTEGER NOT NULL,
    CONSTRAINT chat_people_chats_id_fk FOREIGN KEY (chat_id) REFERENCES chats (id),
    CONSTRAINT chat_people_people_id_fk FOREIGN KEY (person_id) REFERENCES people (id)
);
CREATE TABLE chats
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    archived BOOLEAN NOT NULL,
    display_name TEXT
);
CREATE TABLE handles
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    handle TEXT NOT NULL,
    person_id INTEGER NOT NULL,
    CONSTRAINT handles_people_id_fk FOREIGN KEY (handle) REFERENCES people (id)
);
CREATE TABLE messages
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    sender_id INTEGER NOT NULL,
    date INTEGER NOT NULL,
    from_me BOOLEAN NOT NULL,
    chat_id INTEGER NOT NULL,
    text TEXT,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    hour INTEGER NOT NULL,
    minute INTEGER NOT NULL,
    day_of_month INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT messages_people_id_fk FOREIGN KEY (sender_id) REFERENCES people (id),
    CONSTRAINT messages_chats_id_fk FOREIGN KEY (chat_id) REFERENCES chats (id)
);
CREATE TABLE meta
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL
);
CREATE TABLE people
(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT,
    is_me BOOLEAN DEFAULT FALSE NOT NULL
);