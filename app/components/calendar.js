let db = require('../data/database');
let renderer = require("../renderer");

let calendar = document.getElementById("calendar");
let tooltip = calendar.getElementById("tooltip");
let tooltiptext = calendar.getElementById("tooltiptext");
const svgns = "http://www.w3.org/2000/svg";
let chats = document.getElementById("chats");

const monthLabelHeight = 20;
const dayLabelWidth = 60;
const spacing = 2;
const calHeight = Number(window.getComputedStyle(calendar).getPropertyValue('height').replace(/\D/g, ''));
const dayHeight = (calHeight - monthLabelHeight - (spacing * 7)) / 7;


let initialRenderCompleted = false;
let initialRenderInProgress = false;
let initialRenderFilters;

let weeks = document.createElementNS(svgns, "g");
weeks.setAttribute("transform", "translate(" + dayLabelWidth + "," + monthLabelHeight + ")");
calendar.appendChild(weeks);

let days = {};

function getDay(year, month, dayOfMonth) {
    if (!days[year]) {
        return null;
    }
    if (!days[year][month]) {
        return null;
    }
    return days[year][month][dayOfMonth];
}

function insertDay(day, year, month, dayOfMonth) {
    if (!days[year]) {
        days[year] = {};
    }
    if (!days[year][month]) {
        days[year][month] = {};
    }
    days[year][month][dayOfMonth] = day;
}

function createWeek(weekIndex) {
    let week = document.createElementNS(svgns, "g");
    weeks.appendChild(week);
    let x = (weekIndex * (dayHeight + spacing));
    week.dataset.x = x;
    week.setAttribute("transform", "translate(" + x + ", 0)");
    calendar.setAttribute("width", ((weekIndex + 1.5) * (dayHeight + spacing)) + dayLabelWidth);
    return week;
}


function createDay(year, month, dayOfMonth, dayOfWeek) {
    let day = document.createElementNS(svgns, "rect");
    let title = document.createElementNS(svgns, "title");
    day.appendChild(title);
    title.textContent = (month + 1) + "/" + dayOfMonth + "/" + year;
    day.setAttribute("width", dayHeight);
    day.setAttribute("height", dayHeight);
    day.setAttribute("x", 0);
    day.setAttribute("y", dayOfWeek * (dayHeight + spacing));
    day.setAttribute("fill", "#ebedf0");
    day.setAttribute("fill-opacity", 1.0);
    day.setAttribute("visibility", "hidden");

    day.dataset.year = year;
    day.dataset.month = month;
    day.dataset.dayofmonth = dayOfMonth;
    day.dataset.dayofweek = dayOfWeek;

    day.onclick = function (event) {

        if (day.classList.contains("active")) {
            renderer.unfilterByDay(year, month, dayOfMonth);
            day.classList.remove("active");
        } else {
            if (day.dataset.messages > 0) {
                renderer.filterByDay(year, month, dayOfMonth);
                day.classList.add("active");
            }
        }

    };

    return day;
}


function createMonthLabel(weekX, month, year) {
    let label = document.createElementNS(svgns, "text");
    label.setAttribute("x", Number(weekX));
    label.setAttribute("y", 18);
    label.classList.add("month-label");
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    label.textContent = months[month] + " " + year;
    calendar.appendChild(label);
}

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

    db.selectCalendarMessages(null, function (err, rows) {
        let currDate = new Date(rows[0].year, rows[0].month, rows[0].day_of_month);

        let weekIndex = 0;
        let week = createWeek(weekIndex);

        let addDay = function (year, month, dayOfMonth) {
            let dayOfWeek = currDate.getDay();
            let day = createDay(year, month, dayOfMonth, dayOfWeek);
            insertDay(day, year, month, dayOfMonth);
            week.appendChild(day);

            if (dayOfMonth === 1) {
                createMonthLabel(Number(week.dataset.x) + dayLabelWidth, month, year);
            }

            if (dayOfWeek === 6) {
                weekIndex += 1;
                week = createWeek(weekIndex);
            }
            currDate.setDate(currDate.getDate() + 1);
        };

        rows.forEach(function (row) {
            let dayOfMonth = row.day_of_month;
            let month = row.month;
            let year = row.year;

            let needFillerDate = function () {
                return currDate.getFullYear() !== year || currDate.getMonth() !== month || currDate.getDate() !== dayOfMonth
            };


            while (needFillerDate()) {
                addDay(currDate.getFullYear(), currDate.getMonth(), currDate.getDate(), 0, 0);
            }

            addDay(year, month, dayOfMonth);

        });

        initialRenderCompleted = true;
        initialRenderInProgress = false;

        renderWithFilters(initialRenderFilters);

    });
}

function renderWithFilters(filters) {
    db.selectCalendarMessages(filters.chat, function (err, rows) {

        weeks.childNodes.forEach(function (week) {
            week.childNodes.forEach(function (day) {
                day.setAttribute("fill", "#ebedf0");
                day.setAttribute("fill-opacity", 1.0);
                day.setAttribute("visibility", "visible");
                day.dataset.messages = 0;
                day.dataset.words = 0;

                day.childNodes[0].textContent = (Number(day.dataset.month) + 1) + "/" + day.dataset.dayofmonth + "/" + day.dataset.year + ": 0 Messages, 0 Words";
            });
        });

        let maxMessages = 0;
        let maxWords = 0;

        rows.forEach(function (row) {
            maxMessages = Math.max(maxMessages, row.num_messages);
            maxWords = Math.max(maxWords, row.num_words);
        });

        rows.forEach(function (row) {
            let dayOfMonth = row.day_of_month;
            let month = row.month;
            let year = row.year;

            let day = getDay(year, month, dayOfMonth);

            let numMessages = row.num_messages;
            let numWords = row.num_words;

            let noMessages = numMessages === 0;

            day.setAttribute("visibility", "visible");
            day.setAttribute("fill", noMessages ? "#ebedf0" : "red");
            day.setAttribute("fill-opacity", noMessages ? 1.0 : ((numMessages / maxMessages) / 1.5 + 0.15));
            day.dataset.messages = numMessages;
            day.dataset.words = numWords;

            day.childNodes[0].textContent = (Number(day.dataset.month) + 1) + "/" + dayOfMonth + "/" + year + ": " + numMessages + " Messages, " + numWords + " Words";
        });

    });
}


module.exports = {
    filterBy: filterBy
};