---
title: "GPG Offline Volume Handbook"
date: 2020-05-03T18:42:27+02:00
tags: ["howto", "privacy"]
---


**Disclaimer**: all the _"knowledge"_ you can find in this post, is obtained by trial and error, documentation reading and years of struggling using GPG. Some information may be out of date or just incorrect.

**Disclaimer 2**: as many others point out, GPG is not the easiest software to deal with. Moreover its codebase is dated and hard to extend. Further, in this day and age is pratically used only by the FOSS community and the _"darknet"_ drug dealers. All of the above, set GPG in an unfortunate spot, where it seems it will be replace any other day. Yet, the biggest problem of GPG is not either its codebase, nor its low usage and for this reason I think it will (sadly) remain around for quite a bit. Maybe I will discuss more on this later topic in another thread.

GPG version used: 2.2.12


## 0. Offline volume creation

The best way to manage your GPG keys is to have a bootable live operating system with some kind of encrypted persistency enabled.

The easiest way to do so, in my opinion, is using [TAILS](https://tails.boum.org/).

Please follow many other online guides on how to setup TAILS, create a persistent volume and enable the GPG files to persist.



## 1. Generating a Master Key

### Master Key vs Sub-keys

The master key is a PRIMARY key, as such it has *UIDs* and subkeys attached to it. If you need different **separated** identities, you will need different master keys. A subkey is a key which is linked to a master key. As such, it has the ability to be added and deleted on will.

Master key is used to sign other people keys (or in GPG words, Certify them) and your own keys. As such, it should **NOT** be exported outside this offline volume.

### Key modes

Every key (either primary or secondary) has a "mode" metafield in it. This mode describes how the key can be used. There are 4 different modes: **C**ertify, **S**ign, **E**ncrypt and **A**uthenticate.

The master key should be the only key having the **C**ertify mode, since is the mode allowing key signing and editing.

Moreover you should always have two different keys used for encryption and signing.

### Generating a key with custom cipher and modes

Generate a full key, specifying the expert mode

```
gpg --expert --full-generate-key
```

Now you should choose your preferred kind of master key, and then select the option which allows you to **set your own capabilities**.

Next, you should toggle actions for your master key allowing only the **C**ertify capability and disabling all the others.

Continue the key generation normally, adding your first User ID.

Usually, I prefer to use no password for the keys stored inside my offline volume, and to temporarily add a password only to key which are being exported (check the point number 4 of this handbook to learn how to mess around with GPG environments).

Moreover, no expiration date is really needed for your master key, since it should be used only in offline context and should be safe virtually forever.



## 2. Manage your keys

Now that your master key is created you have to add some subkeys, eventually some identities and start signing other keys.

Start editing the key in expert mode using:

```
gpg --expert --edit-key 0xMASTERKEYID
```

### Managing UID

User ID are used to identify GPG keys and associate them to email. Many program, such as enigmail, associate emails and keys using UIDs.

To add an user ID use `adduid`.

To delete an UID, first select it using `uid NUMBER` and then use `deluid`.

To set an user ID as primary, first select it using `uid NUMBER` and then use `primary`.

Finally `save` .

### Creating sub-keys

The next step is to create subkeys. Do so by using the `addkey` command.

Finally `save` .

### Extend a (sub) key lifetime

Select the key using `key ID`, then use the command `expire` and follow prompts.

Finally `save` .

### Add / Change / Remove password to a (sub) key

Select the key using `key ID`, then use the `passwd` command and follow prompts.

Finally `save` .



## 3. Export your secret subkeys to an USB drive

First you need to export your public key, which will be only one and linked to your master key.

```
gpg --export --armor --output public-keys 0xMASTERKEYID
```

Then you should generate a revokcation certificate for your master key:

```
gpg --gen-revoke --output revocation-certificate.asc 0xMASTERKEYID
```

Then you can export all your secret sub-keys:

```
gpg --armor --output secret-subkeys.asc --export-secret-subkeys 0xMASTERKEYID
```

**IMPORTANT:** when importing your keys for online usage, remember to first import the public key and then the secret sub keys.

### Export specific single subkeys

For many different reasons, one may want to export only **some** specific subkeys. To do so, add an exclamation mark after your **subkey** ID
```
gpg --export-secret-subkeys --armor --output specific-subkeys.asc 0xSUBKEYID1! 0xSUBKEYID2!
```



## 4. Testing around using a different GPG environment

You can fiddle around with GPG using the `--homedir` flag followed by a directory path. In this way you are able to have different GPG environment and you can test if everything is working as expected.

For example you may be curious to test if the subkeys import works.

You can do so creating a gpgtmp directory.

```
mkdir ~/gpgtmp
chmod 700 ~/gpgtmp
```

Then importing your public key inside it.

```
gpg --homedir ~/gpgtmp --import public-key.asc
```

Next, you should also import your secret subkeys.

```
gpg --homedir ~/gpgtmp --import secret-subkeys.asc
```

Finally you can check if everything worked out as expected by running the command:

```
gpg --homedir ~/gpgtmp -K
```

You should now see your just imported secret key having an `#` next to each key you are missing.

