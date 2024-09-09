---
title: "My Firefox user.js: a compromise between privacy and usability"
description: "Sometimes it is neither black or white. Sometimes you have to go with grey."
date: 2019-11-18T14:52:11+02:00
tags: [ "config", "privacy", "firefox" ]
---

Today I decided to refresh my Firefox profile, here is a little log.

# Why

Firstly, I decided to refresh the profile since it was a while I didn't take
care of it. Secondly, my last setup depended on `about:config`, thus all my
edits where _"ethereal"_. This time I configured everything using the sysadmin
way: [user.js](http://kb.mozillazine.org/User.js_file).

The goal of this renewal was to minimize big tech tracking while still
preserving Firefox usability, which in my case, comes before any tinfoil
paranoia.

**NOTE**: this setup is really specific and suits **me**, you should not copy
and paste it, because, as you will soon see, there is no way of _"opting out"_.

# How

I created a `user.js` for the first time in my life (**you can find it below**),
created a new profile and installed a couple of extensions to keep things
tidy and clean.

I will start by exposing the extensions and their settings for readibility's
sake, even though I first wrote the configs (`user.js`) and then installed and
configured the extensions.

## Extensions

1. uBlock Origin
  * **I am an advanced user**: this will allow you to nitpick resources to block
    when you need it, allowing an advanced filtering.
  * **Prevent WebRTC from leaking local IP addresses**: useful when using a VPN.
2. HTTPSEverywhere
3. Decentraleyes

# Results
{{< bundle-image name="womp-womp.png" >}}

Nice! :'D

# What's the point then?
If you go through the config, you will find that I limit the maximum history
size, I setup the cache in tmpfs and do other cool tricks other than fingerprint
blacklisting.

There is no way of opting out, other than stop using computers all along, I'm
sorry for you tinfoilers, but that's the hard truth.

Fingerprinting removal was only a secondary goal, the first one was to "deblob"
Firefox from his _"useless"_ features and to give me an optimal and customized
expirience.

# user.js
To create the following `user.js`, I leveraged an online tool, some online
documentation and my educated guessing skillz.

You can find some informations on the tool used and the documentations consulted
in the commends of the source code.

Read throughly the source to understand what the changes do, a lot of stuff get
disabled (I.E. mozilla's account) on the way.

{{< highlight js>}}
// antipatico's user.js
// 
// Resources:
// [1] https://ffprofile.com/
// [2] https://github.com/allo-/firefox-profilemaker
// [3] https://restoreprivacy.com/firefox-privacy/
// [4  https://wiki.mozilla.org/Privacy/Privacy_Task_Force/firefox_about_config_privacy_tweeks
//
// I will probably write a blog post about this on my blog!
// Go read it @ https://blog.bootkit.dev

/** CUSTOM SETTINGS **/
// please proceed to edit according to your preferences and system setup.

/* Set homepage. */
user_pref("browser.startup.homepage", "https://duckduckgo.com");
/* Cache settings
 * Enable cache, then set its maximum size to 200MB and set its disk location to
 * a tmpfs mounted directory (R.A.M.). */
user_pref("browser.cache.disk.enable", true);
user_pref("browser.cache.disk.capacity", 200000);
user_pref("browser.cache.disk.parent_directory", "/run/user/1000/ff-cache/");
/* Set the maximum history size (in pages) 
 * Remember the last 200 pages visited.*/
user_pref("places.history.expiration.max_pages", 200);
/* Disable asking to save websites passwords */
user_pref("signon.rememberSignons", false);
/* Clear data on shutdown
 * Keep only cache, site settings and history. */
user_pref("privacy.history.custom", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", false);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.siteSettings", false);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.openWindows", true);
user_pref("privacy.clearOnShutdown.sessions", true);
/* HiDPI settings */
user_pref("layout.css.devPixelsPerPx", "1.33");
/* Disable firefox sync */
user_pref("identity.fxaccounts.enabled", false);
/* Disable recommended extensions in about:addons */
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

/** PRIVACY TASK FORCE SETTINGS **/
/* A result of the Tor Uplift effort, this preference isolates all browser
 * identifier sources (e.g. cookies) to the first party domain, with the goal of
 * preventing tracking across different domains. */
user_pref("privacy.firstparty.isolate", true);
/* The attribute would be useful for letting websites track visitors’ clicks. */
user_pref("browser.send_pings", false);
/* Website owners can track the battery status of your device. */
user_pref("dom.battery.enabled", false);
/* Disable that websites can get notifications if you copy, paste, or cut
 * something from a web page, and it lets them know which part of the page had
 * been selected. */
user_pref("dom.event.clipboardevents.enabled", false);
/* Disables geolocation. */
user_pref("geo.enabled", false);
/* Websites can track the microphone and camera status of your device. */
user_pref("media.navigator.enabled", false);
/* Cookies are deleted at the end of the session

       0 = Accept cookies normally
       1 = Prompt for each cookie
       2 = Accept for current session only
       3 = Accept for N days
*/
user_pref("network.cookie.lifetimePolicy", 2);
/* Send only the scheme, host, and port in the Referer header

       0 = Send the full URL in the Referer header
       1 = Send the URL without its query string in the Referer header
       2 = Send only the scheme, host, and port in the Referer header
*/
user_pref("network.http.referer.trimmingPolicy", 2);
/* WebGL is a potential security risk. */
user_pref("webgl.disabled", true);


/** AUTOMATICALLY GENERATED CONFIGS (ffprofile.com) **/
/* Disable reset prompt
 * When Firefox is not used for a while, it displays a prompt asking if the
 * user wants to reset the profile. (see Bug #955950). */
user_pref("browser.disableResetPrompt", true);
/* Disable about:config warning */
user_pref("general.warnOnAboutConfig", false);
/* Disable new tab page intro.
 * Disable the intro to the newtab page on the first run. */
user_pref("browser.newtabpage.introShown", true);
/* Content of the new tab page
 * Empty. */
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.enhanced", false);
/* Disable Pocket */
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket",
false);
/* Disable Heartbeat Userrating 
 * With Firefox 37, Mozilla integrated the Heartbeat system to ask users from
 * time to time about their experience with Firefox. */
user_pref("browser.selfsupport.url", "");
/* Disable firefox intro tabs on the first start
 * Disable the first run tabs with advertisements for the latest firefox
 * features. */
user_pref("browser.startup.homepage_override.mstone", "ignore");
/* Do not trim URLs in navigation bar
 * By default Firefox trims many URLs (hiding the http:// prefix and trailing
 * slash /). */
user_pref("browser.urlbar.trimURLs", false);
/* Disable telemetry
 * The telemetry feature sends data about the performance and responsiveness
 * of Firefox to Mozilla. */
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.prompted", 2);
user_pref("toolkit.telemetry.rejected", true);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.unifiedIsOptIn", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
/* Disable health report
 * Disable sending Firefox health reports to Mozilla. */
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
/* Disable shield studies
 * Mozilla shield studies is a feature which allows mozilla to remotely install
 * experimental addons. */
user_pref("app.normandy.api_url", "");
user_pref("app.normandy.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("extensions.shield-recipe-client.api_url", "");
user_pref("extensions.shield-recipe-client.enabled", false);
/* Disable experiments
 * Telemetry Experiments is a feature that allows Firefox to automatically
 * download and run specially-designed restartless addons based on certain
 * conditions. */
user_pref("experiments.activeExperiment", false);
user_pref("experiments.enabled", false);
user_pref("experiments.manifest.uri", "");
user_pref("experiments.supported", false);
user_pref("network.allow-experiments", false);
/* Opt out metadata updates
 * Firefox sends data about installed addons as metadata updates, so Mozilla is
 * able to recommend you other addons. */
user_pref("extensions.getAddons.cache.enabled", false);
/* Disable google safebrowsing
 * Google safebrowsing can detect pishing and malware but it also sends
 * informations to google together with an unique id called wrkey. */
user_pref("browser.safebrowsing.appRepURL", "");
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
/* Disable malware scan
 * The malware scan sends an unique identifier for each downloaded file to
 * Google. */ 
user_pref("browser.safebrowsing.appRepURL", "");
user_pref("browser.safebrowsing.malware.enabled", false);
/* Disable DNS over HTTPS
 * DNS over HTTP (DoH), aka. Trusted Recursive Resolver (TRR), uses a server run
 * by Cloudfare to resolve hostnames, even when the system uses another (normal)
 * DNS server. This setting disables it and sets the mode to explicit
 * opt-out (5).*/
user_pref("network.trr.mode", 5);
/* Disable preloading of the new tab page.
 * By default Firefox preloads the new tab page (with website thumbnails) in the
 * background before it is even opened. */
user_pref("browser.newtab.preload", false);
/* Disable about:addons' Get Add-ons panel
 * The start page with recommended addons uses google analytics. */
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.webservice.discoverURL", "");
/* Disable check for captive portal.
 * By default, Firefox checks for the presence of a captive portal on every
 * startup. This involves traffic to Akamai. */
user_pref("network.captive-portal-service.enabled", false);
/* Disable Fixup URLs
 * When you type "something" in the urlbar and press enter, Firefox tries
 * "something.com", if Fixup URLs is enabled. */
user_pref("browser.fixup.alternate.enabled", false);
/* Disable Search Suggestions
 * Firefox suggests search terms in the search field. This will send everything
 * typed or pasted in the search field to the chosen search engine, even when
 * you did not press enter. */
user_pref("browser.search.suggest.enabled", false);
/* Disable speculative website loading.
 * In some situations Firefox already starts loading web pages when the mouse
 * pointer is over a link, i. e. before you actually click. This is to speed up
 * the loading of web pages by a few milliseconds. */
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("network.http.speculative-parallel-limit", "0");
/* Use a private container for new tab page thumbnails
 * Load the pages displayed on the new tab page in a private container when
 * creating thumbnails. */
user_pref("privacy.usercontext.about_newtab_segregation.enabled", true);
/* Enable resistFingerprinting
 * The privacy.resistFingerprinting setting coming from the tor-browser hides
 * some system properties.See Bug #1308340 for more information. This option may
 * interfere with other privacy related settings, see the discussion in our bug
 * tracker. */
user_pref("privacy.resistFingerprinting", true);
{{< / highlight >}}

