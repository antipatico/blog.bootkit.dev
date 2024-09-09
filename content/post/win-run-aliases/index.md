---
title: "Win Run Aliases"
description: "Memento scripti"
date: 2019-03-20T03:33:54+01:00
tags: [ "scripts", "howto", "win10" ]
---

Today I was looking for a simple and efficient way to add aliases to the Windows
**Run** dialog box (the one you can open using `Win+R`).

{{< bundle-image name="1.png" >}}

Turns out my preferred way to do so is editing the registry, adding a key under
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths
```
ending with `.exe`.

The _**Default**_ value represents the exe you want to run, you can also add a
subkey string value to the key with the name _**Path**_ to specify the path
where you want to run your alias.

{{< bundle-image name="2.png" >}}

You can find more informations in this
[beautiful MSDN article](https://docs.microsoft.com/en-us/windows/desktop/shell/app-registration)

I would like to create a script to ease the process and eventually support an
export / import feature (maybe also interactive?), but I don't know, we'll see..

antipatico >:B
