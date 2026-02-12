#!/bin/bash

RESERVED=(
        select insert update delete
        create drop use show
        table database where from
        join group order exit
)

validate_name() {
        local name="$1"
        if [[ -z "$name" ]]; then
                zenity --error --text="name cannot be empty"
                return 1
        fi
        if [[ "$name" =~ [[:space:]] ]]; then
                zenity --error --text="name cannot contain spaces"
                return 1
        fi

        if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                zenity --error --text="Wrong name. It must start with a letter and contain only letters, numbers, underscores"
                return 1
        fi

        for word in "${RESERVED[@]}"; do
                if [[ "${name,,}" == "$word" ]]; then
                        zenity --error --text="$name is reserved"
                        return 1
                fi
        done

        return 0
}

MAX_INT=2147483647
MAX_STRING_LENGTH=255

validate_int_value() {
        local val="$1"
        
        if ! [[ "$val" =~ ^[0-9]+$ ]]; then
                zenity --error --text="Must be a valid integer"
                return 1
        fi
        
        if [[ "$val" -gt "$MAX_INT" ]]; then
                zenity --error --text="Integer value too large. Max allowed: $MAX_INT"
                return 1
        fi
        
        return 0
}

validate_string_value() {
        local val="$1"
        
        if [[ ${#val} -gt $MAX_STRING_LENGTH ]]; then
                zenity --error --text="String too long. Max allowed: $MAX_STRING_LENGTH characters"
                return 1
        fi
        
        if [[ "$val" == *:* ]]; then
                zenity --error --text="String cannot contain ':'"
                return 1
        fi
        
        return 0
}


