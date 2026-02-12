#!/bin/bash

table_menu() {
    while true
    do
        choice=$(zenity --list --height=600 \
            --title="Tables Menu" \
            --text="Choose table operation" \
            --column="Options" \
            "List Tables" \
            "Create Table" \
            "Insert Into Table" "Update Table"\
            "Drop Table" \
            "Select From Table" \
            "Delete From Table" \
            "Back")

        [[ $? -ne 0 ]] && return 0

        case "$choice" in
            "List Tables") list_tables ;;
            "Create Table") create_table ;;
            "Insert Into Table") insert_into_table ;;
            "Update Table") update_table ;;
            "Drop Table") drop_table ;;
            "Select From Table") select_from_table ;;
            "Delete From Table") delete_from_table ;;
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
            "int" "string" "boolean")

        
        [[ $? -ne 0 ]] && return 1

        columns="$columns$col_name:"
        types="$types$col_type:"
    done

    columns="${columns%:}"
    types="${types%:}"

    col_count=$(echo "$columns" | tr ":" "\n" | wc -l)
    pk_candidates=""
    
    for (( i=1; i<=col_count; i++ )); do
        col=$(echo "$columns" | cut -d":" -f$i)
        type=$(echo "$types" | cut -d":" -f$i)
        if [[ "$type" != "boolean" ]]; then
            pk_candidates="$pk_candidates $col"
        fi
    done

    pk_candidates=$(echo "$pk_candidates" | awk '{$1=$1};1')

    if [[ -z "$pk_candidates" ]]; then
        zenity --error --text="No valid columns for primary key (boolean columns cannot be primary keys)"
        return 1
    fi

    pk=$(echo "$pk_candidates" | tr " " "\n" | zenity --list \
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
            if [[ "$type" == "boolean" ]]
            then
                val=$(zenity --list \
                    --title="Insert Value" \
                    --text="Select value for $col (boolean):" \
                    --column="Value" \
                    "true" "false")
                [[ $? -ne 0 ]] && return 0
            else
                val=$(zenity --entry \
                    --title="Insert Value" \
                    --text="Enter value for $col ($type):")
                [[ $? -ne 0 ]] && return 0
            fi

            if [[ "$type" == "int" ]]; then
                validate_int_value "$val" || continue
            fi

            if [[ "$type" == "string" ]]; then
                validate_string_value "$val" || continue
            fi

            if [[ "$col" == "$pk" ]]
            then
                pk_index=$(echo "$columns" | tr ":" "\n" | grep -n "^$pk$" | cut -d: -f1)
                if awk -F: -v idx="$pk_index" -v val="$val" '$idx == val {found=1; exit} END {exit !found}' "$data" 2>/dev/null; then
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


select_from_table() {
    ensure_db_connected || return 1

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$" | sed 's/\.table$//')
    [[ -z "$tables" ]] && {
        zenity --error --text="No tables found"
        return 1
    }

    table=$(zenity --list \
        --title="Select Table" \
        --column="Table Name" \
        $(echo "$tables"))

    [[ $? -ne 0 || -z "$table" ]] && return 0

    option=$(zenity --list \
        --title="Select Display Mode" \
        --column="Option" \
        "Display all rows" \
        "Display one row by Primary Key" \
        "Back")

    [[ $? -ne 0 || "$option" == "Back" ]] && return 0

    if [[ "$option" == "Display all rows" ]]
    then
        select_all_rows "$table"
    else
        select_one_row_by_pk "$table"
    fi
}

select_all_rows() {
    table="$1"

    meta="$CURRENT_DB/$table.meta"
    data="$CURRENT_DB/$table.table"

    columns=$(sed -n '1p' "$meta")

    if [[ ! -s "$data" ]]
    then
        zenity --info --text="Table is empty"
        return 0
    fi

    col_count=$(echo "$columns" | tr ":" "\n" | wc -l)

    zenity_cmd="zenity --list --title='Table Data' --text='Displaying all rows' --width=800 --height=400 "

    for (( i=1; i<=col_count; i++ ))
    do
        col=$(echo "$columns" | cut -d":" -f$i)
        zenity_cmd="$zenity_cmd --column='$col'"
    done

    while read line
    do
        for (( i=1; i<=col_count; i++ ))
        do
            value=$(echo "$line" | cut -d":" -f$i)
            zenity_cmd="$zenity_cmd '$value'"
        done
    done < "$data"

    eval $zenity_cmd
}


select_one_row_by_pk() {
    table="$1"

    meta="$CURRENT_DB/$table.meta"
    data="$CURRENT_DB/$table.table"

    columns=$(sed -n '1p' "$meta")
    pk=$(sed -n '3p' "$meta")

    pk_index=$(echo "$columns" | tr ":" "\n" | grep -n "^$pk$" | cut -d: -f1)

    pk_values=$(cut -d":" -f"$pk_index" "$data")

    if [[ -z "$pk_values" ]]
    then
        zenity --info --text="Table is empty"
        return 0
    fi

    selected_pk=$(zenity --list \
        --title="Select Primary Key" \
        --text="Choose a primary key value" \
        --column="$pk" \
        $(echo "$pk_values"))

    [[ $? -ne 0 || -z "$selected_pk" ]] && return 0

    row=$(awk -F: -v idx="$pk_index" -v val="$selected_pk" '$idx==val {print}' "$data")

    {
        echo "$columns"
        echo "--------------------"
        echo "$row"
    } | zenity --text-info \
        --title="Result" \
        --width=600 \
        --height=400
}

delete_from_table() {
    ensure_db_connected || return 1

    tables=$(ls "$CURRENT_DB" 2>/dev/null | grep ".table$" | sed 's/\.table$//')
    [[ -z "$tables" ]] && {
        zenity --error --text="No tables found"
        return 1
    }

    table=$(zenity --list \
        --title="Delete From Table" \
        --text="Select table" \
        --column="Table Name" \
        $(echo "$tables"))

    [[ $? -ne 0 || -z "$table" ]] && return 0

    meta="$CURRENT_DB/$table.meta"
    data="$CURRENT_DB/$table.table"

    columns=$(sed -n '1p' "$meta")
    pk=$(sed -n '3p' "$meta")

    pk_index=$(echo "$columns" | tr ":" "\n" | grep -n "^$pk$" | cut -d: -f1)

    pk_values=$(cut -d":" -f"$pk_index" "$data")

    if [[ -z "$pk_values" ]]
    then
        zenity --info --text="Table is empty"
        return 0
    fi

    selected_pk=$(zenity --list \
        --title="Delete Row" \
        --text="Select primary key to delete" \
        --column="$pk" \
        $(echo "$pk_values"))

    [[ $? -ne 0 || -z "$selected_pk" ]] && return 0

    zenity --question \
        --text="Are you sure you want to delete this record?"

    [[ $? -ne 0 ]] && return 0

    awk -F: -v idx="$pk_index" -v val="$selected_pk" '$idx != val' "$data" > "$data.tmp"
    mv "$data.tmp" "$data"

    zenity --info --text="Row deleted successfully"
}

update_table() {
    ensure_db_connected || return 1

    tables=$(find "$CURRENT_DB" -maxdepth 1 -name "*.table" -printf "%f\n" | sed 's/\.table$//')
    [[ -z "$tables" ]] && {
        zenity --error --text="No tables found"
        return 1
    }

    table=$( echo "$tables" | zenity --list --title="Update Table" --column="Table Name")

    [[ $? -ne 0 || -z "$table" ]] && return 0

    meta="$CURRENT_DB/$table.meta"
    data="$CURRENT_DB/$table.table"

    if [[ ! -s "$data" ]]; then
        zenity --error --text="Table is empty. Nothing to update."
        return 1
    fi

    columns=$(sed -n '1p' "$meta")
    types=$(sed -n '2p' "$meta")
    pk=$(sed -n '3p' "$meta")

    pk_index=$(echo "$columns" | tr ":" "\n" | grep -n "^$pk$" | cut -d":" -f1)

    pk_value=$(zenity --entry --title="Select Row" --text="Enter $pk (Primary Key) value of row to update:")

    [[ $? -ne 0 || -z "$pk_value" ]] && return 0

    row_number=$(awk -F: -v val="$pk_value" -v idx="$pk_index" ' $idx==val {print NR; exit}' "$data")

    if [[ -z "$row_number" ]]; then
        zenity --error --text="No row found with $pk = '$pk_value'"
        return 1
    fi

    current_row=$(sed -n "${row_number}p" "$data")

    update_type=$(zenity --list --title="Update Type" --text="How do you want to update?" --column="Option" "Update Entire Row" "Update Specific Columns")

    [[ $? -ne 0 || -z "$update_type" ]] && return 0

    col_count=$(echo "$columns" | tr ":" "\n" | wc -l)

    if [[ "$update_type" == "Update Entire Row" ]]; then
        new_values=""

        for (( i=1; i<=col_count; i++ )); do
            col=$(echo "$columns" | cut -d":" -f$i)
            type=$(echo "$types" | cut -d":" -f$i)
            current_val=$(echo "$current_row" | cut -d":" -f$i)

            while true; do
                if [[ "$type" == "boolean" ]]
                then
                    val=$(zenity --list --title="Update Value" --text="Select new value for $col (boolean):\nCurrent: $current_val" --column="Value" "true" "false")
                    [[ $? -ne 0 ]] && return 0
                else
                    val=$(zenity --entry --title="Update Value" --text="Enter new value for $col ($type):\nCurrent: $current_val" --entry-text="$current_val")
                    [[ $? -ne 0 ]] && return 0
                fi

                if [[ "$type" == "int" ]]; then
                    validate_int_value "$val" || continue
                fi

                if [[ "$type" == "string" ]]; then
                    validate_string_value "$val" || continue
                fi

                if [[ "$col" == "$pk" ]]; then
                    if [[ "$val" != "$pk_value" ]]; then
                        exists=$(awk -F: -v idx="$i" -v val="$val" -v row="$row_number" '$idx==val && NR!=row {print 1}' "$data")
                        if [[ -n "$exists" ]]; then
                            zenity --error --text="Primary key value already exists"
                            continue
                        fi
                    fi
                fi

                break
            done

            new_values="$new_values$val:"
        done

        new_values="${new_values%:}"
        awk -v row="$row_number" -v new="$new_values" 'NR == row { print new; next } { print }' "$data" > "$data.tmp" && mv "$data.tmp" "$data"

        zenity --info --text="Row updated successfully"
    else
        selected_cols=$(echo "$columns" | tr ":" "\n" | awk '{print "FALSE\n"$0}' | zenity --list --checklist --title="Select Columns to Update" --text="Choose columns to update:" --column="Select" --column="Column Name" --separator=":")

        [[ $? -ne 0 || -z "$selected_cols" ]] && return 0

        new_values=""

        for (( i=1; i<=col_count; i++ )); do
            col=$(echo "$columns" | cut -d":" -f$i)
            type=$(echo "$types" | cut -d":" -f$i)
            current_val=$(echo "$current_row" | cut -d":" -f$i)

            if echo "$selected_cols" | tr ":" "\n" | grep -q "^$col$"; then
                while true; do
                    if [[ "$type" == "boolean" ]]
                    then
                        val=$(zenity --list --title="Update Value" --text="Select new value for $col (boolean):\nCurrent: $current_val" --column="Value" "true" "false")
                        [[ $? -ne 0 ]] && return 0
                    else
                        val=$(zenity --entry --title="Update Value" --text="Enter new value for $col ($type):\nCurrent: $current_val" --entry-text="$current_val")
                        [[ $? -ne 0 ]] && return 0
                    fi

                    if [[ "$type" == "int" ]]; then
                        validate_int_value "$val" || continue
                    fi

                    if [[ "$type" == "string" ]]; then
                        validate_string_value "$val" || continue
                    fi

                    if [[ "$col" == "$pk" ]]; then
                        if [[ "$val" != "$pk_value" ]]; then
                            exists=$(awk -F: -v idx="$i" -v val="$val" -v row="$row_number" '$idx==val && NR!=row {print 1}' "$data")
                            if [[ -n "$exists" ]]; then
                                zenity --error --text="Primary key value already exists"
                                continue
                            fi
                        fi
                    fi

                    break
                done
                new_values="$new_values$val:"
            else
                new_values="$new_values$current_val:"
            fi
        done

        new_values="${new_values%:}"
        awk -v row="$row_number" -v new="$new_values" 'NR == row { print new; next } { print }' "$data" > "$data.tmp" && mv "$data.tmp" "$data"

        zenity --info --text="Columns updated successfully"
    fi
}