{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.k3s;
  isAgent = cfg.masterUrl != null;

in
{
  options.services.k3s = {

    enable = mkEnableOption "enable k3s - lightweight kubernetes.";

    nodeName = mkOption {
      type = types.str;
      example = "somenode";
      description = ''
        The node name for the current node.
      '';
    };

    labels = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "label-one" "label-two" ];
      description = ''
        The node labels to apply to the current node.
      '';
    };

    clusterSecret = mkOption {
      type = types.str;
      example = "some-random-string-99uqu9jq9c";
      description = ''
        The shared cluster secret enabling hosts to automatically connect to each other.
      '';
    };

    masterUrl = mkOption {
      type = types.nullOr (types.strMatching "https:\/\/[0-9a-zA-Z.]+.*");
      example = "https://1.2.3.4:6332";
      default = null;
      description = ''
        The url to the master node agents should connect to. By not specifying this
        the current node is assumed to be the master node.
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.services.k3s = with pkgs; rec {
      description = "Lightweight kubernetes";
      after = [ "network-online.target" ];
      enable = true;
      environment = {
        K3S_NODE_NAME = cfg.nodeName;
        K3S_CLUSTER_SECRET = cfg.clusterSecret;
      } // (if isAgent then { K3S_URL = cfg.masterUrl; } else {});

      script = (
        if isAgent then
          ''
          exec ${k3s}/bin/k3s agent -d /var/lib/k3s/data \
                              --kubelet-arg "volume-plugin-dir=/var/lib/k3s/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              ${lib.concatStringsSep " " (map (v: "--node-label ${v}") cfg.labels)}
          ''
        else
          ''
          exec ${k3s}/bin/k3s server --no-deploy=traefik --no-deploy=servicelb --no-deploy=local-storage -d /var/lib/k3s/data \
                              -o /kubeconfig.yml \
                              --kubelet-arg "volume-plugin-dir=/var/lib/k3s/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              --kube-controller-arg "flex-volume-plugin-dir=/var/lib/k3s/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              ${lib.concatStringsSep " " (map (v: "--node-label ${v}") cfg.labels)}
          ''
      );

      serviceConfig = {
        Type = if isAgent then "exec" else "notify";
        NotifyAccess = "all";
        KillMode = "process";
        Delegate = "yes";
        LimitNOFILE = "infinity";
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
        TasksMax = "infinity";
        TimeoutStartSec = 0;
        Restart = "always";
        RestartSec = 5;
      };

      wantedBy = [ "multi-user.target" ];
    };
  };

}