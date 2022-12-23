{ config, ... }:
{
  sops.secrets."root_user_password" = {
    format = "yaml";
    sopsFile = ../secrets/all/secrets.yaml;
    neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users = {
    root.passwordFile = config.sops.secrets."root_user_password".path;
    e1mo = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfbb4m4o89EumFjE8ichX03CC/mWry0JYaz91HKVJPb e1mo"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9x/kL2fFqQSEyFvdEgiM2UKYAZyV1oct9alS6mweVa e1mo (ssh_0x6D617FD0A85BAADA)"
      ];
    };
    n0emis = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcOPtW5FWNIdlMQFoqeyA1vHw+cA8ft8oXSbXPzQNL9 n0emis@n0emis.eu"
      ];
    };
    ruru = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMSH41EwxyxnsqDUIRxnhpl+CmvMftPRJK/CVJgft+gGurZ9X5KUeKiMPy7hCe/BAnsduhYTk452vV5JSAN0tj0c0RzDjUrM+Z+XdkRSpwKeI97QxTJADBVmxun2Y2msgnxa4eQX2J4xBqI94ogfuBKM3xKpu9IPu3ozmhSJSR1uI7MoFZpmd10Eqw5uWSld8ZjotcOibhIVisZkqIRF6OjkVDFOmeA8GqRCUa5XB24c8iUknfo1nxSednCMy+Q0tIb44+HdBhSOqSMEvDXg26PNk9sg087nOQggG8GEt1pUHmoNox528pz/UdRPl0P4bn26kIte0MGSpCjcIjYrCy6h+bXgbr6sGY47LEeyGzNDUftXA8uZzULKQLJl1IogExPZHh2JXmNKlWxlkMPGEO+BwG1uWvqDidJ8DksenWAeSDu/qhpppA56FrWHvrkok7cZCQyQfx17iZGgzI4fiYxZZDVaieLooC5S5NlpLTI2/jXyIsvcmzdX6CI0hbLhNjrlutILxvdeKuUWe7yQLeGYeYdyVj7KiA4l5f+qqVLBnzh1i/jJe6sBTTJGHUFc3TJm1p0jEkbQ9Zz/BfOc25bIzwXYbsC0dDh+b19hzrwLuzXcc2tCMIBtbmpnic+A/Gt/WuOROBApcRw5F/Ymrdrx7SwmuRL2pztkMN+Pa3jQ== linus@3-Anaklet"
      ];
    };
    adb = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwOSpmsFqj4JuuxBhpmFZ0lVyMrnwjHHP5VNJRIGFmo5kL//vpP/e70h5bIVgLXoGtloKlvopjEb6zP74JwLMMOzsNmHI3HPe4x1/KpIMoYvbdMMR85CGbZjS/Npy/rxlOxu7MkVj3I1HLpfQMFoihwYPlTcLAp+XEFdeQ01emxANa1bQj/8ttpkFRAg0GOGXfxkcQK8CVYFiuyMfOYrUcWqr5tQI50XIA4GWohSyO/9OOXvJ3u1MGoWZFg+3ABLJ8VIgMEcMPKjRHyYEJbL0b4D3YaFCx8Spyrol4zQ45Q+I3zMkxsuokFcqaT8EzE6Z7dWQ/1V4RpsfzsZ6mK186F+Q/D1gPapQUeOX0X1RubKrX0mIqbB9QBflDASRVHfAONC6lfE6iaEcXJKzYH9ldfQHgHep42zcFQpl7wrYd4fTabfqvScfwamkb6vF/JsDBwQ6Ukr7lBjgc4BSxwMmO259DzU+9caovzUl3iL1o4NtEcVEcSKcciZ7w9x5T01k= adb@adb-ux370uaf"
      ];
    };
  };
}
