self: super: rec {
  k3s = super.callPackage ../pkgs/k3s { };
  system-san-francisco-font = super.callPackage ../pkgs/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../pkgs/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../pkgs/office-code-pro-font { };
  btr-snap = super.callPackage ../pkgs/btr-snap { };
  redshift-wl = super.callPackage ../pkgs/redshift {
    inherit (super.python3Packages) python pygobject3 pyxdg wrapPython;
    geoclue = super.geoclue2;
  };
}
