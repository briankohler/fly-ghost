#!/bin/bash
set -e

env
# Restore the database if it does not already exist.
if [ -f /var/lib/ghost/content/data/ghost.db ]; then
	echo "Database already exists, skipping restore"
else
	echo "No database found, restoring from replica if exists"
	litestream restore -v -if-replica-exists -o /var/lib/ghost/content/data/ghost.db content/data/ghost.db
fi

# Run litestream with your app as the subprocess.
exec litestream replicate --trace /dev/stdout -exec "docker-entrypoint.sh node current/index.js"
