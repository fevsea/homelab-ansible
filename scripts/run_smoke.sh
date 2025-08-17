#!/usr/bin/env bash
set -euo pipefail

INV=${1:-inventories/lab/hosts.yml}

echo "[SMOKE] Running inventory schema tests (pytest)"
pytest -q tests/test_inventory_schema.py

echo "[SMOKE] Running Ansible smoke play (check mode)"
ansible-playbook -i "$INV" playbooks/smoke_lab.yml --check

echo "[SMOKE] Running Ansible smoke play (actual)"
ansible-playbook -i "$INV" playbooks/smoke_lab.yml

echo "[SMOKE] Completed successfully"
