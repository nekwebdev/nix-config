set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

help:
    @bash ./scripts/help.sh

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

new-user user:
    @echo "==> Creating user scaffold: {{ user }}"
    @bash ./scripts/new-user.sh "{{ user }}"

new-host host user:
    @echo "==> Creating host scaffold: {{ host }} (user: {{ user }})"
    @bash ./scripts/new-host.sh "{{ host }}" "{{ user }}"

sops-decrypt-env file='.env.sops':
    @echo "==> Decrypting {{ file }} in place"
    @bash ./scripts/sops-decrypt-in-place.sh "{{ file }}"

sops-encrypt-env file='.env':
    @echo "==> Encrypting {{ file }} in place"
    @bash ./scripts/sops-encrypt-in-place.sh "{{ file }}"
