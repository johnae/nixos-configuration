{ pkgs, config, lib, options }:

rec {
  programs.mako = {
    enable = true;
    settings = rec {
      font = "Roboto";
      background-color = "#000021DD";
      text-color = "#FFFFFFFF";
      border-size = "0";
      border-radius = "15";
      icons = "1";
      icon-path = "${pkgs.moka-icon-theme}/share/icons/Moka";
      markup = "1";
      actions = "1";
      default-timeout = "3000"; ## ms
      padding = "20";
      height = "200";
      width = "500";
      layer = "overlay";
    };
  };
}
