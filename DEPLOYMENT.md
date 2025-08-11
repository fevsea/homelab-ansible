# Homelab Deployment Guide

This guide provides step-by-step instructions for deploying and managing your homelab infrastructure.

## Prerequisites

### Control Machine Setup

1. **Install Ansible**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Install Ansible Collections**:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

3. **Set up SSH Keys**:
   ```bash
   # Generate SSH key for Ansible automation
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/homelab_ansible -C "homelab-ansible"
   
   # Create vault password file
   echo "your-vault-password" > ~/.ssh/vault
   chmod 600 ~/.ssh/vault
   ```

4. **Configure Ansible Vault**:
   ```bash
   # Create/edit encrypted secrets
   ansible-vault edit group_vars/all/vault
   ```

### Target Host Requirements

- Ubuntu 20.04+ or Debian 11+
- SSH access with sudo privileges
- Network connectivity to NFS server
- Sufficient disk space for containers and backups

## Deployment Process

### Phase 1: Bootstrap New Hosts

For each new host, run the bootstrap playbook:

```bash
# Replace with actual host IP and credentials
ansible-playbook -i "192.168.5.10," bootstrap.yml \
  --ask-become-pass \
  --ask-pass \
  --vault-password-file ~/.ssh/vault \
  -e "ansible_ssh_user=ubuntu" \
  -e "ip=192.168.5.10" \
  -e "gateway=192.168.5.1"
```

**What this does:**
- Creates the ansible automation user
- Sets up SSH key authentication
- Configures static IP addressing
- Installs essential packages
- Configures basic security

### Phase 2: Update Inventory

Add the new host to `inventory.yml`:

```yaml
central:
  hosts:
    new-host:
      ansible_host: 192.168.5.10
      ip: 192.168.5.10
      gateway: 192.168.5.1
      interface: eth0
```

### Phase 3: Configure Host Variables

Create host-specific variables in `host_vars/new-host.yml`:

```yaml
# Container services to deploy
containers:
  - service1
  - service2

# Service configurations
docker_services:
  service1:
    - name: "app1"
      image: "nginx"
      tag: "alpine"
      ports:
        - "80:80"
      volumes:
        app_data: "/usr/share/nginx/html"
```

### Phase 4: Deploy Infrastructure

Run the main site playbook:

```bash
# Deploy to all hosts
ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault

# Deploy to specific hosts
ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault -l tooling

# Deploy only common configuration
ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault --tags common

# Deploy only Docker services
ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault --tags docker
```

### Phase 5: Verify Deployment

1. **Check service status**:
   ```bash
   ansible all -i inventory.yml -m systemd -a "name=docker state=started" --vault-password-file ~/.ssh/vault
   ```

2. **Verify containers**:
   ```bash
   ansible all -i inventory.yml -m command -a "docker ps" --vault-password-file ~/.ssh/vault
   ```

3. **Test connectivity**:
   ```bash
   ansible all -i inventory.yml -m ping --vault-password-file ~/.ssh/vault
   ```

## Ongoing Operations

### Backup Management

#### Manual Backup
```bash
# Run full backup for all hosts
ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault

# Backup specific host
ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault -l tooling

# Docker volumes only
ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault --tags docker

# System directories only
ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault --tags system
```

#### Scheduled Backups
Set up cron job on control machine:
```bash
# Add to crontab
0 2 * * * cd /path/to/homelab-ansible && ansible-playbook -i inventory.yml backup.yml --vault-password-file ~/.ssh/vault
```

### Maintenance Operations

#### System Updates
```bash
# Run maintenance playbook
ansible-playbook -i inventory.yml maintenance.yml --vault-password-file ~/.ssh/vault

# Package updates only
ansible-playbook -i inventory.yml maintenance.yml --vault-password-file ~/.ssh/vault --tags packages

# Docker cleanup only
ansible-playbook -i inventory.yml maintenance.yml --vault-password-file ~/.ssh/vault --tags cleanup
```

