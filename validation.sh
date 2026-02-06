#!/bin/bash
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

        return 0
}

