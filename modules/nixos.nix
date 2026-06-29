{
  self,
  inputs,
  ...
}: let
  inherit (inputs) nixpkgs disko sops-nix nixos-hardware;
in {
  flake.nixosConfigurations."cypher" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit self;};
    modules = [
      disko.nixosModules.disko
      sops-nix.nixosModules.sops
      nixos-hardware.nixosModules.framework-11th-gen-intel
      ./disko/btrfs-subvolumes.nix
      ./sops/default.nix
      ({
        config,
        pkgs,
        lib,
        self,
        ...
      }: let
        alyKeys = builtins.attrValues (
          builtins.mapAttrs (name: _: "${self}/keys/${name}")
          (lib.filterAttrs (name: _: lib.hasPrefix "aly_" name && lib.hasSuffix ".pub" name)
            (builtins.readDir "${self}/keys"))
        );
      in {
        boot = {
          loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
        };

        environment = {
          systemPackages = with pkgs; [
            age
            chezmoi
            curl
            bat
            bsky-cli
            eza
            fd
            fzf
            gh
            helix
            htop
            jq
            just
            nodejs
            opencode
            python3
            ripgrep
            sops
            ssh-to-age
            tmux
            wget
            zellij
            xh
          ];

          variables = {
            FLAKE = "github:alyraffauf/cypher";
            NH_FLAKE = "github:alyraffauf/cypher";
          };
        };

        hardware.enableRedistributableFirmware = true;
        i18n.defaultLocale = "en_US.UTF-8";

        networking = {
          hostName = "cypher";
          networkmanager = {
            enable = true;

            ensureProfiles = {
              environmentFiles = [config.sops.secrets.wifi.path];

              profiles.LilycoveDeptStore = {
                connection.id = "LilycoveDeptStore";
                connection.type = "wifi";
                ipv4.method = "auto";
                ipv6.addr-gen-mode = "default";
                ipv6.method = "auto";
                wifi.mode = "infrastructure";
                wifi.ssid = "LilycoveDeptStore";
                wifi-security.auth-alg = "open";
                wifi-security.key-mgmt = "wpa-psk";
                wifi-security.psk = "$LilycoveDeptStorePSK";
              };
            };
          };
        };

        nix.settings.experimental-features = ["nix-command" "flakes"];

        programs = {
          fish.enable = true;
          git.enable = true;
          ssh.startAgent = true;
        };

        services = {
          fwupd.enable = true;

          openssh = {
            enable = true;
            openFirewall = true;
            settings.PasswordAuthentication = false;
          };

          tailscale = {
            enable = true;
            authKeyFile = config.sops.secrets.tailscaleAuthKey.path;
            extraUpFlags = ["--accept-routes" "--ssh"];
            openFirewall = true;
            useRoutingFeatures = "both";
          };
        };

        system = {
          stateVersion = "26.05";

          autoUpgrade = {
            enable = true;
            allowReboot = true;
            flags = ["--accept-flake-config"];
            flake = "github:alyraffauf/cypher";
            operation = lib.mkDefault "switch";
            dates = lib.mkDefault "02:00";
            randomizedDelaySec = lib.mkDefault "0";
            persistent = true;

            rebootWindow = {
              lower = "02:00";
              upper = "06:00";
            };
          };
        };

        time.timeZone = "America/New_York";

        users = {
          mutableUsers = false;
          users = {
            root.openssh.authorizedKeys.keyFiles = alyKeys;

            aly = {
              isNormalUser = true;
              extraGroups = ["wheel"];
              shell = pkgs.fish;
              openssh.authorizedKeys.keyFiles = alyKeys;
            };

            cypher = {
              isNormalUser = true;
              linger = true;
              shell = pkgs.bash;
              openssh.authorizedKeys.keyFiles = alyKeys;
            };
          };
        };
      })
    ];
  };
}
