[![Build status](https://badge.buildkite.com/4e0d9ed7873fec61b569bd1e43d580393ae98ca1e1e8243ee4.svg)](https://buildkite.com/insane/nixos-configuration)

## NixOS Configuration

This repo contains NixOS configuration for all my machines. The initial bootstrapping of a machine is done by building a self-installing iso like this:

```sh
nix-shell --run "build -A installers.<hostname-here>"
```

an example:

```sh
nix-shell --run "build -A installers.europa"
```

This should return a path which you can `dd` onto a usb stick. Just boot from that and it will automatically wipe your disks and install the system - if you rely on wifi for networking, it will pause when it detects there's no network to let you connect to one. Just exit when connected and the installer will continue.

You can also just build a system - perhaps for testing that the configuration is buildable, like this:

```sh
nix-shell --run "build -A machines.europa"
```

To update the local system:

```sh
nix-shell --run update-system
```

Updating a remote system using a locally built configuration is done like this:

```sh
nix-shell --run "update-remote-system rhea"
```

```sh
nix-shell --run "update-remote-system rhea reboot"
```
To also reboot the remote system when updated.

Of course, I use [direnv](https://direnv.net/) with Nix integration so I don't need to prefix any of the above with "nix-shell --run", I can just run `build -A machines.europa`. Together with [lorri](https://github.com/target/lorri), direnv + nix becomes even more awesome btw.


There's a metadata submodule in this repo accessible only by me. It contains encrypted secrets which I didn't feel like sharing with the world even though they're encrypted. If anyone finds this repo it should be pretty easy to figure out what data it provides (it's basically json which becomes an imported module). These secrets are encrypted using [mozilla sops](https://github.com/mozilla/sops) - there's also a helper in this repo for integrating sops with Nix using the extra-builtins feature of Nix (which is relatively recent, see: https://github.com/NixOS/nix/pull/1854 and also https://elvishjerricco.github.io/2018/06/24/secure-declarative-key-management.html).