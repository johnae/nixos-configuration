{ stdenv, rustPlatform, pkgconfig, dbus, libpulseaudio, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.i3status-rust.repo;
  version = sources.i3status-rust.rev;

  src = sources.i3status-rust;
  cargoSha256 = "0wm3vzbqiia54hymdfqwhqxrcp4jdbyyhmb83g1lm59x8q80gb18";

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
