{ stdenv, rustPlatform, pkgconfig, dbus, libpulseaudio, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.i3status-rust.repo;
  version = sources.i3status-rust.rev;

  src = sources.i3status-rust;
  cargoSha256 = "1l0fkjiawjzixh03pi8mm3jrpwkadw138xfy32rpqz0p6ykrdv1y";

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
