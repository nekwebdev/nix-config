#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 6 ]; then
  echo "usage: assistants-config-sync.sh <codex-template> <codex-config> <claude-mcp-template> <claude-mcp-json> <claude-settings-template> <claude-settings-json>" >&2
  exit 2
fi

codex_template="$1"
codex_config="$2"
claude_mcp_template="$3"
claude_mcp_config="$4"
claude_settings_template="$5"
claude_settings="$6"
dry_run="${DRY_RUN:-}"

if [ ! -f "$codex_template" ]; then
  echo "error: codex template not found: $codex_template" >&2
  exit 1
fi

if [ ! -f "$claude_mcp_template" ]; then
  echo "error: claude mcp template not found: $claude_mcp_template" >&2
  exit 1
fi

if [ ! -f "$claude_settings_template" ]; then
  echo "error: claude settings template not found: $claude_settings_template" >&2
  exit 1
fi

section_block() {
  local header="$1"
  local file="$2"

  awk -v hdr="$header" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s);
      sub(/[[:space:]]+$/, "", s);
      return s;
    }
    {
      line = trim($0);
      if (!in_section && line == hdr) {
        in_section = 1;
        print $0;
        next;
      }
      if (in_section && line ~ /^\[[^]]+\]$/) {
        exit;
      }
      if (in_section) {
        print $0;
      }
    }
  ' "$file"
}

ensure_parent_dir() {
  local file="$1"
  local dir
  dir="$(dirname "$file")"
  if [ -n "$dry_run" ]; then
    echo "Would create $dir"
  else
    mkdir -p "$dir"
  fi
}

ensure_file() {
  local file="$1"
  ensure_parent_dir "$file"
  if [ ! -f "$file" ]; then
    if [ -n "$dry_run" ]; then
      echo "Would create $file"
    else
      touch "$file"
    fi
  fi
}

append_block_if_missing() {
  local section_regex="$1"
  local block="$2"
  local file="$3"

  if [ ! -f "$file" ] || ! grep -Eq "^[[:space:]]*\\[$section_regex\\][[:space:]]*$" "$file"; then
    if [ -n "$dry_run" ]; then
      echo "Would append [$section_regex] block to $file"
    else
      printf '\n%s\n' "$block" >> "$file"
    fi
  fi
}

ensure_json_object_file() {
  local file="$1"
  ensure_parent_dir "$file"
  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    if [ -n "$dry_run" ]; then
      echo "Would create $file"
    else
      printf '{}\n' > "$file"
    fi
  fi
}

ensure_json_template_object() {
  local file="$1"
  if ! jq -e 'type == "object"' "$file" >/dev/null; then
    echo "error: template must be a JSON object: $file" >&2
    exit 1
  fi
}

sync_codex_config() {
  local block_nixos
  local block_nixos_tools
  local block_tui
  local desired_command
  local desired_args
  local desired_approval_mode
  local desired_status_line

  ensure_file "$codex_config"

  block_nixos="$(section_block "[mcp_servers.nixos]" "$codex_template")"
  block_nixos_tools="$(section_block "[mcp_servers.nixos.tools.nix]" "$codex_template")"
  block_tui="$(section_block "[tui]" "$codex_template")"

  if [ -z "$block_nixos" ] || [ -z "$block_nixos_tools" ] || [ -z "$block_tui" ]; then
    echo "error: codex template is missing one or more required sections" >&2
    exit 1
  fi

  desired_command="$(printf '%s\n' "$block_nixos" | awk '/^[[:space:]]*command[[:space:]]*=/{print; exit}')"
  desired_args="$(printf '%s\n' "$block_nixos" | awk '/^[[:space:]]*args[[:space:]]*=/{print; exit}')"
  desired_approval_mode="$(printf '%s\n' "$block_nixos_tools" | awk '/^[[:space:]]*approval_mode[[:space:]]*=/{print; exit}')"
  desired_status_line="$(printf '%s\n' "$block_tui" | awk '/^[[:space:]]*status_line[[:space:]]*=/{print; exit}')"

  append_block_if_missing 'mcp_servers\.nixos' "$block_nixos" "$codex_config"
  append_block_if_missing 'mcp_servers\.nixos\.tools\.nix' "$block_nixos_tools" "$codex_config"
  append_block_if_missing 'tui' "$block_tui" "$codex_config"

  if [ -n "$dry_run" ]; then
    echo "Would reconcile mcp/tui keys in $codex_config with $codex_template"
    return
  fi

  sed -i '/^[[:space:]]*\[mcp_servers\.nixos\][[:space:]]*$/,/^[[:space:]]*\[[^]]+\][[:space:]]*$/{/^[[:space:]]*command[[:space:]]*=.*/d;/^[[:space:]]*args[[:space:]]*=.*/d;}' "$codex_config"
  sed -i '/^[[:space:]]*\[mcp_servers\.nixos\][[:space:]]*$/a '"$desired_args"'' "$codex_config"
  sed -i '/^[[:space:]]*\[mcp_servers\.nixos\][[:space:]]*$/a '"$desired_command"'' "$codex_config"

  sed -i '/^[[:space:]]*\[mcp_servers\.nixos\.tools\.nix\][[:space:]]*$/,/^[[:space:]]*\[[^]]+\][[:space:]]*$/{/^[[:space:]]*approval_mode[[:space:]]*=.*/d;}' "$codex_config"
  sed -i '/^[[:space:]]*\[mcp_servers\.nixos\.tools\.nix\][[:space:]]*$/a '"$desired_approval_mode"'' "$codex_config"

  sed -i '/^[[:space:]]*\[tui\][[:space:]]*$/,/^[[:space:]]*\[[^]]+\][[:space:]]*$/{/^[[:space:]]*status_line[[:space:]]*=.*/d;}' "$codex_config"
  sed -i '/^[[:space:]]*\[tui\][[:space:]]*$/a '"$desired_status_line"'' "$codex_config"
}

