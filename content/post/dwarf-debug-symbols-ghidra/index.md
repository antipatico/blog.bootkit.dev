---
# editPost:
#     URL: "https://github.com/<path_to_repo>/content"
#     Text: "Suggest Changes" # edit text
#     appendFilePath: true # to append file path to Edit link
# weight: 1
# aliases: ["/first"]
# author: ["Me", "You"] # multiple authors
# canonicalURL: "https://canonical.url/to/page"
hidemeta: false
comments: false
disableHLJS: true # to disable highlightjs
disableShare: false
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
UseHugoToc: true # To disable table of content
showToc: true # Hide table of content
TocOpen: true # Show expanded table of content?
draft: false # remember to change this
# cover:
#     image: "<image path/url>" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: true # only hide on current single page
description: "How to get those juicy .debug files to load" # remember to change this
tags: ["ghidra", "howto", "reverse engineering", "vulnerability research", "ctf", "gdb"]
author: "Jacopo Scannella"
title: "Load (glibc) DWARF debug symbols in Ghidra"
date: 2024-10-11T15:59:12+02:00
---

# Introduction

Today, I was doing a pwning challenge (maybe more on this on a future blog post) and for some stupid reason,
I wanted to load the glibc of my system on Ghidra. 99% of the times there is no real good reason to load
glibc on Ghidra.

That being said, loading other symbols for other binaries can be useful in other scenarios, hence the post.

This guide will cover symbols in [**DWARF**](https://en.wikipedia.org/wiki/DWARF) (`.debug`) format. Other
symbol formats exist (E.G. map files), some scripts enable partial support of those but they are deemed
out-of-scope for the purpose of this post.

# Step 1: retrieve the symbols

Skip this step if you already got your hands on the `.debug` file of your binary.

As an old grumpy debian user, the first thing I did was looking for the symbols in apt:

```bash
$ apt-cache search libc debug | rg ^libc
libc6-dbg - GNU C Library: detached debugging symbols
```

Thus, I ensured that the symbols were installed, and listed the content of the package:

```bash
$ sudo apt install libc6-dbg
libc6-dbg is already the newest version (2.40-2).

$ dpkg -L libc6-dbg                     
/.
/usr
/usr/lib
/usr/lib/debug
/usr/lib/debug/.build-id
/usr/lib/debug/.build-id/00
/usr/lib/debug/.build-id/00/816b247f0a7b16e16a4f5d3923c2db381a88b1.debug
/usr/lib/debug/.build-id/00/ec9617d2109516ef19a58c67e51c6ddbc52884.debug
/usr/lib/debug/.build-id/03
/usr/lib/debug/.build-id/03/168341ee3ad1b6a0f12236f485ad52adde5dcc.debug
/usr/lib/debug/.build-id/03/db02abdea2b823013af088df1f2cd3fc688ac3.debug
...
```

Okay, great.. but what is the one corresponding to my currently installed libc? `readelf` comes to the rescue:

```bash
$ readelf -n /usr/lib/x86_64-linux-gnu/libc.so.6 | grep Build
    Build ID: d66c2f639cbba67fc6461d75acbd0087169bc2f1
```

Then, it was possible to copy the debug file from the `/usr/lib/debug` folder:

```bash
$ cp /usr/lib/debug/.build-id/d6/6c2f639cbba67fc6461d75acbd0087169bc2f1.debug ~/ctf/libc.6.so.debug
```


# Step 2A: embedding symbols to the binary

While reading [pwntools' documentation on libcdb](https://docs.pwntools.com/en/dev/libcdb.html) a really interesting
[**unstrip_libc**](https://docs.pwntools.com/en/dev/libcdb.html#pwnlib.libcdb.unstrip_libc) function caught my eye:

> pwnlib.libcdb.unstrip_libc(filename)
>
> Given a path to a libc binary, attempt to download matching debug info and add them back to the given binary.
>
> This modifies the given file.

Trying the example code on my pwn vm resulted in the following error:

{{< bundle-image
      name="unstrip.png"
      alt="pwntools unstrip error"
      caption="pwntools unstrip error" >}}

Thereafter, I installed `elfutils` and used `eu-unstrip` to merge the `.debug` symbols with the binary:

```bash
$ eu-unstrip libc.so.6 libc.so.6.debug -o libc.so.6.WITHSYMBOLS 

$ ls -lah libc.so* 
-rwxr-xr-x 1 user user 1.9M Oct 11 15:32 libc.so.6
-rwxrwxr-x 1 user user 5.6M Oct 11 16:17 libc.so.6.WITHSYMBOLS
-rw-r--r-- 1 user user 3.8M Oct 11 16:17 libc.so.6.debug
```

Loading the binary with embedded symbols (`libc.so.6.WITHSYMBOLS`) in Ghidra and running the `Auto-Analysis` **(WITH THE DWARF STEP ENABLED)**, correctly loaded the symbols contained in the `.debug` file.

# Step 2B: define a search directory for DWARF symbols

Before coming up with the solution described in step 2A, I searched on the web (without success) how to load DWARF files in Ghidra.
Many posts and github issues referenced how it was now built-in in Ghidra and some settings non-more-existing to limit the number of symbols loaded
by Ghidra's DWARF plugin.

After searching for `DWARF` in Ghidra's script, the following script caught my eye:

{{< bundle-image
      name="DWARF.png"
      alt="DWARFSetExternalDebugFilesLocationPrescript.java"
      caption="DWARFSetExternalDebugFilesLocationPrescript.java" >}}

It was possible to load the `.debug` files present in `/usr/lib/debug` by adding the following to my `.bashrc`:

```bash
export DWARF_EXTERNAL_DEBUG_FILES="/usr/lib/debug"
```

Thereafter:
1. Closed Ghidra (all windows not only the code browser)
2. Reloaded the terminal (`. ~/.bashrc`)
3. Loaded the file without symbols (`libc.so.6`)
4. Run the `Auto-Analysis` **(WITH THE DWARF STEP ENABLED)**

The above steps resulted in the `.debug` file symbols being loaded from the specified `DWARF_EXTERNAL_DEBUG_FILES` directory.

# Conclusion

Loading glibc symbols on Ghidra will be rarely useful to anybody. Hopefully, loading `.debug` files will be for someone!
