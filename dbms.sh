#!/bin/bash
source ./config.sh
source ./database.sh
source ./table.sh
source ./validation.sh
init_db
while true
do
    choice=$(zenity --list --title="BASH DBMS" --text="Choose an option" --column="Database List" "Create DB" "List DB" "Drop DB" "Exit" --height=400 --width=400)
    if [[ $? -ne 0 ]]
    then
        exit 0
    fi
    case "$choice" in 
        "Create DB") zenity --info --text="creating db"
        ;;
        "List DB") zenity --info --text="list db"
        ;;
        "Drop DB") zenity --info --text="drop db"
        ;;
        "Exit") exit 0
        ;;
        *) zenity --error --text="err"
        ;;
    esac
done