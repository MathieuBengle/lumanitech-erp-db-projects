# Database Design Document

## Overview

This document outlines the design principles, architectural decisions, and rationale behind the Lumanitech ERP Projects database schema.

## Design Goals

1. **Simplicity**: Keep the schema simple and understandable
2. **Scalability**: Support growth in data volume and user base
3. **Performance**: Optimize for common query patterns
4. **Maintainability**: Easy to modify and extend
5. **Data Integrity**: Ensure data consistency and validity
6. **API-First**: Designed to be accessed primarily through the Projects API

## Core Principles

### 1. Database Ownership

**The Projects API owns this database.**

- All schema changes must go through the Projects API team
- Other services access project data only via the Projects API
- Direct database access by other services is prohibited
- This ensures data integrity and allows for schema evolution

### 2. Forward-Only Migrations

- Migrations are never modified after being deployed
- All changes are made through new migrations
- This provides a clear audit trail and prevents conflicts
- See `/migrations/README.md` for details

### 3. Idempotent Operations

- Migrations should be safe to run multiple times
- Use `IF NOT EXISTS` and similar constructs
- Prevents failures during re-runs or rollbacks

### 4. Explicit Naming Conventions

Clear, consistent naming makes the schema self-documenting:

- **Tables**: Plural nouns (e.g., `projects`, `tasks`)
- **Columns**: Snake_case (e.g., `created_at`, `project_id`)
- **Foreign Keys**: `fk_{child_table}_{parent_table}`
- **Indexes**: `idx_{column_name}` or `idx_{purpose}`
- **Unique Constraints**: `uk_{column_name}`

## Architectural Decisions

### Decision 1: MySQL as Database Engine

**Rationale**:
- Wide industry adoption and support
- Excellent performance for read-heavy workloads
- Strong ACID compliance
- Good tooling and ecosystem
- Team familiarity

**Trade-offs**:
- Less flexible than NoSQL for unstructured data
- Vertical scaling limits
- More complex for geographically distributed systems

### Decision 2: InnoDB Storage Engine

**Rationale**:
- ACID compliance with transaction support
- Row-level locking for better concurrency
- Foreign key constraint support
- Crash recovery capabilities
- Default and recommended for MySQL

**Alternative Considered**: MyISAM
- Rejected due to lack of transaction support and foreign keys

### Decision 3: BIGINT UNSIGNED for Primary Keys

**Rationale**:
- Maximum range: 0 to 18.4 quintillion
- Future-proof for massive scale
- No risk of ID exhaustion
- Consistent across all tables
- 8 bytes per ID

**Alternative Considered**: INT UNSIGNED (4 bytes)
- Rejected due to limit of ~4.2 billion records

### Decision 4: utf8mb4 Character Set

**Rationale**:
- Full Unicode support including emojis
- 4-byte character support
- International character compatibility
- Standard for modern applications

**Alternative Considered**: utf8 (3-byte)
- Rejected due to incomplete Unicode support

### Decision 5: ENUM for Status and Priority Fields

**Rationale**:
- Database-level validation of values
- Storage efficiency (stored as integers)
- Self-documenting allowed values
- Fast comparisons and indexes

**Trade-offs**:
- Schema changes required to add new values
- Less flexible than VARCHAR with app-level validation
- Careful migration planning needed for value changes

**Alternative Considered**: VARCHAR with check constraints
- Rejected due to less efficient storage and queries

### Decision 6: Separate Tables for Tasks and Members

**Rationale**:
- Single Responsibility Principle
- Independent lifecycle management
- Better query performance for specific needs
- Clearer foreign key relationships
- Easier to extend independently

**Alternative Considered**: Denormalized into projects table
- Rejected due to data redundancy and update anomalies

### Decision 7: Cascade Delete for Child Tables

**Rationale**:
- Automatic cleanup prevents orphaned records
- Ensures referential integrity
- Simpler application code
- Aligned with business logic (tasks/members belong to projects)

**Trade-offs**:
- Must be careful when deleting projects
- Consider soft deletes for important data
- May need additional safeguards in application

### Decision 8: Logical Foreign Keys for User References

**Rationale**:
- Users managed by separate User service
- Avoids tight coupling between databases
- Allows independent scaling of services
- Simplifies user service changes

**Trade-offs**:
- No database-level referential integrity for users
- Application must validate user IDs
- Potential for orphaned references if user deleted
- Requires coordination between services

### Decision 9: Composite Unique Key for Task Codes

**Rationale**:
- Task codes should be unique within each project
- Allows simple codes like "TASK-001" per project
- Business-friendly identifiers
- Supports project-level organization

**Alternative Considered**: Global unique task codes
- Rejected as unnecessarily complex and less user-friendly

### Decision 10: Decimal for Currency and Hours

**Rationale**:
- Exact precision for financial calculations
- No floating-point rounding errors
- Industry standard for currency
- Predictable behavior

**Alternative Considered**: FLOAT/DOUBLE
- Rejected due to rounding errors and precision loss

## Schema Design Patterns

