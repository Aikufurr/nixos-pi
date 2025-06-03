{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages;

  # Disable ZFS on kernel 6
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "xfs"
    "cifs"
    "ntfs"
  ];

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=256M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
      "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
      };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  # systemPackages
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    nano
    micro
    bind
    iptables
    fish
  ];

  programs.fish = {
      enable = true;
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  # Some sample service.
  # Use dnsmasq as internal LAN DNS resolver.
  services.dnsmasq = {
    enable = false;
    settings.servers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];
#    settings.extraConfig = ''
#      address=/fenrir.test/192.168.100.6
#      address=/recalune.test/192.168.100.7
#      address=/eth.nixpi.test/192.168.100.3
#      address=/wlan.nixpi.test/192.168.100.4
#    '';
  };

  # services.openvpn = {
  #     # You can set openvpn connection
  #     servers = {
  #       privateVPN = {
  #         config = "config /home/nixos/vpn/privatvpn.conf";
  #       };
  #     };
  # };

#  programs.zsh = {
#    enable = true;
#    ohMyZsh = {
#      enable = true;
#      theme = "bira";
#    };
#  };


  virtualisation.docker.enable = true;

  networking.firewall.enable = false;


  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };
  # Networking
  networking = {
    # useDHCP = true;
    interfaces.wlan0 = {
      useDHCP = false;
      ipv4.addresses = [{
        # I used static IP over WLAN because I want to use it as local DNS resolver
        address = "192.168.1.4";
        prefixLength = 24;
      }];
    };
    interfaces.eth0 = {
      useDHCP = true;
      # I used DHCP because sometimes I disconnect the LAN cable
      #ipv4.addresses = [{
      #  address = "192.168.100.3";
      #  prefixLength = 24;
      #}];
    };

    # Enabling WIFI
    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
    # If you want to connect also via WIFI to your router
    wireless.networks."Glide".psk = "";
    # You can set default nameservers
    nameservers = [ "1.1.1.1" ];
    # You can set default gateway
    # defaultGateway = {
    #  address = "192.168.1.1";
    #  interface = "eth0";
    # };
  };

  # forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.tcp_ecn" = true;
  };

  # put your own configuration here, for example ssh keys:
  users.users."root".shell = pkgs.fish;
  users.users.root.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNorG0H/G8Y+dstPpE2+d3L2ozuS+RktL5Y5hwPUb/fr1JstMdgCpL98OoQDlWmScsYY7nIJ3N6aJyoEYUBPhjutDUun6LRKKQfT8b72fpG42mMI3Q6X/rPiHbIE9vveaetjVkzy/MiGY8B5twSuekb7Q3F/UB3M0zuW/vEz57/XvXbxWBaAaiUBJKRLALiya64ZErc6AfCxNLC9+uZjiQIAK5P3+pXhWfzQScmMkWWpFS6IEimVRbwtJOQjNDJvB7wbP2yrCDl/CDpT0gsKmdRcz+D0z/Xn9jNDC8+zsyz8HOF87H2gHBKV5NKKx4Y/I8FlyP2M0aP4KcS3Mhs8vjh7n4Ri6Iy4vXf4/UtTk0IJa8NXoRDN76FOeG+Pvfa+bQ0h3CaMe6bTz/fF415gwuuf4VJs8UEgdnIjUT16lsPnPvfqgrO2PBL5NnePO8MZUyH8OK/b5/TF0w0q1QAwvdWDVLHZ3UcuqSBOcMzw7B4X5cVzFWW1NAjnmBwo02IYQnjfRRrAgWhGlMNOrwptQ1YbvJrD8jPgoax6jDCTURkXGWTkvLE2E69Gq4LHiNj6QbZnOQkw9bPI5FOXqc5oezNy2XmHv7Uvi01ChyT305iMqh7qsI+MQZwwNqZK3Kb5W3wtxUK/WMBhS9nzhq+cwGbDCIjstkDxHEqGTZMHsoiw== framework13gen"
  ];
  system.stateVersion = "25.05";
}
