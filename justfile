set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

fmt:
  bash ./scripts/fmt.sh

check:
  bash ./scripts/check.sh

check-vm:
  bash ./scripts/check-vm.sh

switch host:
  bash ./scripts/switch.sh "{{host}}"

new-user user sops_key_path='':
  SOPS_KEY_PATH="{{sops_key_path}}" bash ./scripts/new-user.sh "{{user}}" "{{sops_key_path}}"

new-host host user='bob' sops_key_path='':
  bash ./scripts/new-host.sh "{{host}}" "{{user}}" "{{sops_key_path}}"

sops-user-password user='oj' secret='secrets/users.yaml' recipients_file='':
  bash ./scripts/sops-user-password.sh "{{user}}" "{{secret}}" "{{recipients_file}}"
