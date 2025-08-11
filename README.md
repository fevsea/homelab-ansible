# Homelab Ansible Configuration

This repository contains Ansible playbooks and roles for managing a homelab infrastructure with Docker containers, automated backups, and centralized configuration management.

## Project Structure

```
├── playbooks/              # Main playbooks
│   ├── site.yml            # Main site configuration
│   ├── bootstrap.yml       # New node bootstrapping
│   ├── backup.yml          # Backup operations
│   └── maintenance.yml     # System maintenance
├── roles/                  # Ansible roles
│   ├── common/             # Base system configuration
│   ├── docker/             # Docker and container management
│   └── backup/             # Backup management
├── group_vars/             # Group variables
│   ├── all/                # Variables for all hosts
│   ├── central.yml         # Central node variables
│   └── workers.yml         # Worker node variables
├── host_vars/              # Host-specific variables
└── inventory.yml           # Inventory file
```

## Quick Start

### 1. Bootstrap a New Node

Configure a fresh server with basic settings:

```bash
# Replace IP and connection details as needed
ansible-playbook -i "192.168.5.44," bootstrap.yml \
  --ask-become-pass \
  --ask-pass \
  --vault-password-file ~/.ssh/vault \
  -e "ansible_ssh_user=ubuntu" \
  -e "ip=192.168.5.44" \
  -e "gateway=192.168.5.1"
```

### 2. Deploy Infrastructure

Run the main site configuration:

```bash
ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault
```

### 3. Perform Backups

Execute backup operations:

```bash
ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault
```

### 4. System Maintenance

Run maintenance tasks:

```bash
ansible-playbook -i inventory.yml maintenance.yml --vault-password-file ~/.ssh/vault
```

## Configuration

### Inventory

The inventory is defined in `inventory.yml` with logical groups:

- **central**: Central management servers
- **workers**: Worker nodes for distributed tasks
- **amd64_workers**: x86_64 architecture workers
- **arm64_workers**: ARM64 architecture workers

### Variables

Variables are organized hierarchically:

1. **Global variables**: `group_vars/all/vars.yml`
2. **Group variables**: `group_vars/{group}/`
3. **Host variables**: `host_vars/{hostname}.yml`

### Secrets Management

Sensitive data is encrypted using Ansible Vault:

- `group_vars/all/vault`: Encrypted secrets
- `group_vars/all/secrets.yml`: Secret variable mappings

## Roles

### Common Role

Base system configuration including:
- User management and SSH keys
- Package installation and updates
- Network configuration
- NFS mount setup

### Docker Role

Container management including:
- Docker installation and configuration
- Docker Compose service deployment
- Volume management with backup restore
- Service health monitoring

### Backup Role

Automated backup system featuring:
- Docker volume backups
- System directory backups
- NFS-based backup storage
- Backup scheduling and retention

## NFS Storage

The system supports two types of NFS mounts:

1. **Permanent mounts**: Always available storage for shared data
2. **Temporary mounts**: Mounted only during backup operations

### Configuration Example

```yaml
nas:
  host: "192.168.5.15"
  homelab:
    mount_point: "/mnt/nas_homelab"
    share: "/homelab"
    options: "rw,sync,hard,intr"
  backups:
    mount_point: "/mnt/nas_backups"
    share: "/backups"
    options: "rw,sync,hard,intr"
```

## Docker Services

Services are defined in host variables with comprehensive configuration:

```yaml
docker_services:
  service_name:
    - name: "container_name"
      image: "image_name"
      tag: "version"
      ports:
        - "host:container"
      volumes:
        volume_name: "/container/path"
      env:
        ENV_VAR: "value"
      healthcheck:
        test: ["CMD", "command"]
        interval: "30s"
        timeout: "10s"
        retries: 3
```

## Security

- SSH key-based authentication
- Passwordless sudo for automation
- Encrypted secret storage with Ansible Vault
- Restricted NFS mount permissions
- Container security with proper user management

## Maintenance

Regular maintenance includes:

- System package updates
- Docker system cleanup
- Service health monitoring
- Disk usage monitoring
- Backup verification

## Troubleshooting

### Common Issues

1. **SSH Connection Issues**: Verify SSH keys and host connectivity
2. **NFS Mount Failures**: Check NFS server availability and permissions
3. **Docker Container Issues**: Review container logs and health checks
4. **Backup Failures**: Verify NFS backup mount and disk space

### Useful Commands

```bash
# Check service status
ansible all -i inventory.yml -m systemd -a "name=docker state=started"

# Verify NFS mounts
ansible all -i inventory.yml -m command -a "df -h"

# Check Docker container status
ansible all -i inventory.yml -m command -a "docker ps"

# Test connectivity
ansible all -i inventory.yml -m ping
```

## Contributing

1. Follow Ansible best practices
2. Test changes in a development environment
3. Update documentation for new features
4. Use semantic versioning for releases

## License

MIT License - see LICENSE file for details.
