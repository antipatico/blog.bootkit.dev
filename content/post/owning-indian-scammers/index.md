---
title: "Owning Indian scammers"
description: "0day today"
date: 2018-09-29T19:10:00+02:00
tags: [ "0day", "authbypass", "osint", "itsec", "wordpress" ]
---

A couple of months ago while I was watching
[KitBoga livestream](https://twitch.tv/kitboga) he leaked the address of a fake
tech-support website, made in WordPress. \
The now dead site was *"password protected"* by the [Hide My
Site](https://nl.wordpress.org/plugins/hide-my-site/) plugin. \
Thus I decided to take a look at the source-code and try to own the shit out of
the scammers.

## Target aesthetics
{{< bundle-image name="1.png" >}}

## A quick look through the code
I downloaded the source-code and I started analyzing `index.php`.\
After about 5 minutes I get to the important part
{{< highlight php "linenos=table, hl_lines=31-32, linenostart=179" >}}
<?php
public function verify_login(){
    //a password was entered. first let's confirm the user isn't blocked...
    if ((isset($_POST['hwsp_motech']))) {
      $this->security->track_ip();
    }
    do_action( 'hidemy_beforeverify', $this ); #use this hook to add additional logic before verifying password entry
    //set access cookie if password is correct
    if ((isset($_POST['hwsp_motech']) AND ($this->security->needs_to_wait != 1)
AND ($_POST['hwsp_motech'] != "")) AND ((!empty($this->verifyother)) or
($_POST['hwsp_motech'] == get_option($this->plugin_slug.'_password'))  )) {
        setcookie($this->get_cookie2_name(), 1, $this->get_cookie_duration(), '/');
      $cookie_just_set = 1;
      $this->cookie_just_set = 1;
      $this->security->remove_ip();
      $this->attempt_status = "accepted";
      do_action( 'hidemy_loginattempted', $this ); #use this hook to take an action upon login acceptance...    
    }
    //if 
    //failother is true and default cookie was not just set, or no cookie is set AND cookie was not just set
    //AND there is no admin bypass and this is not hmspreview
      //then show the login page
    if(
      (isset($_GET['hmspreview']) && ($_GET['hmspreview'] == 'true'))
      or
      (
           (
           ( (!empty($this->failother)) AND ($this->failother) AND
(empty($cookie_just_set)) ) 
           or 
           ( (empty($_COOKIE[$this->get_cookie2_name()])) AND
(empty($cookie_just_set)) )
           )   
           AND
           ( ($this->no_admin_bypass()) AND (!(isset($_GET['hmspreview']) &&
($_GET['hmspreview'] == 'true'))) )  
           AND 
           (empty($this->open_to_public))
       )
      ) {
   ...
{{< / highlight >}}

So basically if the cookie is set to something, you are authenticated.\
Here's the rest of the relevant code
{{< highlight php "linenos=table, hl_lines=11-12, linenostart=112" >}}
<?php
  public function get_cookie_name(){
    $name = $this->plugin_slug . "-access";
    return $name ;
  }
  public function get_cookie2_name(){
    $name = $this->get_cookie_name();
    $cookie2suffix = get_option($this->plugin_slug . '_cookie2suffix','');
    if(!empty($cookie2suffix)) { //cookie2suffix already set. add suffix from db
      $name .= $cookie2suffix;
    } else { //cookie2suffix not already set. generate new suffix, save to db, and add generated suffix
      $generated_suffix = rand(1,99999);
      update_option( $this->plugin_slug . '_cookie2suffix', $generated_suffix );
      $name .= $generated_suffix;
    }
    return $name;
  }
{{< / highlight >}}

`$this->plugin_slug` is a costant and its value equals to `hide_my_site`.

As highlighted in the code, if this is the first time running the plugin, a
number between `1` and `99999` is generated. That will be the number holding
your whole security up in place.

## Security considerations

There are a couple of problems with the approach of this plugin

* It assumes that every request has a maximum of one of its *special* cookies
set
* Users provided with password are considered trusted
* Changing the password won't affect a smart user
* Is the `rand()` function properly seeded?

## Owning

It's just a matter of writing a script to craft HTTP requests containing a lot
cookies.

That's what [mine](https://github.com/antipatico/0wn-my-site) looks like in action

{{< bundle-image name="2.png" >}}

The script could be parallelized, I didn’t really bothered tho. If you really
want to you can do it and send me a PR.

## Patching it

Please don't, just use an [established authentication
standard](https://en.wikipedia.org/wiki/Basic_access_authentication).

## What about the scammers?

After gaining access to the WordPress blog, it was an awful template that pushed
you to download their "security solutions" (such as TeamViewer and brothers),
and a peculiar zip, which contained a `vbs` malware to install in the
**startup** folder.

If installed, the malware would kill explorer on startup and give cancer,
litterally telling you to call their call center to fix your computer.
