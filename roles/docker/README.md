# Docker Role

This role manages Docker installation and container orchestration for homelab services.

## Recent Refactoring (2025)

The role has been significantly refactored to improve code quality and reduce complexity:

### Bug Fixes
- Fixed syntactical errors (typos, deprecated modules, file type declarations)
- Corrected semantic errors (variable inconsistencies, logic issues)
- Improved error handling and validation
- Replaced deprecated `apt_key` module with `get_url`

### Code Quality Improvements
- **Reduced complexity**: Consolidated 4+ task files into 2 main files
- **Eliminated deep call stacks**: Removed nested `include_tasks` chains
- **Consistent naming**: Standardized variable names and YAML structure
- **Better error handling**: Added retries, proper conditionals, and validation
- **Security improvements**: Better permission handling and validation

### Architecture Changes
- Consolidated `deploy_containers.yml`, `compose.yml`, `volumes.yml`, and `deploy.yml` into single `deploy_service.yml`
- Simplified main task flow: `main.yml` → `install.yml` OR `deploy_service.yml`
- Reduced from 6 task files to 3 task files
- Improved template safety with better conditionals and defaults

## Features

- Docker and Docker Compose installation with proper error handling
- Container service deployment via Docker Compose (module driven)
- Volume management with optional backup restore capability
- Simplified service status reporting
- Better retry logic and failure handling

## Variables

### Required Variables

- `containers`: List of container service names to deploy (can be empty)
- `docker_services`: Dictionary defining container configurations

### Optional Variables

- `docker_enabled`: Boolean to enable/disable Docker install logic (default: true)
- `docker_volumes_path`: Path for persistent volumes (default: /var/docker_volumes)
- `docker_config_path`: Path for Docker Compose files (default: /srv/docker)
- `python_system_venvs_path`: Path for Python virtual environments (default: /opt/python_venvs)
- `timezone`: Timezone for containers (default: Europe/Madrid)

## Docker Services Configuration

Services are defined in the `docker_services` variable as follows:

```yaml
docker_services:
  service_name:
    - name: "container_name"
      image: "image_name"
      tag: "version"  # defaults to 'latest' if not specified
      ports:
        - "host_port:container_port"
      volumes:
        volume_name: "/container/mount/path"
      env:
        ENV_VARIABLE: "value"
      healthcheck:
        test: ["CMD", "health_command"]
        interval: "30s"
        timeout: "10s"
        retries: 3
      depends_on:
        - other_service
      networks:
        - network_name
```

## Dependencies

- common role (for base system configuration)

## Example Playbook

```yaml
- hosts: docker_hosts
  become: true
  roles:
    - role: docker
  vars:
    containers:
      - mongodb
      - nginx
    docker_services:
      mongodb:
        - name: "mongodb"
          image: "mongo"
          tag: "5.0"
          ports:
            - "27017:27017"
          volumes:
            mongodb_data: "/data/db"
          env:
            MONGO_INITDB_ROOT_USERNAME: "admin"
            MONGO_INITDB_ROOT_PASSWORD: "{{ vault_mongo_password }}"
```

## Tasks Overview

- `main.yml`: Orchestrates install (if enabled) and deployment
- `install.yml`: Installs Docker CE and related packages, sets up Python venv
- `deploy_service.yml`: Handles complete service deployment including volumes, backup restore, and Docker Compose deployment

## Volume Management

- Creates volume directories with proper permissions
- Optionally restores data for empty volumes from NFS backup share
- Improved error handling for backup operations

## Security Improvements

- Proper Docker group management for non-root access
- Controlled restore operations with validation
- Better permission handling throughout
- Input validation and error checking
