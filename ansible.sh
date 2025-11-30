#!/usr/bin/env bash
# Wrapper script that activates venv and runs ansible commands
# Usage: ./ansible.sh <command> [args...]
#
# Examples:
#   ./ansible.sh ansible --version
#   ./ansible.sh ansible all -m ping
#   ./ansible.sh ansible-playbook playbooks/site.yml --check

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

if [[ ! -d "${VENV_DIR}" ]]; then
    echo "Virtual environment not found. Run ./install_ansible first."
    exit 1
fi

source "${VENV_DIR}/bin/activate"
exec "$@"
