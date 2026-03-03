set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

fmt:
  bash ./scripts/fmt.sh

check:
  bash ./scripts/check.sh

check-vm:
  bash ./scripts/check-vm.sh

switch host:
  bash ./scripts/switch.sh "{{host}}"
