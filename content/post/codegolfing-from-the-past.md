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
showToc: false # Hide table of content
TocOpen: false # Show expanded table of content?
draft: false # remember to change this
# cover:
    # image: "<image path/url>" # image path/url
    # alt: "<alt text>" # alt text
    # caption: "<text>" # display caption under cover
    # relative: false # when using page bundles set this to true
    # hidden: true # only hide on current single page
description: "A tale from the past" # remember to change this
tags: ["blog", "coding", "js", "python", "cloudflare"]
author: "Jacopo Scannella"
title: "Code-Golfing from the past"
date: 2024-07-20T09:16:13+02:00
# Original Date: date = "2018-10-24"
---
This was an old post I originally wrote the 24th of October 2018. I recently discovered it in the drafts of this blog.
At the time, I was planning to do this challenge on many other languages, but ended up abandoning. I decided to publish it today. It is a short one, enjoy!

# Cloudflare's email-decoder in one line

I've recently _"decrypted"_ Cloudflare's [email-decode.js](https://gist.github.com/antipatico/4ab1a4a93e2200df50a3d007b387ae37),
this is my take on writing some **one line** decoders for it.
Thus `....` will be _"decrypted"_ into `l33t@antipatico.ml`

### Why one line?
It's fun to code-golf from time to time.

## Javascript
```javascript
var cfDecrypt = ciphertext => [...ciphertext].slice(2).map(x => parseInt(x,16)).map((x,i,arr) => (i%2)? x+arr[i-1]*16 : -1).filter(x => x != -1).map(x => x ^ parseInt(ciphertext.substr(0,2),16)).map(x => String.fromCharCode(x)).join("");
```

## Python
```python
cfDecrypt = lambda emailCipher : "".join([ chr(int(emailCipher[x:x+2], 16)^int(emailCipher[:2],16)) for x in range(2, len(emailCipher), 2)])
```

## Bash

## Radare2

## Powershell

## C#

## Go