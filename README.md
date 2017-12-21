# backup-script

## Installation

You can download the files from Github.com or use directly Git :

```
git clone https://github.com/SmurfyFR/backup-script.git
chmod +x backup.sh
```

## Usage

Once downloaded, it's very easy to get started. You just need to call the backup.sh script with the correct parameters !

```
cd backup-script # Here is where you downloaded the script
./backup.sh root@server029.company.tld:/ /volumes/backup/server029
```

Backups will be stored in the `/volumes/backup/server029` folder.
The `last/` folder will keep the latest backup. Backups are archived using current date (Day-Month-Year_Hour).
By default, archived backups are kept for 7 days. Everytime the script is started, it will detect if a 7 days old backup is present and delete it.
