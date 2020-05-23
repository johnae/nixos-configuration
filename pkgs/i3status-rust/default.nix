{ stdenv, rustPlatform, pkgconfig, dbus, libpulseaudio, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.i3status-rust.repo;
  version = sources.i3status-rust.rev;

  src = sources.i3status-rust;
  cargoSha256 = "1z823fcchm8z3l5rl6yni4ljf65fbv866xr0k2ji25yvq4zkq3c4";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ dbus libpulseaudio ];

  # Currently no tests are implemented, so we avoid building the package twice
  doCheck = false;

  meta = with stdenv.lib; {
    description =
      "Very resource-friendly and feature-rich replacement for i3status";
    homepage = "https://github.com/greshake/i3status-rust";
    license = licenses.gpl3;
    maintainers = with maintainers; [ backuitist globin ];
    platforms = platforms.linux;
  };
}
