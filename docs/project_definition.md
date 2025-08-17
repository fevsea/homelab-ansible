# Ansible Homelab Project Definition

## 1. Vision & Summary
Provide a reproducible, simple, and testable Ansible automation stack to manage a heterogeneous homelab cluster consisting of a NAS (central storage), a tooling/controller node (cluster services + orchestration), a proxy/VPN edge node, and multiple heterogeneous worker mini‑PCs (mixed CPU architectures: `amd64`, `arm64`, `riscv`). The system should let me:

* Bring any new node under management quickly (baseline provisioning + role assignment).
* Express desired state declaratively & idempotently.
* Test everything locally (no‑risk dry runs + Molecule scenarios / emulation) before touching real hardware.
* Keep complexity low: minimal moving parts, prefer core Ansible features over large external frameworks.


## 4. Node Types & Roles
| Logical Role | Description | Example Functions |
|--------------|-------------|-------------------|
| `nas` | Central storage / backups; may export NFS/SMB, hold artifacts. | ZFS/btrfs mgmt, snapshot tasks, share exports. |
| `tooling` | Primary controller & shared services orchestrator (Ansible execution point). | Ansible, CI runner, monitoring stack, registry/cache. |
| `proxy` | VPN server for external acces. Acts as fallback monitor to detect issues with the tooling node | Wireguard ,  |
| `worker` | Heterogeneous compute nodes with variable capabilities. | Containers, lightweight services, build tasks, experimentation. |

Workers differ by:
* CPU Arch: `amd64`, `arm64`, `riscv` 
* Performance Traits: `high_cpu`, `low_power`, `gpu_enabled`, `high_ram`, `fast_disk`
* Constraints: `limited_ram`, `sd_storage`

## 5. Operating System Strategy
* Preferred: Ubuntu Server 24.04 LTS.
* Fallback: Debian stable when Ubuntu not available (esp. exotic architectures).
* OS abstraction handled via variables: `ansible_distribution` / `ansible_os_family` + custom `os_flavor` if needed.
* Avoid deep OS‑specific branching in roles; prefer vars files (`vars/Ubuntu.yml`, `vars/Debian.yml`) or `include_vars` patterns.

## 6. Inventory & Metadata Model
Static inventory first (YAML). Potential future dynamic layering (e.g. script or inventory plugin) is optional.

### 6.1 Proposed Inventory Group Layout
```
inventories/
	production/
		hosts.yml
	lab/               # duplicate structure for local simulation
group_vars/
	all/               # global defaults (low risk, generic)
	nas/
	tooling/
	proxy/
	workers/
	arch_amd64/
	arch_arm64/
	arch_riscv/
	capability_high_cpu/
	capability_gpu_enabled/
host_vars/
	nas01.yml
	tool01.yml
	proxy01.yml
	worker01.yml
```

### 6.2 Host Metadata (Minimal, Fact-Augmenting)
Instead of duplicating information Ansible already gathers (`ansible_hostname`, `ansible_architecture`, `ansible_distribution`, network interfaces, etc.), host vars should only supply *augmented metadata* that cannot be reliably inferred from facts or that represents desired-state intent.

Guiding principles:
* Do NOT restate architecture, distro, IPs, or storage devices unless you intentionally need to override or pin logic.
* Keep host-specific YAML lean; prefer groups for shared traits.
* Treat host vars as a sparse overlay of intent, not a full schema dump.

Recommended custom keys:
```yaml
role_primary: tooling              # Required: nas|tooling|proxy|worker
role_secondary: [monitoring]       # Optional additional logical roles
capabilities:                      # Capabilities not derivable from plain facts
	- high_cpu
	- fast_disk
feature_flags:                     # Optional toggles for experimental features
	enable_gpu_stack: false
tags: [baseline, managed]

network_iface_primary: enp3s0
```

## 7. Repository Structure (Initial Proposal)
```
ansible-flow/
	docs/                      # Documentation (this file, design notes)
	inventories/
		lab/
			hosts.yml
		production/
			hosts.yml
	playbooks/
		site.yml                 # Orchestrates high-level roles
		bootstrap.yml            # Minimal prep for new unmanaged node
		verify.yml               # Post-run validation checks
        maintenance.yml          # Run periodic tasks (cleanup, backups, updates)
	roles/
		base/                    # Common baseline: users, packages, updates
		proxy_edge/              # VPN + reverse proxy configuration
	collections/ (optional later)
	molecule/                  # Centralized or per-role scenarios (if outside roles/<role>/molecule)
	scripts/                   # Helper scripts (lint wrapper, inventory tooling)
	ci/                        # Pipeline configs (GitHub Actions, etc.)
	ansible.cfg
	requirements.yml           # Galaxy collections / roles
	pyproject.toml              # Python deps (ansible-core pin, linters) nad overall project definition
```

## 8. Playbook Strategy
* `bootstrap.yml`: Apply minimal prerequisites (Python, user, SSH keys) using `raw` where needed.
* `site.yml`: Primary convergence (ordered roles by dependency).
* `verify.yml`: Asserts final state (ports open, services running, storage mounted).
* `maintenance.yml`: Run periodic tasks (cleanup, backups, updates)

* Provide Molecule tests for each role with at least: converge, idempotence, and verify.

## 10. Testing & Local Simulation Strategy
Goal: Full validation without touching real hardware.

### 10.2 Tooling Choices
* Molecule drivers: `docker` (fast)
* Multi-arch simulation options:
	* Use Docker buildx & emulation (qemu-user-static) for basic arm



## 11. Secrets & Sensitive Data
* Start simple: Ansible Vault for small number of secrets (`group_vars/all/vault.yml`).
* `vault.yml` contains a cleartext reference to the encrypte var, that is the name of the var with "vault_" prepended (ie. admin_pub_keys: "{{ vault_admin_pub_keys }}")



## 13. Conventions & Style
* YAML: 2-space indent, no tabs, explicit booleans (`true`/`false`).
* Filenames: use underscores, no spaces.
* Variables: snake_case, avoid CamelCase.
* Handlers: prefix with role (e.g., `handler: base_restart_sshd`).
* Tags: Provide tags per role and functional area (e.g., `tags: ['base','users']`).

## 14. Idempotency & Safety
* Always test with `--check` before production run.
* Use `changed_when` / `failed_when` precisely.
* For destructive ops (partitioning, formatting): require explicit confirmation variable (e.g., `allow_disk_format: true`).
* Maintain a `DRY_RUN.md` with typical dry-run output examples (future enhancement).

## 20. Initial Action Items
* Create `ansible.cfg` with reasonable defaults (inventory path, roles_path, forks, retry_files disabled).
* Scaffold base roles (`base`, `security`, `worker_runtime`, `tooling_services`, `proxy_edge`, `storage_nas`).
* Add minimal `site.yml` referencing new roles (no-op placeholders initially).
* Add `requirements.yml` pinning `ansible.posix`, `community.general`.
* Implement Molecule in one role (`base`) as template for others.
* Add CI pipeline for lint + base role Molecule.
* Populate `inventories/lab/hosts.yml` with 2–3 representative hosts.
