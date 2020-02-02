{ pkgs, config, lib, options }:

{
  programs.firefox = {
    enable = true;
    #package = pkgs.latest.firefox-nightly-bin;
    profiles = {
      default = {
        settings = {
          "browser.startup.homepage" = "https://nixos.org";
          "browser.search.region" = "SE";
          "browser.search.isUS" = false;
          "distribution.searchplugins.defaultLocale" = "sv-SE";
          "general.useragent.locale" = "sv-SE";
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.tabs.opentabfor.middleclick" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
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
