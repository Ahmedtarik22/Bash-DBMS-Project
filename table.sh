#!/bin/bash

table_menu() {
    while true
    do
        choice=$(zenity --list \
            --title="Tables Menu" \
            --text="Choose table operation" \
            --column="Options" \
            "List Tables" \
            "Create Table" \
            "Drop Table" \
            "Back")

        [[ $? -ne 0 ]] && return 0

        case "$choice" in
            "List Tables") list_tables ;;
            "Create Table") create_table ;;
            "Drop Table") drop_table ;;
            "Back") return 0 ;;
            *) zenity --error --text="Invalid choice" ;;
        esac
    done
}

ensure_db_connected() {
    if [[ -z "$CURRENT_DB" ]]
    then
        zenity --error --text="No database selected"
        return 1
    fi
    return 0
}


list_tables() {
    ensure_db_connected || return 1

    shopt -s nullglob
    tables=("$CURRENT_DB"/*"$ACTIVE_TABLE")
    shopt -u nullglob

    if [[ ${#tables[@]} -eq 0 ]]
    then
        zenity --error \
            --title="No Tables" \
            --text="No tables found in this database"
        return 1
    fi

    printf "%s\n" "${tables[@]##*/}" | zenity --list \
        --title="Tables List" \
        --text="Available Tables" \
        --column="Table Name"
}


create_table() {
    ensure_db_connected || return 1

    while true
    do
        table_name=$(zenity --entry \
            --title="Create Table" \
            --text="Enter table name:")

        [[ $? -ne 0 ]] && return 0

        validate_name "$table_name" || {
            zenity --error --text="Invalid table name"
            continue
        }

        table_path="$CURRENT_DB/$table_name$ACTIVE_TABLE"

        if [[ -f "$table_path" ]]
        then
            zenity --error --text="Table already exists"
            continue
        fi

        zenity --info \
            --title="Next Step" \
            --text="Table name accepted\nNext: define columns"
        break
    done
}


drop_table() {
    ensure_db_connected || return 1

    shopt -s nullglob
    tables=("$CURRENT_DB"/*"$ACTIVE_TABLE")
    shopt -u nullglob

    if [[ ${#tables[@]} -eq 0 ]]
    then
        zenity --error \
            --title="No Tables" \
            --text="There are no tables to delete in this database"
        return 1
    fi

    table=$(printf "%s\n" "${tables[@]##*/}" | zenity --list \
        --title="Drop Table" \
        --text="Select table to drop" \
        --column="Table")

    [[ $? -ne 0 || -z "$table" ]] && return 0

    zenity --question \
        --text="Are you sure you want to delete table '$table'?"

    [[ $? -ne 0 ]] && return 0

    rm -f "$CURRENT_DB/$table"

    zenity --info --text="Table deleted successfully"
}

