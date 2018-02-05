#!/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}

_usage () {
    die "Usage : $0 [-p port] [--dry-run] [--verbose|-v] root@hostname.tld:/ /volumes/backup/dest"
}

[ "$#" -gt 1 ] || _usage

source $(dirname $0)/backup_config.sh
eval SSH_FILE=$SSH_FILE
eval EXCLUDE_FILE=$EXCLUDE_FILE

SSH_PORT=22
RSYNC_OPT="--quiet"
while getopts :p:v-:verbose option
do
    case "${option}"
    in
    p) SSH_PORT=${OPTARG};;
    v) RSYNC_OPT=${RSYNC_OPT/"--quiet"/"--progress -v"};;
    -) case "${OPTARG}" in
        dry-run) RSYNC_OPT="$RSYNC_OPT --dry-run";;
        verbose) RSYNC_OPT=${RSYNC_OPT/"--quiet"/"--progress -v"};;
        *) _usage
       esac;;
    [?]) _usage
    esac
done
shift $(($OPTIND - 1))

# Get source and destination from parameters
SRC=$1
DST=$2

# Make sure dest folder is created
mkdir -p $DST

# Get current datetime
DATE=`date +%Y-%m-%d_%H`

# Get backup name from 7 days ago
EXPIRATION=`date -d "7 days ago" +%s`

for i in $(ls $DST)
do
    if test -d $DST/$i; then
        # Only match YYYY-MM-DD_HH directories
        if [[ $i =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}$ ]]; then
            # Parse into full date (YYYY-MM-DD HH:00:00)
            i_date=`date -d "${i%_*} ${i#*_}:00:00" +%s`

            if [ $i_date -le $EXPIRATION ]; then
                echo "Deleting expired backup (7 days) : $i ..."
                rm -rf $DST/$i
            fi
        fi
    fi
done

# Create tmp folder
mkdir -p $DST/tmp

echo "Starting backup "`date "+%Y-%m-%d %T"`
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
rsync -e "ssh -p $SSH_PORT -i $SSH_FILE" -aPx $RSYNC_OPT --delete-after --numeric-ids --exclude-from="$EXCLUDE_FILE" $SRC/ $DST/last/

if [ $? -eq 0 ]
then
    echo "Finished RSYNC."

    echo "Backup finished at "`date "+%Y-%m-%d %T"`
    echo "Done  : "`date "+%Y-%m-%d %T"` >> $DST/log
else
    echo "WARNING: RSYNC finished with an error code."
    echo "Error : "`date "+%Y-%m-%d %T"` >> $DST/log
fi
