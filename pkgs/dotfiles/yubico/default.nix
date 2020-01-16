{stdenv, lib, libdot, writeText, ...}:

let
  user = builtins.getEnv "USER";
  keys = [
    {
      keyHandle = "Luurpb0vdJ7EaMY7jt6iq3YyA5Jh2M9DfL1GTNN_pVYhUkMvvpJ-tmnpGI_4F_73oyzAvRtWp-BSit8arnTRKw";
      userKey = "04b8ccf918b9ef6e5a4f92918e27cddbb3ad81de12cf3f028bdef8c748561115ae115244b0110fff04532053e4a7d311cb6a4c17557402615225ca3209e823bd86";
    }
    {
      keyHandle = "Jp8BxTUctJ_85v8NZ2YIEdLbXqDBzwTbBlwAokjnNR4qgRd47oxxihMeNkotwwYVGyDEhvm5gQ8OIg5yTLDw9g";
      userKey = "040b194f42521fbde358dc127a42e9ddc216ad6c9eefdd77969f8b15e9492c1265f0130c3c584676356d76e0531ff98c08cc3ee8c51f80633ac0fe19625bae013f";
    }
    {
      keyHandle = "xFr5z5C9F68c53WkiHg4S3q83bE8w4JV2Yc_8lBMoR5FW1u6eg4JP2EJ0L0VAiTJqShXPUsAU7JUVzM3XfJiBw";
      userKey = "04dc6c1bba56aceeab24ae4d4de2ca37de06eefdf4d487aaeeb7ad0ab41fce27d36df627f3f0b2e97461142577e57ab026bd513d37dcdb69fdf398ad774b7721b5";
    }
    {
      keyHandle = "rjKCJ2c8PB-UlMCsf5ql8j53lc5XBmCCoLaWghXPUMxoyW6RwVIZYabLu3Rhty69ut7V3DSWnlslQ_z2Z49IaQ";
      userKey = "045c78187e971d1bcc487ac75617345457ef13698913f3e871d33b5f67c352ea21ebf279f2e6b294f3fac4510c71c750aebd664e817b09927a5798ec3eb071d183";
    }
  ];

  config = writeText "yubico-u2f_keys" ''
  ${user}:${
    lib.concatStringsSep ":" (
      lib.concatMap (x: [''${x.keyHandle},${x.userKey}'']) keys
    )
  }
  '';

in

  {
    __toString = self: ''
      ${libdot.mkdir { path = ".config/Yubico"; }}
      ${libdot.copy { path = config; to = ".config/Yubico/u2f_keys"; mode = "0600"; }}
    '';
  }