### Timestamp Tracking

All tables include:
```sql
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

**Purpose**: Audit trail and temporal queries

### Audit Fields

Most tables include:
```sql
created_by BIGINT UNSIGNED
updated_by BIGINT UNSIGNED
```

**Purpose**: Track which user made changes

### Soft Delete Support (Future)

Currently not implemented, but structure supports adding:
```sql
deleted_at TIMESTAMP NULL
deleted_by BIGINT UNSIGNED
```

**Use Case**: Preserve historical records, undo deletions

## Indexing Strategy

### Primary Indexes

- Every table has a single-column `id` as primary key
- Auto-incrementing BIGINT UNSIGNED
- Clustered index in InnoDB

### Unique Indexes

- Business keys (e.g., `project_code`)
- Composite keys preventing duplicates (e.g., `project_id, task_code`)

### Secondary Indexes

Created on columns that are:
- Frequently used in WHERE clauses
- Used in JOIN conditions
- Used in ORDER BY clauses
- High cardinality (many distinct values)

### Composite Indexes

- `(start_date, end_date)` on projects for date range queries
- `(project_id, user_id)` on project_members

### Index Maintenance

- Monitor index usage with MySQL performance schema
- Remove unused indexes
- Update statistics regularly
- Consider covering indexes for frequent queries

## Data Validation

### Database-Level Validation

- NOT NULL constraints
- UNIQUE constraints
- Foreign key constraints
- ENUM value restrictions
- CHECK constraints (MySQL 8.0+)

### Application-Level Validation

- Business rule validation
- Cross-field validation
- User ID existence
- Date logic (end_date >= start_date)
- Complex constraints

## Scalability Considerations

### Current Scale Support

- Millions of projects
- Tens of millions of tasks
- Hundreds of millions of member assignments

### Scaling Strategies

**Vertical Scaling**:
- Increase server resources (RAM, CPU, storage)
- Optimize queries and indexes
- Use query caching

**Horizontal Scaling**:
- Read replicas for read-heavy workloads
- Sharding by project ID if needed
- Caching layer (Redis, Memcached)

**Data Archival**:
- Move completed/old projects to archive tables
- Partition tables by date
- Implement data retention policies

## Security Considerations

### Access Control

- Database credentials stored securely (environment variables, secrets management)
- Principle of least privilege for database users
- Separate credentials for read-only operations

### Data Privacy

- No personally identifiable information (PII) stored directly
- User data managed by User service
- Audit logs for sensitive operations

### SQL Injection Prevention

- Parameterized queries in application code
- No dynamic SQL with user input
- ORM/query builder usage encouraged

## Performance Optimization

### Query Optimization

- Use EXPLAIN to analyze queries
- Avoid SELECT *
- Use appropriate indexes
- Limit result sets
- Use JOIN instead of subqueries where appropriate

### Caching Strategy

- Application-level caching for frequently accessed data
- Redis for session and temporary data
- Query result caching for expensive queries
- Cache invalidation on updates

### Connection Pooling

- Connection pools in application layer
- Reuse connections to reduce overhead
- Configure appropriate pool sizes

## Monitoring and Maintenance

### What to Monitor

- Query performance (slow query log)
- Index usage and efficiency
- Table sizes and growth rates
- Connection pool usage
- Lock contention
- Replication lag (if applicable)

### Regular Maintenance

- Analyze and optimize tables
- Update statistics
- Review and optimize indexes
- Archive old data
- Backup and restore testing

## Disaster Recovery

### Backup Strategy

- Daily full backups
- Incremental backups throughout the day
- Point-in-time recovery capability
- Test restoration procedures regularly
- Store backups in multiple locations

### Recovery Plan

1. Identify scope of data loss
2. Restore from most recent backup
3. Apply incremental backups
4. Verify data integrity
5. Test application functionality
6. Document incident and lessons learned

## Migration Best Practices

### Before Migration

- Backup database
- Test on development/staging environment
- Review migration script
- Estimate downtime
- Prepare rollback plan

### During Migration

- Use transactions where possible
- Monitor progress
- Watch for locks and contention
- Have DBA on standby

### After Migration

- Verify migration success
- Check application functionality
- Monitor performance
- Update documentation

## Future Enhancements

### Planned Features

1. **Soft Deletes**: Add deleted_at columns for recovery
2. **Audit Logging**: Comprehensive change tracking
3. **Time Tracking**: Detailed time entry system
4. **Task Dependencies**: Task relationship management
5. **Project Templates**: Reusable project structures

### Potential Optimizations

1. **Partitioning**: Partition large tables by date
2. **Materialized Views**: Pre-computed aggregations
3. **Full-Text Search**: Better text search capabilities
4. **JSON Columns**: Flexible metadata storage

## Conclusion

This database design balances simplicity, performance, and scalability while maintaining data integrity and supporting the needs of the Projects API. The forward-only migration strategy ensures safe schema evolution, and the clear separation of concerns allows for independent service scaling.

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-21  
**Schema Version**: V003  
**Maintained By**: Projects API Team
