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
            "Insert Into Table" \
            "Drop Table" \
            "Back")

        [[ $? -ne 0 ]] && return 0

        case "$choice" in
            "List Tables") list_tables ;;
            "Create Table") create_table ;;
            "Insert Into Table") insert_into_table ;;
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

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$" | sed 's/\.table$//')

    if [[ -z "$tables" ]]
    then
        zenity --error --text="No tables found in this database"
        return 1
    fi

    zenity --list \
        --title="Tables List" \
        --column="Table Name" \
        $(echo "$tables")
}

create_table() {
    ensure_db_connected || return 1

    while true
    do
        table_name=$(zenity --entry \
            --title="Create Table" \
            --text="Enter table name:")

        [[ $? -ne 0 ]] && return 0

        validate_name "$table_name" || continue

        if [[ -f "$CURRENT_DB/$table_name.table" ]]
        then
            zenity --error --text="Table already exists"
            continue
        fi

        break
    done

    define_columns "$table_name"
}

define_columns() {
    table_name="$1"

    while true
    do
        col_count=$(zenity --entry \
            --title="Columns Count" \
            --text="Enter number of columns:")

        [[ $? -ne 0 ]] && return 1

        if [[ "$col_count" =~ ^[0-9]+$ ]] && [[ "$col_count" -gt 0 ]]
        then
            break
        fi

        zenity --error --text="Invalid number of columns"
    done

    columns=""
    types=""

    for (( i=1; i<=col_count; i++ ))
    do
        while true
        do
            col_name=$(zenity --entry \
                --title="Column Name" \
                --text="Enter name of column $i:")

            [[ $? -ne 0 ]] && return 1

            validate_name "$col_name" || continue

            if echo "$columns" | grep -w "$col_name" >/dev/null
            then
                zenity --error --text="Duplicate column name"
                continue
            fi

            break
        done

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
        --column="Column")

    [[ $? -ne 0 || -z "$pk" ]] && return 1

    echo "$columns" > "$CURRENT_DB/$table_name.meta"
    echo "$types" >> "$CURRENT_DB/$table_name.meta"
    echo "$pk" >> "$CURRENT_DB/$table_name.meta"

    touch "$CURRENT_DB/$table_name.table"

    zenity --info --text="Table '$table_name' created successfully"
}

insert_into_table() {
    ensure_db_connected || return 1

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$" | sed 's/\.table$//')
    [[ -z "$tables" ]] && {
        zenity --error --text="No tables found"
        return 1
    }

    table=$(zenity --list \
        --title="Insert Into Table" \
        --column="Table Name" \
        $(echo "$tables"))

    [[ $? -ne 0 || -z "$table" ]] && return 0

    meta="$CURRENT_DB/$table.meta"
    data="$CURRENT_DB/$table.table"

    columns=$(sed -n '1p' "$meta")
    types=$(sed -n '2p' "$meta")
    pk=$(sed -n '3p' "$meta")

    col_count=$(echo "$columns" | tr ":" "\n" | wc -l)
    values=""

    for (( i=1; i<=col_count; i++ ))
    do
        col=$(echo "$columns" | cut -d":" -f$i)
        type=$(echo "$types" | cut -d":" -f$i)

        while true
        do
            val=$(zenity --entry \
                --title="Insert Value" \
                --text="Enter value for $col ($type):")

            [[ $? -ne 0 ]] && return 0

            if [[ "$type" == "int" ]] && ! [[ "$val" =~ ^[0-9]+$ ]]
            then
                zenity --error --text="$col must be an integer"
                continue
            fi

            if [[ "$type" == "string" ]] && [[ "$val" == *:* ]]
            then
                zenity --error --text="String cannot contain ':'"
                continue
            fi

            if [[ "$col" == "$pk" ]]
            then
                if grep -q "^$val:" "$data" || grep -q ":$val:" "$data" || grep -q ":$val$" "$data"
                then
                    zenity --error --text="Primary key value already exists"
                    continue
                fi
            fi

            break
        done

        values="$values$val:"
    done

    values="${values%:}"
    echo "$values" >> "$data"

    zenity --info --text="Row inserted successfully"
}

drop_table() {
    ensure_db_connected || return 1

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$" | sed 's/\.table$//')
    [[ -z "$tables" ]] && {
        zenity --error --text="There are no tables to delete"
        return 1
    }

    table=$(zenity --list \
        --title="Drop Table" \
        --column="Table Name" \
        $(echo "$tables"))

    [[ $? -ne 0 || -z "$table" ]] && return 0

    zenity --question --text="Are you sure you want to delete table '$table'?"

    [[ $? -ne 0 ]] && return 0

    rm -f "$CURRENT_DB/$table.table"
    rm -f "$CURRENT_DB/$table.meta"

    zenity --info --text="Table deleted successfully"
}
