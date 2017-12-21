// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

let dataImport = require("./data/import");
const remote = require('electron').remote;

let dataPath = remote.getGlobal('dataPath');
console.log(dataPath);

// Components
let chats = require("./components/chats");
let messages = require("./components/messages");
let calendar = require("./components/calendar");
let charts = require("./components/charts");
let words = require("./components/words");
let loader = document.getElementById("loading");
let helptext = document.getElementById("helptext");

let components = [chats, messages, calendar, charts, words];
loader.style.display = "";
helptext.style.display = "none";

let filters = {
    chat: null,
    days: [],
    minutes: new Set(),
    hours: new Set(),
    daysOfTheWeek: new Set(),
    daysOfTheMonth: new Set(),
    years: new Set()
};



try {
    console.log(dataPath);
    dataImport.ensureImport(function () {
        // Success
        sendFilters();
        loader.style.display = "none";
        helptext.style.display = "";
    }, function (text) {
        // Failure
        loader.style.display = "none";
        console.log("Nothing to display...failure");
        helptext.style.display = "";
        helptext.innerText = "Failure..." + text || "";
        helptext.style.fontSize = 8;
    });
} catch(err) {
    loader.style.display = "none";
    helptext.style.display = "";
    helptext.innerText = err;
}


// Data filtering
module.exports.filterByChat = function (id) {
    filters.chat = id;
    console.log("Filter by", id);
    sendFilters();
};

module.exports.removeChatFilter = function () {

    filters.chat = null;
    sendFilters();
};

module.exports.filterByDay = function (year, month, day) {
    console.log("filter");
    let filterDay = [year, month, day];
    let index = filters.days.indexOfArray(filterDay);
    console.log("index:", index);
    if (index === null) {
        filters.days.push(filterDay);
    }

    sendFilters();
};

module.exports.unfilterByDay = function (year, month, day) {
    console.log("Unfilter");
    let filterDay = [year, month, day];
    let index = filters.days.indexOfArray(filterDay);
    console.log("Index:", index);
    if (index !== null) {
        console.log("REMOVE");
        filters.days.splice(index, 1);
    }
    sendFilters();
};

function arraysEqual(arr1, arr2) {
    if (arr1.length !== arr2.length) return false;
    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] !== arr2[i]) return false;
    }

    return true;
}

Array.prototype.indexOfArray = function (arr) {
    for (let i = 0; i < this.length; i++) {
        if (arraysEqual(this[i], arr)) {
            return i;
        }
    }
    return null;
};

function sendFilters() {
    console.log("Filter Days: ", filters.days);
    for (let i = 0; i < components.length; i++) {
        let component = components[i];
        if (component.filterBy) {
            component.filterBy(filters);
        }
    }
}

module.exports.setDataPath = function (path) {
    dataPath = path;
};


/*

Filter by:
    - One ore multiple chats
    - A day or day range
    - Any of the date components

*/
