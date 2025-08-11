# Backup Role

This role provides comprehensive backup management for Docker volumes and system data using NFS storage with automated cleanup and verification.

## Features

- Docker volume backup with graceful container coordination
- System directory backup with source validation
- NFS-based backup storage with proper mount handling
- Backup metadata generation and verification
- Automatic backup cleanup based on retention policy
- Backup integrity verification and reporting
- Robust error handling and recovery
- Configurable backup retention and scheduling

## Variables

### Required Variables

- `nas.backups`: NFS backup storage configuration

### Optional Variables

- `backup_enabled`: Enable system backups (default: true)
- `backup_retention_days`: Backup retention period in days (default: 30)
- `backup_directories`: Directories to backup (default: ["/etc", "/home", "/var/log"])
- `docker_backup_enabled`: Enable Docker volume backups (default: true)
- `docker_config_path`: Path to Docker Compose files (default: "/srv/docker")
- `docker_volumes_path`: Path to Docker volumes (default: "/var/docker_volumes")
- `container_stop_timeout`: Timeout for stopping containers (default: 30)
- `container_start_retries`: Retries for starting containers (default: 3)
- `backup_rsync_options`: Rsync options for backup operations

## NFS Configuration

```yaml
nas:
  host: "192.168.5.15"
  backups:
    mount_point: "/mnt/nas_backups"
    share: "/backups"
    options: "rw,sync,hard,intr"
```

## Dependencies

- common role (for NFS mount utilities)

## Example Playbook

```yaml
- hosts: all
  become: true
  roles:
    - role: backup
  vars:
    backup_enabled: true
    docker_backup_enabled: true
    backup_directories:
      - "/etc"
      - "/home"
      - "/opt/important"
```

## Tasks

### main.yml
- Validates backup configuration
- Orchestrates backup operations
- Conditionally includes Docker and system backup tasks
- Runs cleanup and verification if enabled

### docker_volumes.yml
- Gracefully stops Docker containers using docker_compose module
- Backs up Docker volumes to NFS storage with proper error handling
- Restarts containers with retry logic after backup
- Provides backup status reporting and verification

### system.yml
- Validates source directories before backup
- Backs up specified system directories with error handling
- Creates detailed backup metadata files
- Handles backup directory structure creation

### cleanup.yml
- Removes old backup directories based on retention policy
- Cleans up both system and docker backups
- Provides cleanup status reporting

### verify.yml
- Verifies backup integrity and completeness
- Creates verification reports
- Validates backup sizes and timestamps

## Backup Process

### Docker Volume Backup

1. Validate backup configuration and prerequisites
2. Mount NFS backup storage securely
3. Stop Docker containers gracefully with configurable timeout
4. Wait for complete container shutdown
5. Sync Docker volumes to backup location with verification
6. Restart Docker containers with retry logic
7. Verify backup completion and integrity
8. Unmount NFS backup storage
9. Log backup completion with status

### System Backup

1. Validate backup configuration
2. Mount NFS backup storage
3. Create host-specific backup directories
4. Verify source directories exist before backup
5. Sync existing directories to backup location
6. Generate detailed backup metadata with statistics
7. Verify backup completion
8. Unmount NFS backup storage
9. Log backup status

### Cleanup Process

1. Mount NFS backup storage
2. Find old backup directories based on retention policy
3. Remove expired backups for both system and docker
4. Log cleanup statistics
5. Unmount NFS backup storage

### Verification Process

1. Mount NFS backup storage
2. Verify system backup integrity and metadata
3. Check docker backup completeness
4. Validate backup sizes and timestamps
5. Generate verification report
6. Unmount NFS backup storage

## Backup Structure

```
/mnt/nas_backups/
├── docker/                    # Docker volume backups
│   ├── service1/
│   │   ├── volume1/
│   │   └── volume2/
│   └── service2/
└── hostname/                  # Host-specific backups
    └── system/
        ├── etc/
        ├── home/
        ├── var/log/
        └── backup_metadata.txt
```

## Integration

### With Docker Role

The backup role integrates with the Docker role to:
- Restore volumes during initial deployment
- Coordinate container shutdown/startup during backups
- Maintain service availability

### With Common Role

Uses the common role's mount utilities for:
- Temporary NFS mount management
- Proper mount point creation
- Error handling and cleanup

## Security

- Secure NFS mount handling
- Proper file permissions on backup data
- Encrypted transport (when NFS configured with security)
- Access control through group membership

## Monitoring

- Backup completion logging
- Error handling and reporting
- Backup metadata for tracking
- Integration with maintenance playbooks for monitoring

## Recovery

To restore from backup:

1. Ensure target directories are empty
2. Mount backup storage
3. Use rsync to restore data
4. Set proper permissions
5. Restart services as needed

Example restore command:
```bash
rsync -av /mnt/nas_backups/docker/service/ /var/docker_volumes/service/
```
