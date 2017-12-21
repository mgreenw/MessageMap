let db = require('../data/database');
let renderer = require("../renderer");

let messageList = document.getElementById("messages");
let loader = document.getElementById("loading");
let helptext = document.getElementById("helptext");

function filterBy(filters) {
    loader.style.display = "";
    while (messageList.firstChild) {
        messageList.removeChild(messageList.firstChild);
    }

    if (filters.chat !== null) {

        db.selectMessages(filters.chat, filters.days, function (err, rows) {
            rows.forEach(function (row) {
                let message = createMessage(row.text, row.from_me === 1, row.year, row.month, row.day_of_month, row.hour, row.minute, row.first_name);
                messageList.appendChild(message);
            });

            loader.style.display = "none";
            helptext.style.display = "none";
            messageList.scrollTop = messageList.scrollHeight;
        });


    } else {
        helptext.style.display = "";
        loader.style.display = "none";
    }
}


function createMessage(text, fromMe, year, month, dayOfMonth, hour, minute, senderName) {
    let message = document.createElement("li");
    // let tooltip = document.createElement("span");
    // tooltip.innerText = month + "/" + dayOfMonth + "/" + year;
    // tooltip.classList.add("tooltiptext");
    // message.classList.add("tooltip");
    // message.appendChild(tooltip);
    let messageText = document.createElement("p");
    messageText.innerText = text;
    message.setAttribute("class", "message " + (fromMe ? "me" : "not-me"));
    messageText.setAttribute("title", senderName + ": " + (month+1) + "/" + dayOfMonth + "/" + year + " " + hour + ":" + (minute < 10 ? "0" : "") + minute);
    message.appendChild(messageText);
    return message;
}

module.exports = {
    filterBy: filterBy
};