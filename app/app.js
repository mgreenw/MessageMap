const electron = require('electron');
const Menu = electron.Menu;
const app = electron.app;

var BrowserWindow = electron.BrowserWindow;

let mainWindow;

app.on('window-all-closed', function () {
    app.quit();
});

// This method will be called when Electron has done everything
// initialization and ready for creating browser windows.
app.on('ready', function () {
    // Create the browser window.

    // const template = [
    //     {
    //         label: 'Filter',
    //         submenu: [
    //             {
    //                 label: 'Hello',
    //                 accelerator: 'Shift+CmdOrCtrl+H',
    //                 click() {
    //                     console.log('Oh, hi there!')
    //                 }
    //             }
    //         ]
    //     }
    // ];
    // Menu.setApplicationMenu(Menu.buildFromTemplate(template));

    //var path = app.setPath("MessageMap", app.getPath("appData"));
    global.dataPath = app.getPath("userData");
    global.resourcesPath = process.resourcesPath;
    mainWindow = new BrowserWindow({width: 1500, height: 1200, title:"MessageMap"});

    // and load the index.html of the app.
    mainWindow.loadURL('file://' + __dirname + '/index.html');

    // Emitted when the window is closed.
    mainWindow.on('closed', function () {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        mainWindow = null;
    });


});


