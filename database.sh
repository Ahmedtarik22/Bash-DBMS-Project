#!/bin/bash
get_database_list() {
    find "$DB_ROOT" -maxdepth 1 -type d ! -path "$DB_ROOT" | awk -F/ '{print $NF}'
}

count_databases() {
    find "$DB_ROOT" -maxdepth 1 -type d ! -path "$DB_ROOT" | wc -l
}

list_databases() {
    db_count=$(count_databases)
    if [[ "$db_count" -eq 0 ]]; then
        zenity --error --title="No Databases" --text="No databases found"
        return 1
    fi

    get_database_list | zenity --list --title="List of Databases" --text="Available databases ($db_count found):" --column="Database Name" --height=400
    
    return 0
}

create_database() {
    while true
    do
        db_name=$(zenity --entry --title="Create Database" --text="Enter database name:")
        
        if [[ $? -ne 0 ]]
        then
            return 0
        fi
        
        validate_name "$db_name" || continue

        db_path="$DB_ROOT/$db_name"
        if [[ -e "$db_path" ]]; then
            zenity --error --title="Already Exists" --text="A database or file named '$db_name' already exists"
            continue
        fi

        mkdir -p "$db_path" || {
            zenity --error --title="Creation Failed" --text="Failed to create database '$db_name' check permissions"
            continue
        }

        zenity --info --title="Success" --text="Database '$db_name' created successfully"
        break
    done
}