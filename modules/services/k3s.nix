{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.k3s;
  isAgent = cfg.masterUrl != null;
  isMaster = !isAgent;
  k3sDir = "/var/lib/k3s";
  k3sDataDir = "${k3sDir}/data";
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

    docker = mkOption {
      type = types.bool;
      default = config.virtualisation.docker.enable;
      description = ''
        Whether to use docker instead of containerd.
      '';
    };

    flannelBackend = mkOption {
      type = with types; nullOr (enum [ "none" "vxlan" "ipsec" "wireguard" ]);
      default = "vxlan";
      description = ''
        The type of flannel networking to use. If set to none, you are free to
        use your own network plugin.
      '';
    };

    extraManifests = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        A list of paths to kubernetes manifests to automatically apply.
      '';
    };

    masterUrl = mkOption {
      type = types.nullOr (types.strMatching "https://[0-9a-zA-Z.]+.*");
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
        if isAgent
        then ''
          exec ${k3s}/bin/k3s agent -d ${k3sDataDir} ${
        if cfg.docker then "--docker" else ""
        }\
                              --kubelet-arg "volume-plugin-dir=${k3sDir}/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              --kubelet-arg "cni-bin-dir=${k3sDir}/opt/cni/bin" \
                              ${
        lib.concatStringsSep " "
          (map (v: "--node-label ${v}") cfg.labels)
        }
        '' else ''
          exec ${k3s}/bin/k3s server --no-deploy=traefik --no-deploy=servicelb --no-deploy=local-storage -d ${k3sDataDir} ${
        if cfg.docker then "--docker" else ""
        } \
                              -o /kubeconfig.yml --flannel-backend=${cfg.flannelBackend} \
                              --kubelet-arg "volume-plugin-dir=${k3sDir}/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              --kubelet-arg "cni-bin-dir=${k3sDir}/opt/cni/bin" \
                              --kube-controller-arg "flex-volume-plugin-dir=${k3sDir}/libexec/kubernetes/kubelet-plugins/volume/exec" \
                              ${
        lib.concatStringsSep " "
          (map (v: "--node-label ${v}") cfg.labels)
        }
        ''
      );

      postStart = (
        if isMaster
        then ''
          echo Applying extra kubernetes manifests
          set -x
          ${lib.concatStringsSep "\n" (
          map (
            m:
            "${kubectl}/bin/kubectl --kubeconfig /kubeconfig.yml apply -f ${m}"
          )
            cfg.extraManifests
        )}
        '' else
          ""
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
