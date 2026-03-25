{...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    mkCommand = name: text:
      pkgs.writeShellScriptBin name ''
        set -euo pipefail
        ${text}
      '';

    rustTools = [
      pkgs.cargo
      pkgs.cargo-watch
      pkgs.clippy
      pkgs.cmake
      pkgs.openssl
      pkgs.pkg-config
      pkgs.python3
      pkgs.rust-analyzer
      pkgs.rustc
      pkgs.rustfmt
    ];

    rustCommands = [
      (mkCommand "check" ''exec cargo check "$@"'')
      (mkCommand "test" ''exec cargo test "$@"'')
      (mkCommand "fmt" ''exec cargo fmt "$@"'')
      (mkCommand "lint" ''exec cargo clippy -- -D warnings'')
      (mkCommand "run" ''exec cargo run "$@"'')
      (mkCommand "watch" ''exec cargo watch -x check -x test'')
      (mkCommand "doc" ''exec cargo doc --open'')
      (mkCommand "rust-info" ''
        echo "=== Rust Development Shell ==="
        echo "Purpose: self-contained Rust environment for repo or package work"
        echo ""
        echo "Available commands:"
        echo "  check        - Type-check code"
        echo "  test         - Run tests"
        echo "  fmt          - Format code"
        echo "  lint         - Run clippy with warnings as errors"
        echo "  run          - Build and run"
        echo "  watch        - Auto check and test on file changes"
        echo "  doc          - Build and open documentation"
        echo "  rust-info    - Show this information"
        echo ""
        echo "Toolchain:"
        echo "  Rust: $(rustc --version)"
        echo "  Cargo: $(cargo --version)"
        echo "  Clippy: $(cargo clippy --version | head -1)"
        echo "  rust-analyzer: $(rust-analyzer --version | head -1)"
      '')
    ];

    rustShell = pkgs.mkShellNoCC {
      name = "rust";
      packages = rustTools ++ rustCommands;
    };
  in {
    devShells = {
      rust = rustShell;
      default = lib.mkDefault rustShell;
    };
  };
}
