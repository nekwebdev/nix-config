set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

fmt:
  bash ./scripts/fmt.sh

check:
  bash ./scripts/check.sh

check-vm:
  bash ./scripts/check-vm.sh

switch host:
  bash ./scripts/switch.sh "{{host}}"

new-user user:
  bash ./scripts/new-user.sh "{{user}}"

new-host host user='bob':
  bash ./scripts/new-host.sh "{{host}}" "{{user}}"