#### Service Restart
```bash
# Restart Docker services
ansible-playbook -i inventory.yml maintenance.yml --vault-password-file ~/.ssh/vault --tags restart -e restart_services=true
```

### Adding New Services

1. **Update host variables** (`host_vars/hostname.yml`):
   ```yaml
   containers:
     - existing_service
     - new_service  # Add this
   
   docker_services:
     new_service:
       - name: "new_app"
         image: "app_image"
         tag: "latest"
         ports:
           - "8080:80"
         volumes:
           app_data: "/app/data"
   ```

2. **Deploy the changes**:
   ```bash
   ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault -l hostname --tags docker
   ```

### Service Updates

1. **Update image tags** in host variables
2. **Deploy updates**:
   ```bash
   ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault -l hostname --tags docker
   ```

## Troubleshooting

### Common Issues

#### SSH Connection Problems
```bash
# Test SSH connectivity
ansible all -i inventory.yml -m ping --vault-password-file ~/.ssh/vault

# Debug SSH issues
ansible all -i inventory.yml -m ping --vault-password-file ~/.ssh/vault -vvv
```

#### Docker Issues
```bash
# Check Docker status
ansible all -i inventory.yml -m systemd -a "name=docker" --vault-password-file ~/.ssh/vault

# View Docker logs
ansible hostname -i inventory.yml -m command -a "journalctl -u docker -n 50" --vault-password-file ~/.ssh/vault
```

#### NFS Mount Issues
```bash
# Check NFS mounts
ansible all -i inventory.yml -m command -a "df -h" --vault-password-file ~/.ssh/vault

# Test NFS connectivity
ansible all -i inventory.yml -m command -a "showmount -e 192.168.5.15" --vault-password-file ~/.ssh/vault
```

#### Container Problems
```bash
# Check container status
ansible hostname -i inventory.yml -m command -a "docker ps -a" --vault-password-file ~/.ssh/vault

# View container logs
ansible hostname -i inventory.yml -m command -a "docker logs container_name" --vault-password-file ~/.ssh/vault
```

### Recovery Procedures

#### Restore from Backup
1. **Stop affected services**:
   ```bash
   ansible hostname -i inventory.yml -m command -a "docker compose -f /srv/docker/service/docker-compose.yml down" --vault-password-file ~/.ssh/vault
   ```

2. **Mount backup storage and restore**:
   ```bash
   # Manual restore process
   sudo mount -t nfs 192.168.5.15:/backups /mnt/nas_backups
   sudo rsync -av /mnt/nas_backups/docker/service/ /var/docker_volumes/service/
   sudo umount /mnt/nas_backups
   ```

3. **Restart services**:
   ```bash
   ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.ssh/vault -l hostname --tags docker
   ```

## Security Considerations

### Access Control
- SSH key-based authentication only
- Ansible vault for sensitive data
- Regular key rotation
- Principle of least privilege

### Network Security
- Firewall configuration (add to common role)
- NFS security settings
- Container network isolation
- Regular security updates

### Monitoring
- Service health checks
- Backup verification
- Disk space monitoring
- Security audit logs

## Performance Optimization

### Ansible Performance
```bash
# Use SSH multiplexing
export ANSIBLE_SSH_CONTROL_PATH="/tmp/ansible-ssh-%%h-%%p-%%r"

# Parallel execution
export ANSIBLE_FORKS=10

# Fact caching
export ANSIBLE_GATHERING=smart
export ANSIBLE_FACT_CACHING=memory
```

### Docker Performance
- Resource limits in compose files
- Volume optimization
- Image cleanup automation
- Registry caching

## Best Practices

### Code Management
- Version control all configurations
- Test changes in development environment
- Use semantic versioning for releases
- Document all changes

### Operational Excellence
- Regular backup testing
- Automated health monitoring
- Capacity planning
- Disaster recovery planning

### Security
- Regular security updates
- Access audit trails
- Encrypted storage
- Network segmentation
