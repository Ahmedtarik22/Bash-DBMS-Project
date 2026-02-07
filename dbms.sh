#!/bin/bash
source ./config.sh
source ./database.sh
source ./table.sh
source ./validation.sh
init_db
while true
do
    choice=$(zenity --list --title="BASH DBMS" --text="Choose an option" --column="Database List" "Create DB" "Connect To DB" "List DBs" "Drop DB" "Exit" --height=400)
    if [[ $? -ne 0 ]]
    then
        exit 0
    fi
    case "$choice" in 
        "Create DB") create_database
        ;;
        "Connect To DB") connect_database
        ;;
        "List DBs") list_databases
        ;;
        "Drop DB") drop_database
        ;;
        "Exit") exit 0
        ;;
        *) zenity --error --text="Invalid choice"
        ;;
    esac
done