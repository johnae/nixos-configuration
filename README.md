## NixOS setup

This repo contains NixOS configuration for a few machines I keep around. The initial bootstrapping of a machine is done by building a self-installing iso using the script `build-system-iso.sh`. This results in an iso image with all the requirements for bootstrapping the specified system (see machines/). The only thing needed to bootstrap it is to boot from the iso, the rest should take care of itself (except possibly networking which might drop you into a shell to set that up after which you can just exit to continue).

The idea here is to completely control the exact git revision of the system we're building.