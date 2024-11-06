#!/bin/bash

new_db_name="livecopy_23102024"
backup_sql_path="./OdooV15EE_backup_10_23_2024.dump"
backup_filestore_path="./OdooV15EE"
local_filestore_path="../.local/share/Odoo/filestore"
postgres_user="odoo"

if [[ -z "$new_db_name" || -z "$backup_sql_path" || -z "$backup_filestore_path" || -z "$local_filestore_path" || -z "$postgres_user" ]]; then
  echo "One or more required variables are not set."
  exit 1
fi

# Create database
echo "Creating database ----: $new_db_name ..."
createdb -U "$postgres_user" "$new_db_name"
if [ $? -ne 0 ]; then
  echo "Database $new_db_name creation failed"
  exit 1
fi

# Determine if the backup file is .dump or .sql and restore accordingly
if [[ "$backup_sql_path" == *.dump ]]; then
  echo "Restoring database from dump file using pg_restore..."
  pg_restore -U "$postgres_user" -d "$new_db_name" "$backup_sql_path"
  if [ $? -ne 0 ]; then
    echo "Restore process failed from $backup_sql_path, please check again."
    exit 1
  fi
else
  echo "Restoring database from SQL file..."
  psql -U "$postgres_user" "$new_db_name" < "$backup_sql_path"
  if [ $? -ne 0 ]; then
    echo "Restore process failed from $backup_sql_path, please check again."
    exit 1
  fi
fi

# Optionally, delete the backup file if the restore is successful
#rm -f "$backup_sql_path"
echo "$new_db_name restored successfully and $backup_sql_path file is deleted."

# Create a directory in the given local_filestore_path with the same name as new_db_name
new_filestore_path="${local_filestore_path}/${new_db_name}"
echo "Creating new filestore directory $new_filestore_path..."
mkdir -p "$new_filestore_path"
if [ $? -ne 0 ]; then
  echo "Failed to create the filestore directory $new_filestore_path"
  exit 1
fi

# Move filestore files to the new filestore directory
echo "Moving filestore from $backup_filestore_path to $new_filestore_path..."
mv "$backup_filestore_path"/* "$new_filestore_path"/
if [ $? -ne 0 ]; then
  echo "Failed to move filestore from $backup_filestore_path to $new_filestore_path"
  exit 1
fi

echo "Database and filestore restored successfully. Please restart Odoo with the proper configuration."

