{ ... }: {
  imports = [
    ./alertmanager.nix
    ./prometheus.nix
    ./blackbox.nix
    ./grafana.nix
  ];
}
