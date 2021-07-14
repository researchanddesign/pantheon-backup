const { execSync } = require('child_process');
const fs = require('fs');
const gfs = require('grandfatherson');
const dayjs = require('dayjs');

const settings = require('./settings.json');
if (!settings.pantheonEmail) {
	throw new Error('Missing pantheonEmail');
}
if (!settings.pantheonSite) {
	throw new Error('Missing pantheonSite');
}
if (!settings.pantheonEnv) {
	throw new Error('Missing pantheonEnv');
}
if (!settings.backupDirectory) {
	throw new Error('Missing backupDirectory');
}

let now = dayjs();
const dates = [];
for(let i = 0; i < 365; i++) {
	dates.push(now.format());
	now = now.subtract(1, 'day');
}
const datesToDelete = gfs.toDelete(dates, {
	days   : 14,
	weeks  : 4,
	months : 12,
	firstweekday : 6, // The first day of the week to consider when calculating weekly dates to keep. Defaults to Saturday. Valid values are 0-6 (Sunday-Saturday)
});

console.log('Grabbing new backup from Pantheon.')
execSync(`./backup.sh -u ${settings.pantheonEmail} -s ${settings.pantheonSite} -e ${settings.pantheonEnv} -d ${settings.backupDirectory}`);
console.log('Finished most recent Pantheon backup.');

console.log('Removing out of date backups.');
datesToDelete.forEach((date, i) => {
	const subFolder = date.format('YYYYMMDD');
	const path = `${settings.backupDirectory}pantheon-backup-${subFolder}`;
	if (fs.existsSync(path)) {
		fs.rmdir(path, { recursive: true }, (err) => {
			if (err) {
				console.log(err);
			}
		});
	}
});
console.log('Finished Pantheon backup script.')
