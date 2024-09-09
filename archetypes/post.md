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
TocOpen: false # Show expanded table of content?
draft: true # remember to change this
# cover:
#     image: "<image path/url>" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: true # only hide on current single page
description: "" # remember to change this
tags: [""]
author: "{{ .Site.Params.Author }}"
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
---