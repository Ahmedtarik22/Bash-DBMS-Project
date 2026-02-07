#!/bin/bash
DB_ROOT="./databases"
ACTIVE_TABLE=".table"
SEP=":"

init_db(){
	if [[ -d "$DB_ROOT" ]]
	then
		return 0
	fi
	if [[ ! -e "$DB_ROOT" ]]
	then
		mkdir -p "$DB_ROOT" || {
			zenity --error --title="Error" --text="Failed to create database directory $DB_ROOT Check permissions"
			exit 1
		}
		return 0
	fi
	
	while true
	do
		choice=$(zenity --list --title="Directory conflict
        How would you like to proceed?" --text="Select an option:" --column="Select" "Abort" "Delete the existing file and create the directory" "Move the existing file to another location" --height=600 --width=550)
		
		if [[ -z "$choice" ]]; then
			exit 0
		fi

		case "$choice" in
			"Abort")
				zenity --info --title="Aborted" --text="Operation aborted"
				exit 0
				;;
			"Delete the existing file and create the directory")
				rm -f "$DB_ROOT" || {
					zenity --error --title="Error" --text="Failed to delete $DB_ROOT check permissions"
					exit 1
				}
				mkdir -p "$DB_ROOT" || {
					zenity --error --title="Error" --text="Failed to create directory after deletion"
					exit 1
				}
				zenity --info --title="Success" --text="Directory $DB_ROOT created successfully"
				return 0
				;;
			"Move the existing file to another location")
				dest=$(zenity --file-selection --directory --title="Select destination directory")
				if [ -z "$dest" ]; then
					continue
				fi
				mv "$DB_ROOT" "$dest" || {
					zenity --error --title="Error" --text="Failed to move file, check permissions"
					continue
				}
				mkdir -p "$DB_ROOT" || {
					zenity --error --title="Error" --text="Failed to create directory after move"
					exit 1
				}
				zenity --info --title="Success" --text="File moved successfully Directory $DB_ROOT created"
				return 0
				;;
			*)
				zenity --error --title="Error" --text="Invalid choice"
				;;
		esac
	done
}