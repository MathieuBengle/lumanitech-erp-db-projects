# Documentation Directory

This directory contains comprehensive documentation for the Lumanitech ERP Projects database.

## Contents

- **`DATABASE_DESIGN.md`** - Database design principles and architecture decisions
- **`DATA_DICTIONARY.md`** - Detailed description of all tables and columns
- **`ERD.md`** - Entity-Relationship Diagram and relationships documentation

## Overview

The Projects database is designed to manage project information, tasks, and team assignments within the Lumanitech ERP system.

## Quick Reference

### Core Tables

1. **projects** - Main project records
2. **tasks** - Individual tasks within projects
3. **project_members** - Team member assignments and roles

### Key Relationships

- Projects have many Tasks (one-to-many)
- Projects have many Project Members (one-to-many)
- Tasks belong to one Project (many-to-one)

## Database Principles

### Character Set

All tables use `utf8mb4` character set with `utf8mb4_unicode_ci` collation to support:
- International characters
- Emojis
- Full Unicode support

### Timestamps

Standard timestamp columns on all tables:
- `created_at` - When the record was created
- `updated_at` - When the record was last modified

### Audit Fields

Where applicable, tables include:
- `created_by` - User ID who created the record
- `updated_by` - User ID who last updated the record

### Indexing Strategy

Indexes are created on:
- Foreign key columns
- Frequently queried columns (status, dates)
- Columns used in WHERE clauses
- Unique constraints for business keys

## Design Decisions

### Why separate tables for tasks and project members?

- **Flexibility**: Tasks and members have different lifecycles
- **Scalability**: Can grow independently
- **Integrity**: Better foreign key constraints and cascading deletes
- **Querying**: More efficient queries for specific needs

### Why ENUM for status fields?

- **Performance**: Stored as integers, faster comparisons
- **Validation**: Database-level validation of allowed values
- **Clarity**: Self-documenting valid states
- **Trade-off**: Schema changes required to add new values

### Why BIGINT UNSIGNED for IDs?

- **Scale**: Supports up to 18,446,744,073,709,551,615 records
- **Future-proof**: Won't need to change ID types later
- **Standard**: Consistent with modern practices

## Maintenance

This documentation should be updated whenever:
- New tables are added
- Table structures change
- New relationships are created
- Design decisions are made

## See Also

- `/schema` - Current database schema SQL
- `/migrations` - Version-controlled schema changes
- Root `README.md` - Project overview and guidelines
