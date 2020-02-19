## NixOS Configuration

This repo contains NixOS configuration for all my machines. The initial bootstrapping of a machine is done by building a self-installing iso like this:

```sh
./build.sh -A installers.<hostname-here>
```

an example:

```sh
./build.sh -A installers.europa
```

This should return a path which you can `dd` onto a usb stick. Just boot from that and it will automatically wipe your disks and install the system - if you rely on wifi for networking, it will pause when it detects there's no network to let you connect to one. Just exit when connected and the installer will continue.

You can also just build a system - perhaps for testing that the configuration is buildable, like this:

```sh
./build.sh -A machines.europa
```

To update the local system (eg. you're now on the europa system):

```sh
./update-system.sh
```

Updating a remote system using a locally built configuration is done like this:

```sh
./update-remote-system.sh rhea
```

```sh
./update-remote-system.sh rhea reboot
```
To also reboot the remote system when updated.


There's a metadata submodule in this repo accessible only to me. It contains encrypted secrets which I didn't feel like sharing with the world even though they're encrypted. If anyone finds this repo it should be pretty easy to figure out what data it provides (it's basically json which becomes an import). These secrets are encrypted using [mozilla sops](https://github.com/mozilla/sops) - there's also a helper in this repo for integrating sops with Nix using the extra-builtins feature of Nix (which is relatively recent, see: https://github.com/NixOS/nix/pull/1854).