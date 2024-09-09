---
title: "ipset and Cloudflare"
description: "a simple bash script for ipset and Cloudflare"
date: 2018-09-09T11:18:14+02:00
tags: [ "iptables", "scripts" ]
---

While setting up the server for this blog I stumbled across the problem to
whitelist cloudflare's ip ranges in iptables.

After a quick search I realized a smart and efficient way to do this is using
[ipset](http://ipset.netfilter.org/).

Thus I created [**a script**](https://gist.github.com/antipatico/3bc4cc2769ba4e16951e39ca468e8572) to download the latest Cloudfare's **IPv4** ranges and
create an ipset list out of it.

#### ipset-cloudflare.sh
```bash
#!/bin/bash
# Created by antipatico (antipatico.ml)
# Download the latest cloudflare's IPv4 ranges and create an ipset
# named "cloudflare" you can later use in your iptables rules.

IPSV4=$(mktemp)
wget --quiet -O $IPSV4 https://www.cloudflare.com/ips-v4
ipset destroy cloudflare
ipset create cloudflare hash:net
while read -r range; do
	ipset add cloudflare $range
done < $IPSV4
rm $IPSV4
ipset list cloudflare
exit 0
```

After running it you can use it in your iptables rules like this

```iptables
-A INPUT -p tcp -m tcp --dport 443 -m set --match-set cloudflare src -j ACCEPT
```
