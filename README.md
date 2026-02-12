# Bash DBMS

A lightweight Database Management System built entirely in Bash with a graphical user interface using Zenity.

## Overview

This project implements a simple yet functional DBMS that allows users to create and manage databases and tables through an intuitive GUI. It supports basic CRUD operations (Create, Read, Update, Delete) and enforces data integrity through primary keys and type validation.

## Features

### Database Operations

- **Create Database**: Create new databases with validation
- **Connect to Database**: Select and connect to existing databases
- **List Databases**: View all available databases
- **Drop Database**: Delete databases with confirmation prompts

### Table Operations

- **Create Table**: Define tables with custom columns and data types
- **List Tables**: View all tables in the current database
- **Insert Records**: Add new rows with type validation
- **Select Records**:
  - Display all rows in a table
  - Query specific rows by primary key
- **Update Records**:
  - Update entire rows
  - Update specific columns selectively
- **Delete Records**: Remove rows by primary key
- **Drop Table**: Delete tables with confirmation

### Data Types

- **int**: Integer values (max: 2,147,483,647)
- **string**: Text values (max: 255 characters, cannot contain `:`)
- **boolean**: True/false values

### Data Integrity

- Primary key constraints (unique values enforced)
- Type validation for all columns
- Reserved keyword protection
- Name validation (alphanumeric + underscore, must start with letter)

## Prerequisites

- Bash shell (version 4.0 or higher recommended)
- Zenity (for GUI dialogs)

### Installing Zenity

**Ubuntu/Debian:**

```bash
sudo apt-get install zenity
```

**Fedora/RHEL:**

```bash
sudo dnf install zenity
```

**macOS:**

```bash
brew install zenity
```

## Installation

1. Clone or download the project files
2. Ensure all scripts have execute permissions:

```bash
chmod +x dbms.sh config.sh database.sh table.sh validation.sh
```

## Usage

### Starting the DBMS

Run the main script:

```bash
./dbms.sh
```

### Workflow

1. **First Time Setup**: The system automatically creates a `./databases` directory
2. **Create a Database**: Use "Create DB" from the main menu
3. **Connect to Database**: Select "Connect To DB" and choose your database
4. **Create Tables**: Define table structure with columns and data types
5. **Perform Operations**: Insert, select, update, or delete data

### Example Workflow

```
1. Start dbms.sh
2. Select "Create DB" → Enter "employees"
3. Select "Connect To DB" → Choose "employees"
4. Select "Create Table" → Enter "staff"
5. Define 3 columns:
   - id (int) - set as primary key
   - name (string)
   - active (boolean)
6. Insert records with validated data
7. Query and manage your data
```

## Project Structure

```
.
├── dbms.sh           # Main entry point and menu system
├── config.sh         # Configuration and initialization
├── database.sh       # Database-level operations
├── table.sh          # Table-level operations (CRUD)
├── validation.sh     # Input validation and constraints
└── databases/        # Storage directory (auto-created)
    └── [db_name]/    # Individual database directories
        ├── [table].table  # Table data files
        └── [table].meta   # Table metadata files
```

## File Format

### Metadata Files (.meta)

```
column1:column2:column3
type1:type2:type3
primary_key_column
```

### Data Files (.table)

```
value1:value2:value3
value1:value2:value3
```

## Validation Rules

### Names (Databases, Tables, Columns)

- Must start with a letter
- Can contain letters, numbers, and underscores
- Cannot contain spaces
- Cannot be reserved keywords

### Reserved Keywords

```
select, insert, update, delete, create, drop, use, show,
table, database, where, from, join, group, order, exit
```

### Data Types

- **int**: Positive integers only, max value 2,147,483,647
- **string**: Max 255 characters, cannot contain `:`
- **boolean**: Must be `true` or `false`