merge_json_from_template() {
  local template="$1"
  local file="$2"
  local tmp_file

  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    if [ -n "$dry_run" ]; then
      echo "Would update $file from template $template"
      return
    fi
  fi

  tmp_file="$(mktemp)"

  jq -n \
    --slurpfile base "$file" \
    --slurpfile patch "$template" '
      def deep_merge(base; patch):
        if (base | type) == "object" and (patch | type) == "object" then
          reduce (patch | keys_unsorted[]) as $k (base;
            .[$k] = if has($k) then deep_merge(.[$k]; patch[$k]) else patch[$k] end
          )
        elif (base | type) == "array" and (patch | type) == "array" then
          if (((base + patch | map(type) | unique) - ["boolean", "number", "string"] | length) == 0)
          then (base + patch | unique)
          else patch
          end
        else
          patch
        end
      ;
      deep_merge($base[0]; $patch[0])
    ' > "$tmp_file"

  if ! cmp -s "$file" "$tmp_file"; then
    if [ -n "$dry_run" ]; then
      echo "Would update $file from template $template"
      rm -f "$tmp_file"
    else
      mv "$tmp_file" "$file"
    fi
  else
    rm -f "$tmp_file"
  fi
}

sync_claude_json() {
  local template_enabled_servers

  ensure_json_template_object "$claude_mcp_template"
  ensure_json_template_object "$claude_settings_template"

  ensure_json_object_file "$claude_mcp_config"
  merge_json_from_template "$claude_mcp_template" "$claude_mcp_config"

  ensure_json_object_file "$claude_settings"
  merge_json_from_template "$claude_settings_template" "$claude_settings"

  if [ ! -f "$claude_settings" ]; then
    return
  fi

  template_enabled_servers="$(jq -c '.enabledMcpjsonServers // []' "$claude_settings_template")"
  apply_jq_patch "$claude_settings" '
    if ($templateEnabled | type) == "array" then
      .enabledMcpjsonServers = (
        if (.enabledMcpjsonServers | type) == "array"
        then (.enabledMcpjsonServers + $templateEnabled | unique)
        else $templateEnabled
        end
      )
      | if (.disabledMcpjsonServers | type) == "array"
        then .disabledMcpjsonServers |= map(select(($templateEnabled | index(.)) == null))
        else .
        end
    else
      .
    end
  ' --argjson templateEnabled "$template_enabled_servers"
}

apply_jq_patch() {
  local file="$1"
  local filter="$2"
  shift 2
  local tmp_file
  tmp_file="$(mktemp)"

  jq "$@" "$filter" "$file" > "$tmp_file"
  if ! cmp -s "$file" "$tmp_file"; then
    if [ -n "$dry_run" ]; then
      echo "Would update $file"
      rm -f "$tmp_file"
    else
      mv "$tmp_file" "$file"
    fi
  else
    rm -f "$tmp_file"
  fi
}

sync_codex_config
sync_claude_json
