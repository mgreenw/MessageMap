let db = require('./database');
var fs = require('fs');
let facebookPath;

function importFacebookMessages(facebookDownloadFolderPath, success, failure) {
    return new Promise((resolve, reject) => {
        const exists = fs.existsSync(facebookDownloadFolderPath);
        if (!exists) {
            failure();
        }
    });
}