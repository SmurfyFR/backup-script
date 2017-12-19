#!/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -gt 1 ] || die "Usage : $0 [-p port] root@hostname.tld:/ /volumes/backup/dest"

source $(dirname $0)/backup_config.sh
eval SSH_FILE=$SSH_FILE
eval EXCLUDE_FILE=$EXCLUDE_FILE

SSH_PORT=22
while getopts p: option
do
    case "${option}"
    in
    p) SSH_PORT=${OPTARG};;
    [?])    die "Usage : $0 [-p port] root@hostname.tld:/ /volumes/backup/dest"
    esac
done
shift $(($OPTIND - 1))

# Get source and destination from parameters
SRC=$1
DST=$2

# Get current datetime
DATE=`date +%d-%m-%Y_%H` # Add -%H -%M -%S if multiple backups per day

# Get backup name from 7 days ago
EXPIRATION=`date +"%d-%m-%Y_%H" -d "7 days ago"`  # Add -%H -%M -%S if multiple backups per day

if [ -d $DST/$EXPIRATION ]
then
        echo "Deleting backup : $EXPIRATION ..."
        rm -rf $DST/$EXPIRATION
        echo
fi

# Create tmp folder
mkdir -p $DST/tmp

echo "Starting backup "`date "+%d-%m-%Y %T"`
echo "Start : "`date "+%Y-%m-%d %T"` >> $DST/log


# If it's not the first backup
if test -d $DST/last ; then
    if test -f $DST/last_date ; then
        LASTDATE=`cat $DST/last_date`

        echo "Archive last backup : $LASTDATE"

        # Hardlink copy to save disk space
        cp -al $DST/last $DST/tmp/
        # Then rename the hardlink copy
        mv $DST/tmp/last $DST/$LASTDATE

    fi

# Else, create the first backup folder
else
    echo "This is the first backup for this host"
    mkdir $DST/last
fi

rm -rf $DST/tmp

# Save the date for the next backup
echo $DATE > $DST/last_date


echo "Running RSYNC from $SRC to $DST/last using port $SSH_PORT ..."
# Rsync call : basically archiving everything
# You can use -v --progress for more detail. Don't forget that --dry-run is available.
rsync -e "ssh -p $SSH_PORT -i $SSH_FILE" -aPx -q -i --delete-after --numeric-ids --exclude-from="$EXCLUDE_FILE" $SRC/ $DST/last/
echo "Finished RSYNC."

echo "Backup finished at "`date "+%d-%m-%Y %T"`
echo "Done  : "`date "+%Y-%m-%d %T"` >> $DST/log