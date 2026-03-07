{
  flake.nixosModules.policy = {
    lib,
    pkgs,
    config,
    ...
  }: let
    trim = lib.strings.trim;

    nordvpnProfileDir = ../../../configs/users/oj/common/nordvpn;
    hasNordvpnProfileDir = builtins.pathExists nordvpnProfileDir;
    nordvpnSecretFile = ../../../secrets/vpn.yaml;
    hasNordvpnSecretFile = builtins.pathExists nordvpnSecretFile;

    mkDeterministicUuid = seed: let
      hash = builtins.hashString "sha1" seed;
    in "${lib.substring 0 8 hash}-${lib.substring 8 4 hash}-${lib.substring 12 4 hash}-${lib.substring 16 4 hash}-${lib.substring 20 12 hash}";

    getDirectiveValue = directive: lines: let
      prefix = "${directive} ";
      matched = lib.findFirst (line: lib.hasPrefix prefix (trim line)) null lines;
      rawValue =
        if matched == null
        then null
        else trim (lib.removePrefix prefix (trim matched));
    in
      if rawValue == null
      then null
      else lib.concatStringsSep " " (lib.filter (part: part != "") (lib.splitString " " rawValue));

    hasDirective = directive: lines: lib.any (line: trim line == directive) lines;

    extractInlineBlock = tag: content: let
      startTag = "<${tag}>";
      endTag = "</${tag}>";
      startSplit = lib.splitString startTag content;
    in
      if builtins.length startSplit < 2
      then null
      else let
        afterStart = builtins.elemAt startSplit 1;
        endSplit = lib.splitString endTag afterStart;
      in
        if builtins.length endSplit < 2
        then null
        else trim (builtins.elemAt endSplit 0);

    formatRemote = remoteDirective:
      if remoteDirective == null
      then null
      else let
        parts = lib.filter (part: part != "") (lib.splitString " " remoteDirective);
      in
        if builtins.length parts >= 2
        then "${builtins.elemAt parts 0}:${builtins.elemAt parts 1}"
        else null;

    mkParsedNordvpnProfile = fileName: let
      profileId = lib.removeSuffix ".ovpn" fileName;
      ovpnPath = nordvpnProfileDir + "/${fileName}";
      ovpnText = builtins.readFile ovpnPath;
      lines = lib.splitString "\n" ovpnText;

      remoteValue = formatRemote (getDirectiveValue "remote" lines);
      verifyRaw = getDirectiveValue "verify-x509-name" lines;
      verifyValue =
        if verifyRaw == null
        then null
        else if lib.hasPrefix "subject:" verifyRaw
        then verifyRaw
        else "subject:${verifyRaw}";
      protoValue = getDirectiveValue "proto" lines;
      compLzoRaw = getDirectiveValue "comp-lzo" lines;
      compLzoValue =
        if compLzoRaw == "no"
        then "no-by-default"
        else compLzoRaw;
      keyDirection = getDirectiveValue "key-direction" lines;
      hasAuthUserPass = hasDirective "auth-user-pass" lines;

      caInline = extractInlineBlock "ca" ovpnText;
      tlsAuthInline = extractInlineBlock "tls-auth" ovpnText;
      caFile =
        if caInline == null
        then null
        else pkgs.writeText "${profileId}-ca.pem" "${caInline}\n";
      tlsAuthFile =
        if tlsAuthInline == null
        then null
        else pkgs.writeText "${profileId}-tls-auth.pem" "${tlsAuthInline}\n";

      missingRequirements = lib.filter (item: item != null) [
        (
          if remoteValue == null
          then "remote <host> <port>"
          else null
        )
        (
          if caInline == null
          then "<ca>...</ca>"
          else null
        )
        (
          if tlsAuthInline == null
          then "<tls-auth>...</tls-auth>"
          else null
        )
        (
          if !hasAuthUserPass
          then "auth-user-pass"
          else null
        )
      ];

      profileValue =
        if missingRequirements != []
        then null
        else {
          connection = {
            id = profileId;
            type = "vpn";
            uuid = mkDeterministicUuid "nordvpn-${profileId}";
            permissions = "";
            autoconnect = false;
          };

          vpn = lib.filterAttrs (_: value: value != null && value != "") {
            "service-type" = "org.freedesktop.NetworkManager.openvpn";
            "connection-type" = "password";
            "challenge-response-flags" = "2";
            "password-flags" = "0";
            auth = getDirectiveValue "auth" lines;
            ca = toString caFile;
            cipher = getDirectiveValue "cipher" lines;
            "comp-lzo" = compLzoValue;
            dev = getDirectiveValue "dev" lines;
            mssfix = getDirectiveValue "mssfix" lines;
            ping = getDirectiveValue "ping" lines;
            "ping-restart" = getDirectiveValue "ping-restart" lines;
            "proto-tcp" =
              if protoValue == "tcp"
              then "yes"
              else if protoValue == "udp"
              then "no"
              else null;
            remote = remoteValue;
            "remote-cert-tls" = getDirectiveValue "remote-cert-tls" lines;
            "remote-random" =
              if hasDirective "remote-random" lines
              then "yes"
              else null;
            "reneg-seconds" = getDirectiveValue "reneg-sec" lines;
            ta = toString tlsAuthFile;
            "ta-dir" = keyDirection;
            "tunnel-mtu" = getDirectiveValue "tun-mtu" lines;
            username = "$NORDVPN_USERNAME";
            "verify-x509-name" = verifyValue;
          };

          "vpn-secrets".password = "$NORDVPN_PASSWORD";

          ipv4 = {
            dns-search = "";
            method = "auto";
          };

          ipv6 = {
            "addr-gen-mode" = "default";
            dns-search = "";
            method = "auto";
          };
        };
    in {
      name = profileId;
      value = profileValue;
      warnings =
        if missingRequirements == []
        then []
        else [
          "Skipping NordVPN profile ${fileName}: missing required OVPN entries (${lib.concatStringsSep ", " missingRequirements})"
        ];
    };

    nordvpnOvpnFiles =
      if !hasNordvpnProfileDir
      then []
      else
        builtins.sort (a: b: a < b) (
          lib.attrNames (
            lib.filterAttrs (name: kind: kind == "regular" && lib.hasSuffix ".ovpn" name) (builtins.readDir nordvpnProfileDir)
          )
        );

    parsedNordvpnProfiles = map mkParsedNordvpnProfile nordvpnOvpnFiles;

    nordvpnProfiles = lib.listToAttrs (
      map
      (parsed: lib.nameValuePair parsed.name parsed.value)
      (lib.filter (parsed: parsed.value != null) parsedNordvpnProfiles)
    );

    nordvpnProfileWarnings = lib.concatMap (parsed: parsed.warnings) parsedNordvpnProfiles;
  in
    lib.mkMerge [
      {
        # HM-first exception: NetworkManager and firewall are host networking plumbing.
        networking.networkmanager.enable = true;
        networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];
        networking.firewall.enable = true;

        # HM-first exception: declarative NetworkManager profile generation is host networking plumbing.
        networking.networkmanager.ensureProfiles.profiles = nordvpnProfiles;

        warnings =
          lib.optionals (!hasNordvpnProfileDir) [
            "NordVPN profile directory not found at ${toString nordvpnProfileDir}; no declarative VPN profiles will be generated."
          ]
          ++ lib.optionals (hasNordvpnProfileDir && nordvpnOvpnFiles == []) [
            "No .ovpn files found in ${toString nordvpnProfileDir}; no declarative VPN profiles will be generated."
          ]
          ++ nordvpnProfileWarnings
          ++ lib.optionals (!hasNordvpnSecretFile && nordvpnProfiles != {}) [
            "SOPS VPN credentials missing at ${toString nordvpnSecretFile}; NordVPN profiles are present but will prompt for credentials until configured."
          ];

        # HM-first exception: sudo policy is a privileged system concern.
        security.sudo.wheelNeedsPassword = lib.mkForce true;

        # HM-first exception: login-shell handoff is host-wide shell policy for system bash.
        programs.bash.interactiveShellInit = ''
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';

        # HM-first exception: dynamic linker compatibility for third-party binaries is system runtime plumbing.
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            libcap
            xz
            openssl
            zlib
          ];
        };
      }

      (lib.mkIf (hasNordvpnSecretFile && nordvpnProfiles != {}) {
        # HM-first exception: credentials for root-owned NetworkManager profiles are system secret plumbing.
        sops.secrets."vpn/nordvpn-username" = {
          sopsFile = nordvpnSecretFile;
          key = "vpn/nordvpn-username";
        };

        sops.secrets."vpn/nordvpn-password" = {
          sopsFile = nordvpnSecretFile;
          key = "vpn/nordvpn-password";
        };

        sops.templates."networkmanager-nordvpn.env".content = ''
          NORDVPN_USERNAME=${config.sops.placeholder."vpn/nordvpn-username"}
          NORDVPN_PASSWORD=${config.sops.placeholder."vpn/nordvpn-password"}
        '';

        networking.networkmanager.ensureProfiles.environmentFiles = [
          config.sops.templates."networkmanager-nordvpn.env".path
        ];
      })
    ];
}
