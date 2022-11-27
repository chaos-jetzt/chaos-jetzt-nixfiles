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
    leona = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILN9nTU+lsrfp+uLo1IvMEIi64m6ke0FmfZ6FxBgmKXp leona@leona.is"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkvy9P1Qweq1kykgn3IWIBWe/v/dTNAx+hd9i2aKe1O openpgp:0xCACA6CB6"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDR9Kp84lHQRnaWU6gd8MHppZD3pQCI2TCeGF/kHm/A/kqADWqtTWjnD5ad1ZhOTSThCF35VGH3ICdnSCHh0uAHV7eK3GDjhxdrIJHY/WiubEpQJcS5OX/qTEn6QrPDIAZy2ykdHX7XrNWDGOlxpTjkPpHJmmDIQTZn/mMADuhVhIm03aFyVbUxpHSU+v7N8yxV5RehIw0RTy+qSjWcthDgTGPjPk1a2sElNVbsgF4VhqpdUfzG0BQCqr+zPDbeH66+gumDPXC5Pw4NQB596UWPDKaQv7juzveiPTpIjhTfpoWBjCmexGPbSYecXNee61NXe6HsGrGLtw/pRLEYVYH0ecU/b0A7TGd2gznKBgvk8xXoxkqHbDPoCPqC3moPD3BwCXTGNi6DBDAquC/Ho266AgZ+z83mP7TuDJmZ/F4f/glbb2hdZ6ITDS7Dvd+jGlw6UXlKeZThHOy+B1c9at4FeyQs6JBd4P5RwekUCF45gk0RfRu1+HE3YOXbN1s1DRXJs689DaBzTbD9rhROEjZgNT/m0VxC6w2i6WRvxcEvy+wL4HyJxdSK0MMVhZJza4MOB7qLvIq8z3L9kLDrKh6R49m+LsH7NCS9gh0wAH17E2cImSoX4IiRemn39oKZTplAwvvaGNXOmH/SqeZlGpYOL9Yn9nE5mC10/5In/KIZMQ== openpgp:0xF5B75815"
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
  };
}