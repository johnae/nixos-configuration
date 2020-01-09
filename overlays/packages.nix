self: super: rec {
  k3s = super.callPackage ../packages/k3s { };
  system-san-francisco-font = super.callPackage ../packages/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../packages/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../packages/office-code-pro-font { };
  btr-snap = super.callPackage ../packages/btr-snap { };
  redshift-wl = super.callPackage ../packages/redshift {
    inherit (super.python3Packages) python pygobject3 pyxdg wrapPython;
    geoclue = super.geoclue2;
  };
}
