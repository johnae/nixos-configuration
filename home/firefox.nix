{ pkgs, config, lib, options }:

let

  firefox-nightly = pkgs.wrapFirefox (pkgs.firejailed pkgs.latest.firefox-nightly-bin) { browserName = "firefox"; };
in

{
  programs.firefox = {
    enable = true;
    package = firefox-nightly;
    profiles = {
      default = {
        settings = {
          "browser.startup.homepage" = "about:home";
          "browser.search.region" = "SE";
          "browser.search.isUS" = false;
          "distribution.searchplugins.defaultLocale" = "sv-SE";
          "general.useragent.locale" = "sv-SE";
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.tabs.opentabfor.middleclick" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "media.peerconnection.enabled" = false; ## disable WebRTC
        };

        userChrome = ''
          #TabsToolbar {
          visibility: collapse;
          }
        '';
      };
    };
  };
}
