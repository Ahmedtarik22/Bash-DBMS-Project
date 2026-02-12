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

select_database() {
    local operation="$1"
    
    db_count=$(count_databases)
    if [[ "$db_count" -eq 0 ]]; then
        zenity --info --title="No Databases" --text="No databases found.\n\nCreate a database first!"
        return 1
    fi

    selected=$(get_database_list | zenity --list --title="Select Database to $operation" --text="Choose a database to $operation:" --column="Database Name" --height=400)

    if [[ -z "$selected" ]]; then
        return 1
    fi

    echo "$selected"
    return 0
}

drop_database() {
    db_name=$(select_database "drop") || {
        return
    }

    db_path="$DB_ROOT/$db_name"
    if [[ ! -d "$db_path" ]]; then
        zenity --error --title="Not Found" --text="Database '$db_name' does not exist"
        return
    fi

    if zenity --question --title="Confirm Deletion" --text="Are you sure you want to drop database '$db_name'?
    This action cannot be undone"
    then
        rm -rf "$db_path" || {
            zenity --error --title="Deletion Failed" --text="Failed to delete '$db_name' check permissions"
            return
        }

        zenity --info --title="Success" --text="Database '$db_name' dropped successfully"
    else
        zenity --info --title="Cancelled" --text="Deletion cancelled"
    fi
}

connect_database() {
    db_name=$(select_database "connect") || {
        return
    }
    db_path="$DB_ROOT/$db_name"
    if [[ ! -d "$db_path" ]]; then
        zenity --error --title="Not Found" --text="Database '$db_name' does not exist"
        return
    fi

    CURRENT_DB="$DB_ROOT/$db_name"
    save_current_db

    zenity --info --title="Connected" --text="Connected to database '$db_name'."
    table_menu
}

disconnect_database() {
    if [[ -n "$CURRENT_DB" ]]; then
        db_name=$(basename "$CURRENT_DB")
        CURRENT_DB=""
        save_current_db
        zenity --info --title="Disconnected" --text="Disconnected from database '$db_name'"
    else
        zenity --info --title="Not Connected" --text="No database is currently connected"
    fi
}