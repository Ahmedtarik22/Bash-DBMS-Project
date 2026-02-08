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

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$")

    if [[ -z "$tables" ]]
    then
        zenity --error --text="No tables found in this database"
        return 1
    fi

    echo "$tables" | zenity --list \
        --title="Tables List" \
        --column="Table Name"
}

create_table() {
    ensure_db_connected || return 1

    table_name=$(zenity --entry \
        --title="Create Table" \
        --text="Enter table name:")

    [[ $? -ne 0 ]] && return 0

    validate_name "$table_name" || {
        zenity --error --text="Invalid table name"
        return 1
    }

    if [[ -f "$CURRENT_DB/$table_name.table" ]]
    then
        zenity --error --text="Table already exists"
        return 1
    fi

    define_columns "$table_name"
}

define_columns() {
    table_name="$1"

    col_count=$(zenity --entry \
        --title="Columns Count" \
        --text="Enter number of columns:")

    [[ $? -ne 0 ]] && return 1

    if ! [[ "$col_count" =~ ^[0-9]+$ ]] || [[ "$col_count" -le 0 ]]
    then
        zenity --error --text="Invalid number of columns"
        return 1
    fi

    columns=""
    types=""

    for (( i=1; i<=col_count; i++ ))
    do
        col_name=$(zenity --entry \
            --title="Column Name" \
            --text="Enter name of column $i:")

        validate_name "$col_name" || return 1

        if echo "$columns" | grep -w "$col_name" >/dev/null
        then
            zenity --error --text="Duplicate column name"
            return 1
        fi

        col_type=$(zenity --list \
            --title="Column Type" \
            --column="Type" \
            "int" "string")

        [[ $? -ne 0 ]] && return 1

        columns="$columns$col_name:"
        types="$types$col_type:"
    done

    columns="${columns%:}"
    types="${types%:}"

    pk=$(echo "$columns" | tr ":" "\n" | zenity --list \
        --title="Primary Key" \
        --text="Choose Primary Key" \
        --column="Column")

    [[ $? -ne 0 || -z "$pk" ]] && return 1

    echo "$columns" > "$CURRENT_DB/$table_name.meta"
    echo "$types" >> "$CURRENT_DB/$table_name.meta"
    echo "$pk" >> "$CURRENT_DB/$table_name.meta"

    touch "$CURRENT_DB/$table_name.table"

    zenity --info --text="Table '$table_name' created successfully"
}

drop_table() {
    ensure_db_connected || return 1

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$")

    if [[ -z "$tables" ]]
    then
        zenity --error --text="There are no tables to delete"
        return 1
    fi

    table=$(echo "$tables" | zenity --list \
        --title="Drop Table" \
        --text="Select table to drop" \
        --column="Table Name")

    [[ $? -ne 0 || -z "$table" ]] && return 0

    zenity --question --text="Are you sure you want to delete table '$table'?"

    [[ $? -ne 0 ]] && return 0

    rm -f "$CURRENT_DB/$table"
    rm -f "$CURRENT_DB/${table%.table}.meta"

    zenity --info --text="Table deleted successfully"
}
