{config, ...}: {
  sops.defaultSopsFile = ../../secrets/default.yaml;

  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  sops.secrets.root-password = {
    neededForUsers = true;
    key = "rootPasswordHash";
  };

  sops.secrets.wifi = {
    sopsFile = ../../secrets/wifi.yaml;
    key = "env";
  };

  sops.secrets.tailscaleAuthKey = {
    sopsFile = ../../secrets/tailscale.yaml;
    key = "auth";
  };

  users.users.root.hashedPasswordFile =
    config.sops.secrets.root-password.path;
}
