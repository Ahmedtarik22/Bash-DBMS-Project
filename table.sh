#!/bin/bash

# =========================
# Table Menu
# =========================
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

