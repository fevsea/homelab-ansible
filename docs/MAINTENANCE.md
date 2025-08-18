# Enhanced Maintenance Playbook

The enhanced `maintenance.yml` playbook provides comprehensive system maintenance capabilities for homelab infrastructure.

## Features

### Package Management
- Updates package caches for Debian/Ubuntu and RedHat/CentOS systems
- Applies security updates (when enabled)
- Cleans package caches and removes unnecessary packages
- Supports both apt and yum package managers

### Docker Cleanup
- Removes unused Docker images
- Removes stopped containers
- Removes unused volumes
- Removes unused networks
- Shows space reclaimed for each operation

### Log Management
- Cleans systemd journal logs older than specified retention period
- Removes old compressed log files from /var/log
- Shows cleanup results

### System Health Monitoring
- Monitors disk usage with configurable warning thresholds
- Checks memory usage
- Identifies failed services
- Provides comprehensive health summary
- Alerts on critical disk usage

### Service Management
- Optionally restarts services like Docker
- Reloads systemd daemon

## Usage

### Run Full Maintenance
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault
```

### Package Updates Only
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags packages
```

### Docker Cleanup Only
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags cleanup,docker
```

### Health Checks Only
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags health,monitoring
```

### Log Cleanup Only
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags cleanup,logs
```

### Service Restart (with Docker restart)
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags restart -e restart_services=true
```

### Security Updates
```bash
ansible-playbook -i inventory.yml playbooks/maintenance.yml --vault-password-file ~/.ssh/vault --tags security -e maintenance_apply_security_updates=true
```

## Configuration Variables

### Main Control Variables
- `maintenance_update_packages: true` - Enable package management
- `maintenance_apply_security_updates: false` - Apply security updates
- `maintenance_docker_cleanup: true` - Enable Docker cleanup
- `maintenance_log_cleanup: true` - Enable log cleanup
- `maintenance_check_disk_space: true` - Enable health monitoring
- `maintenance_restart_services: false` - Enable service restarts

### Health Monitoring
- `disk_usage_warning_threshold: 80` - Disk usage warning threshold (%)
- `disk_usage_critical_threshold: 90` - Disk usage critical threshold (%)

### Log Management
- `log_retention_days: 30` - Log retention period in days

## Available Tags

- `packages` - Package management tasks
- `security` - Security update tasks
- `cleanup` - All cleanup tasks
- `docker` - Docker-specific operations
- `logs` - Log cleanup operations
- `health` - Health monitoring tasks
- `monitoring` - System monitoring tasks
- `restart` - Service restart tasks
- `services` - Service management tasks
- `maintenance` - All maintenance tasks

## Error Handling

The playbook includes comprehensive error handling with rescue blocks that will log failures but continue with other maintenance tasks. This ensures that a failure in one area doesn't prevent other maintenance operations from completing.

## Safety Features

- All tasks are designed to be idempotent and safe to run repeatedly
- Uses check mode compatible operations where possible
- Provides detailed output showing what was done
- Includes warnings and alerts for critical conditions
- Graceful handling of missing components (e.g., Docker not installed)