# Role Consistency Improvements

This document summarizes the changes made to ensure the three roles (common, docker, backup) work consistently together.

## Issues Fixed

### 1. Variable Conflicts and Inconsistencies

**Problem**: Different default values for shared variables between roles
- `timezone`: common role (UTC) vs docker role (Europe/Madrid)
- Path variables duplicated between docker and backup roles

**Solution**:
- Updated docker role to inherit `timezone` from common role with fallback to UTC
- Modified backup role to reference docker role path variables instead of duplicating them

### 2. Task Duplication

**Problem**: Duplicate system configuration tasks in common/tasks/main.yml

**Solution**:
- Removed duplicate `system.yml` import

### 3. Missing Task Includes

**Problem**: User configuration tasks not included in common role main.yml

**Solution**:
- Added user configuration task include with proper conditional

### 4. Inconsistent Validation Patterns

**Problem**: Different assertion styles across roles
- backup role used `assert:` (missing module prefix)
- docker role had no validation
- common role used proper `ansible.builtin.assert`

**Solution**:
- Standardized all roles to use `ansible.builtin.assert` with `quiet: true`
- Added validation to docker role for consistency

### 5. Inconsistent Tag Usage

**Problem**: Mixed tag formats across roles
- common role used single string tags
- other roles used list format

**Solution**:
- Standardized all roles to use list format tags
- Added role-specific prefix tags for better organization

### 6. Legacy File Cleanup

**Problem**: Unused legacy task files in docker role after refactoring

**Solution**:
- Removed unused files: `compose.yml`, `deploy_containers.yml`, `deploy.yml`, `volumes.yml`

## Role Dependencies

### Explicit Dependencies
- **backup** → **common** (declared in meta/main.yml)
- **docker** → **common** (declared in meta/main.yml)

### Variable Dependencies
- **backup** role inherits path variables from **docker** role
- **docker** role inherits `timezone` from **common** role
- All roles use **common** role for NFS mount utilities

## Standardized Patterns

### Validation
All roles now include validation blocks with:
```yaml
- name: Validate [role] configuration
  ansible.builtin.assert:
    that:
      - [required_vars]
    fail_msg: "[Role] configuration is missing or incomplete"
    quiet: true
```

### Tags
All roles now use consistent tag format:
```yaml
tags:
  - [role-name]
  - [feature-name]
```

### Error Handling
Consistent use of block/rescue/always patterns where appropriate for robust error handling.

## Configuration Consistency

### Shared Variables
- `timezone`: Defaults to UTC, can be overridden globally
- `docker_volumes_path`: Defined in docker role, referenced by backup role
- `docker_config_path`: Defined in docker role, referenced by backup role
- `nas`: Used consistently across common and backup roles for NFS operations

### Path Conventions
- Docker volumes: `/var/docker_volumes`
- Docker configs: `/srv/docker`
- Python venvs: `/srv/python_venvs`
- NAS mount points: `/mnt/nas_[share_name]`

## Testing Recommendations

1. Test role execution order: common → docker → backup
2. Verify variable inheritance works correctly
3. Test with and without optional variables
4. Validate tag-based execution (`--tags common,docker`)
5. Test error conditions and recovery scenarios

## Future Maintenance

1. Keep variable definitions in sync between roles
2. Maintain consistent validation patterns for new features  
3. Use consistent tag naming conventions
4. Document cross-role dependencies clearly
5. Regular cleanup of unused files after refactoring
