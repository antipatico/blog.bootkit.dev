---
title: "Backport Software to Nix Using Overlays"
date: 2022-01-04T18:43:44+01:00
tags: ["nixos", "nix", "howto", "config", "log4j", "ghidra", "0day"]
---

I know, I know... It's been almost two years since the last time I wrote here. Well.. I had stuff to do! I am still studying for my masters degree, but I had some major step forwards in many other directions.

One of those was picking up [NixOs](https://nixos.org), a great operating system powered by the _almighty_ [Nix](https://nixos.org/manual/nix/stable/) package manager. There are various reasons behind this choice and I will probably expose them once I installed it as my main system on most of my boxes.

I have little experience with nix, but a thing that stroke me as a potential huge benefit of having a **declarative package manager** is _the possibility to edit packages without the need of messing around with the system_, having full modular and portable patches.

## The Big Ugly Event

The best opportunity to put theory into practice was thanks to the recent [log4j CVE](https://www.debian.org/security/2021/dsa-5020), which affected a lot of software written in Java.

As to be expected, the delivery from upstream developer patches to downstream linux distributions packages, can and will be delayed in cases like this one. This problem is not specific to any linux distribution in particular and can be very daunting to backport much needed hotfix to your _otherwise-stable_ system.

A perfect example of a **critical software** that **needs to be patched as soon as the patch is out** is [Ghidra](https://ghidra-sre.org). In fact, briefly after the CVE announcement, a security researcher ([@zhuowei](https://twitter.com/zhuowei)) posted a [PoC on twitter](https://twitter.com/zhuowei/status/1469511822411767811) on how to exploit the vulnerability.

{{< bundle-animated-image name="ghidra-log4j-poc.webp" >}}

As before mentioned, fixes (even as critical as this one), takes some time to reach the end user. At the time of writing of this article, the [fix has reached the stable channel](https://github.com/NixOS/nixpkgs/pull/151768), but when I came up with the solution (which I will describe in the next paragraph) the fix was yet not available and end user had to either download from upstream and mess around with dependencies, or abstain to use the program until the patch finally reached its distro package manager.

## Nix Overlays to the rescue!

**PSA**: I'm a new user (noob, if you will) of the Nix ecosystem and even if I'm starting to like it alot, I still use it only in my free time. It is more than possible that some information presented below is partially or fully incorrect.

Overlaying a package to change its version is old news. Searching the web, the solution I came up with was something along these lines:

```nix
self: super:
{
    # https://github.com/NixOS/nixpkgs/pull/151768
    # Ghidra hotfix 10.1.1
    ghidra-bin = super.ghidra-bin.overrideAttrs (old: rec {
        version = "10.1.1";
        versiondate = "20211221";
        src = self.fetchzip {
            url = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${version}_build/ghidra_${version}_PUBLIC_${versiondate}.zip";
            sha256 = "1aib24hjfavy31vq0pasbzix9lpqrb90m3hp4n0iakg6ck8jcl5r";
        };
    });
}
```

This version has two immediate shortcomings that immediately pop up in my mind:

1. In case the package receives an additional update (E.G. `10.2`), I'm stuck with the old (and maybe yet again vulnerable) version of the software.
2. Even if the `src.url` "format" is the same of the overlayed package, I have to copy it from the original package again.


## Overlaying without stopping new updates 🚀

After messing more than I liked online, I found the [versions.nix library](https://github.com/NixOS/nixpkgs/blob/master/lib/versions.nix). I kept messing around with `nix-repl` until I found out that there is a function named [**versionAtLeast**](https://github.com/NixOS/nixpkgs/blob/master/lib/strings.nix#L516), which counterintuitively is in the stringslibrary and exported in `pkgs.lib`

Using this function I was able to overcome the first "bug" I pointed out in the section above.

```nix
self: super: 
{ 
    # https://github.com/NixOS/nixpkgs/pull/151768 
    # Ghidra hotfix 10.1.1 
    ghidra-bin = (if self.lib.versionAtLeast super.ghidra-bin.version "10.1.1" then super.ghidra-bin else ( 
        super.ghidra-bin.overrideAttrs (old: rec { 
            version = "10.1.1"; 
            versiondate = "20211221"; 
            src = self.fetchzip { 
                url = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${version}_build/ghidra_${version}_PUBLIC_${versiondate}.zip"; 
                sha256 = "1aib24hjfavy31vq0pasbzix9lpqrb90m3hp4n0iakg6ck8jcl5r"; 
            };
        }) 
    ));
}
```


## Forewords

Being honest, I think the second "problem" I pointed out is not-fixable by design, since the `rec` specifier will replace the urls content with the variables, thus even if I possibly find a way to access `super.src.url` the replace would've happend in the `super` object, returing me a pre-formatted url (pointing to the old package).

This whole log4j event gave me a mountain of memes, some material to tinker with and, more importatly, something some-what interesting to write about!

I'm happy to be back and I hope I will find some more interesting stuff to write about in the future!

{{< bundle-image name="meme.jpg" >}}
