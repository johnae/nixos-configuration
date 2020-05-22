{ stdenv, rustPlatform, pkgconfig, dbus, libpulseaudio, sources }:
rustPlatform.buildRustPackage rec {
  pname = sources.i3status-rust.repo;
  version = sources.i3status-rust.rev;

  src = sources.i3status-rust;
  cargoSha256 = "1c9pz7vk01k73g6vxr95hab3lq2kc202zqz0gd7g1pbl5sqpb8d5";

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
