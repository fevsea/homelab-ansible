# Common Role

This role provides base system configuration for all homelab hosts with improved error handling and code quality.

## Features

- User management with SSH key authentication and role-based access
- System package installation and updates with proper error handling
- Network configuration for static IP assignment with validation
- NFS mount configuration with comprehensive checks
- Basic security hardening and group management

## Variables

### Required Variables

- `ansible_user`: The automation user account
- `username`: Primary admin user account  
- `ansible_user_pub_keys`: SSH public keys for ansible user (list)
- `admin_pub_keys`: SSH public keys for admin user (list)

### Optional Variables

- `ip`: Static IP address (required for network configuration)
- `gateway`: Network gateway (required for network configuration)
- `interface`: Network interface name (auto-detected if not specified)
- `dns_servers`: List of DNS servers (default: Google DNS)
- `timezone`: System timezone (default: UTC)
- `additional_users`: List of additional users to create (default: [])
- `system_groups`: List of system groups to create (default: [software, docker])

### NAS Configuration (optional)

```yaml
nas:
  host: "192.168.1.100"
  homelab:
    mount_point: "/mnt/nas_homelab"
    share: "/homelab"
    options: "rw,sync,hard,intr"
  backups:
    mount_point: "/mnt/nas_backups"
    share: "/backups"
    options: "rw,sync,hard,intr"
```

## Dependencies

- `ansible.posix` collection (for authorized_key module)
- `ansible.utils` collection (for IP address validation)

## Example Playbook

```yaml
- hosts: all
  become: true
  vars:
    ansible_user: ansible
    username: admin
    ansible_user_pub_keys:
      - "ssh-rsa AAAAB3Nza... ansible@homelab"
    admin_pub_keys:
      - "ssh-rsa AAAAB3Nza... admin@homelab"
    ip: "192.168.1.100"
    gateway: "192.168.1.1"
  roles:
    - role: common
```

## Tasks

### main.yml
- Validates required variables
- Creates system groups
- Orchestrates all common configuration tasks

### users.yml
- Configures admin and automation users with proper role separation
- Sets up SSH key authentication with security best practices

### admin.yml
- Creates administrative users with proper permissions
- Configures SSH access and sudo privileges
- Sets up home directory structure and symbolic links

### user.yml
- Creates regular users with limited privileges
- Handles optional SSH key configuration

### packages.yml
- Updates package cache with proper timing controls
- Installs essential system packages
- Removes unnecessary packages and cleans up

### network.yml
- Validates network configuration parameters
- Configures static IP addressing with OS-specific methods
- Supports both Netplan (Ubuntu) and interfaces (Debian)
- Includes configuration validation and backup

### nfs_mounts.yml
- Sets up NFS client utilities
- Configures permanent and temporary mount points
- Handles mount permissions and validation

### mount_util.yml
- Utility for mounting/unmounting temporary NFS shares
- Includes parameter validation and error handling

## Templates

### netplan_config.yml.j2
Network configuration for Ubuntu systems using Netplan with full parameters.

### 01-main.j2
Network configuration for Debian systems using traditional interfaces.

## Handlers

### restart networking
Safely restarts networking service on Debian systems.

### apply netplan
Applies netplan configuration changes on Ubuntu systems.

## Security Features

- SSH key-based authentication only
- Conditional passwordless sudo for automation users
- Proper file permissions on SSH configurations
- Group-based access control with validation
- Password authentication disabled for automation accounts
- Configuration validation before applying changes

## Improvements Made

- Added comprehensive variable validation
- Improved error handling throughout all tasks
- Fixed logical errors in user permission management
- Eliminated code duplication
- Added proper handlers for service management
- Enhanced templates with better documentation
- Improved module usage with fully qualified names
- Added backup functionality for critical configurations
- Better separation of concerns between admin and regular users
