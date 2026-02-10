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

