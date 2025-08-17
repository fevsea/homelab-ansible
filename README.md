# ansible-flow

Infrastructure-as-code for a heterogeneous homelab (NAS, tooling controller, proxy/VPN edge, and mixed-architecture workers). See `docs/project_definition.md` for the full architectural overview.

## Quick Start (uv-based)
```bash
# install deps including dev extras (molecule, lint, etc.)
uv sync --extra dev
uv run ansible-galaxy collection install -r requirements.yml
uv run molecule test -s smoke
```