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
#     image: "<image path/url>" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: true # only hide on current single page
description: "Rest in peace my beloved hugo-dusk" # remember to change this
tags: ["gohugo", "blog"]
author: "Jacopo Scannella"
title: "PaperMod is here!"
date: 2024-07-20T07:26:19+02:00
---

I switched from my old and beloved [hugo-dusk](https://github.com/gyorb/hugo-dusk) theme, to the new flashy and shiny [PaperMod](https://github.com/adityatelange/hugo-PaperMod/) theme.

## Why?

The old theme development has been dropped and I was basically maintaining it myself. I added some (debatably) cool stuff to it, but it was time to let it go.

Moreover, the new theme has really nice features, such as:
- Introduction in home page to brag about my social status and career achievements
- Per-year [archive](/archives/), allowing stalkers to dig easilly in my past
- Search full-text fuzzy functionality, which I still need to figure out how to disable
- Leverages new Hugo features such as table of content, which will be fun to enable in old posts
- Automatic dark / light theme

I also took this chance to finally move to CI/CD instead of manually deploying every time. Github actions are not pretty but they do the job.

## What I will miss

The coolest thing about `hugo-dusk` was that it was pure static HTML, no JavaScript. That made the loading of the site super fast and the over-all experience _"old-school"_. And that was what I was looking for at the time. Moreover, I will miss the shade of orange and the custom play button the old theme had.

