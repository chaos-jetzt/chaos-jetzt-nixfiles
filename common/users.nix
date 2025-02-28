{ config, ... }:
{
  sops.secrets."root_user_password" = {
    format = "yaml";
    sopsFile = ../secrets/all/secrets.yaml;
    neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users = {
    root.hashedPasswordFile = config.sops.secrets."root_user_password".path;
    e1mo = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfbb4m4o89EumFjE8ichX03CC/mWry0JYaz91HKVJPb e1mo"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9x/kL2fFqQSEyFvdEgiM2UKYAZyV1oct9alS6mweVa e1mo (ssh_0x6D617FD0A85BAADA)"
      ];
    };
    ruru = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMSH41EwxyxnsqDUIRxnhpl+CmvMftPRJK/CVJgft+gGurZ9X5KUeKiMPy7hCe/BAnsduhYTk452vV5JSAN0tj0c0RzDjUrM+Z+XdkRSpwKeI97QxTJADBVmxun2Y2msgnxa4eQX2J4xBqI94ogfuBKM3xKpu9IPu3ozmhSJSR1uI7MoFZpmd10Eqw5uWSld8ZjotcOibhIVisZkqIRF6OjkVDFOmeA8GqRCUa5XB24c8iUknfo1nxSednCMy+Q0tIb44+HdBhSOqSMEvDXg26PNk9sg087nOQggG8GEt1pUHmoNox528pz/UdRPl0P4bn26kIte0MGSpCjcIjYrCy6h+bXgbr6sGY47LEeyGzNDUftXA8uZzULKQLJl1IogExPZHh2JXmNKlWxlkMPGEO+BwG1uWvqDidJ8DksenWAeSDu/qhpppA56FrWHvrkok7cZCQyQfx17iZGgzI4fiYxZZDVaieLooC5S5NlpLTI2/jXyIsvcmzdX6CI0hbLhNjrlutILxvdeKuUWe7yQLeGYeYdyVj7KiA4l5f+qqVLBnzh1i/jJe6sBTTJGHUFc3TJm1p0jEkbQ9Zz/BfOc25bIzwXYbsC0dDh+b19hzrwLuzXcc2tCMIBtbmpnic+A/Gt/WuOROBApcRw5F/Ymrdrx7SwmuRL2pztkMN+Pa3jQ== linus@3-Anaklet"
      ];
    };
    servermensch = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAa0Gq23QsvMrutuM/ceCMj+OJ0s7gCnPe0stN9DjFfy5ER/qjCuvdIf2oPqEhdg3wIitvNPV6Lpkz5ifYQU8RRtjXPD2+agE83E6B29MuNG/1w/Netq5wcShrRx7zDvvBScprji7P/jugfrTMoDjh5H0SACHNDHNzQoDIVrMq1ION+2JJbQFA1G9PguhudUpQ2fUt9DNq3b47wzajR9l0wtVOUwpZMnUFvDsZ+85PlnEaAQOBoNucn9nt8QLZsPR7tfB1naT4e03wwvcAoTcAKsXcSpCiTp08CAQxH3yCYSMgBnw8ZL7uy9xtJcdDcm2RtD4R1Pmqzo+KoUcTFlAzusg9WUJXO5oJFGWfkrZR+LrR66Ap6ujhB7dPjUgMjwobFbSh6w7SowbwaSR3WU+X5kek8JAM4Sgmy3wBK5MoDFwyIkLW+2DPKFQFZmuhwzAEmk3TauXWbwy7s9yJg9234Y3ZFqef7TGpJrJ4S6GYTSLs9PWECuP/HbiGF8nMlKPYapdi27reSP5V4RV+R7/WOz5r6MvWRzoXEt2nSbxdES4ZFsEqAxnYVKpJH2xR5BQBqrsRK9hzXk8F+LlpFKIOH8VSbDKVN0Orpc+E8dFwb5oEOAR9oytnyHEMIkos0FAk89GcoYJiB9LPKkLedXXHHPe8yaqPkSz4U7GoNXOo1Q== jetzt"
      ];
    };
  };
}
