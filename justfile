set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

fmt:
    @echo "==> Formatting"
    @bash ./scripts/fmt.sh

check:
    @echo "==> Running checks"
    @bash ./scripts/check.sh

check-vm:
    @echo "==> Running VM checks"
    @bash ./scripts/check-vm.sh

update:
    @echo "==> Updating flake inputs"
    @bash ./scripts/update.sh

switch host='':
    @echo "==> Switching configuration"
    @bash ./scripts/switch.sh "{{ host }}"

config-update:
    @echo "==> Syncing runtime desktop config back to repo"
    @bash ./scripts/config-update.sh

new-user user sops_key_path='':
    @echo "==> Creating user scaffold: {{ user }}"
    @SOPS_KEY_PATH="{{ sops_key_path }}" bash ./scripts/new-user.sh "{{ user }}" "{{ sops_key_path }}"

new-host host user sops_key_path='':
    @echo "==> Creating host scaffold: {{ host }} (user: {{ user }})"
    @bash ./scripts/new-host.sh "{{ host }}" "{{ user }}" "{{ sops_key_path }}"

sops-user-password user recipients_file='':
    @echo "==> Encrypting user password: {{ user }}"
    @bash ./scripts/sops-user-password.sh "{{ user }}" "{{ recipients_file }}"
