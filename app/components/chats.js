let db = require('../data/database');
let renderer = require("../renderer");

let chats = document.getElementById("chats");
let chatsById = {};

let initialRenderCompleted = false;
let initialRenderInProgress = false;
let initialRenderFilters;
let shouldScroll = true;

function filterBy(filters) {
    if (!initialRenderCompleted) {
        initialRenderFilters = filters;
        if (!initialRenderInProgress) {
            performInitialRender();
        }
    } else {
        renderWithFilters(filters);
    }
}

function performInitialRender() {
    initialRenderInProgress = true;

    db.selectChats([], function (err, chatRows) {
        if (err) {
            console.log(err);
        }

        for (let i = 0; i < chatRows.length; i++) {
            let row = chatRows[i];
            let chatId = row.id;

            db.selectPeopleByChat(chatId, function (err, personRows) {
                let displayName = row.display_name;
                if (displayName === null || displayName.trim() === "") {
                    let people = [];
                    personRows.forEach(function (person) {
                        let name = person.first_name;
                        if (person.last_name !== null) {
                            name += " " + person.last_name;
                        }
                        people.push(name);
                    });
                    displayName = people.join(", ")
                }

                //displayName += " " + dateToString(row.date);

                let chat = createChat(displayName, chatId, row.message_count);

                console.log("Push Chat onto list");

                if (i === chatRows.length - 1) {

                    // Finish rendering
                    console.log("Finish render");


                    renderWithFilters(initialRenderFilters);
                    initialRenderCompleted = true;
                    initialRenderInProgress = false;
                    // chats.childNodes.forEach(function (chat) {
                    //     console.log(chat);
                    //     chat.setAttribute("hidden", "false");
                    // });
                }


            });
        }

    });
}


Array.prototype.simplediff = function (a) {
    return this.filter(function (i) {
        return a.indexOf(i) === -1;
    });
};


function renderWithFilters(filters) {
    let activeChat = null;
    let needToScroll = false;
    db.selectChats(filters.days, function (err, chatRows) {
        let allChatIds = Object.keys(chatsById);
        let filteredChatIds = chatRows.map(function (chatRow) {
            return chatRow.id
        });

        let hiddenChatIds = allChatIds.simplediff(filteredChatIds);

        for (let i = 0; i < hiddenChatIds.length; i++) {
            let chat = chatsById[hiddenChatIds[i]];
                chat.style.display = "none";

            if (chat.classList.contains("active")) {
                activeChat = chat;
            }
        }


        chatRows.forEach(function(row) {
            chatsById[row.id].setAttribute("title", "Number of Messages: " + row.message_count);
        });

        for (let i = 0; i < filteredChatIds.length; i++) {
            let chat = chatsById[filteredChatIds[i]];
                chat.style.display = "list-item";
            if (chat.classList.contains("active")) {
                activeChat = chat;
            }
        }
        if (activeChat !== null && shouldScroll) {
            activeChat.scrollIntoView({behavior: "smooth", inline: "center"});
        }
        shouldScroll = true;
    });

}

function dateToString(date) {
    let ourDate = new Date(date);
    return ourDate.toLocaleString();
}

function createChat(displayName, id, numberOfMessages) {
    let chat = document.createElement("li");
    chats.appendChild(chat);
    chat.setAttribute("class", "chat");
    chat.style.display = "none";
    chat.setAttribute("title", "Number of Messages: " + numberOfMessages);
    //chat.setAttribute("hidden", "true");
    chat.innerText = displayName;
    chat.dataset.id = id;
    chat.onclick = function () {
        if (chat.classList.contains("active")) {
            chat.classList.remove("active");
            renderer.removeChatFilter();
        } else {
            for (let id in chatsById) {
                let chat = chatsById[id];
                chat.classList.remove("active");
            }
            chat.classList.add("active");
            renderer.filterByChat(id);
        }
        shouldScroll = false;

    };

    chatsById[id] = chat;
    return chat;
}

module.exports = {
    filterBy: filterBy
};