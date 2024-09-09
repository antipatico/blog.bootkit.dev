+++
title = "My take on GoHugo and Github.io mirroring"
description = "Could be useful to someone"
tags = [ "gohugo", "scripts" ]
date = "2018-09-06"
categories = [ "Blog" ]
+++

In these days I worked on setting up a
[mirror for this blog](https://antipatico.github.io) on github.io, in this
post I'll explain how I set it up.

## Repository everything
Log in on your [github.com](https://github.com) account and create these
repositories:

1. `yourwebsite.com`: this will contain your whole hugo directory and it will
   contain the *config.toml* file with the domain `yourwebsite.com`.
2. `yourgithubname.github.io`: this will be the mirror itself, it will be the
   **public/** directory inside your hugo dir, generated with the github.io
   domain inside the *config.toml*.
3. `yourhugotheme`: your theme folder in **themes/**, you can fork it if you're
   using a theme made by someone else :).

**NOTE** that all of the above repositories *can* be private, and that's sweet.

After creating the repositories copy your whole hugo folder in `yourwebsite.com`
**excluded** `themes/yourhugotheme` and `public/`.
Then copy the contents of your theme directory in `yourhugotheme`.
Create a dummy file on `yourgigthubname.github.io` to make it not empty.

Commit and push and go on the next step.

## Submodule everything
You need to *"link"* the repositories together, we are going to do it using
**git submodule**.

On `yourwebsite.com` run these commands
```bash
git submodule add git@github.com:yourgithubname/yourgithubname.github.io.git public
git submodule add git@github.com:yourgithubname/yourhugotheme.git themes/yourhugotheme
```

## Securing everything
Now we need to be able to sync the stuff from your computer to the repos, then
from the repos to the server. The first step is easy, just use git. The latter
is a little bit more tricky if the repositories are **private**.

If that's not the case, skip this step.

Create a ssh-key on the server using `ssh-keygen`, then go to your private
repositories `Settings` -> `Deploy Keys` and `Add deploy key`.

{{< bundle-image name="deploy-keys.png" >}}

**NOTE** I suggest to add it in Read-Only, you don't want to give the server
push privileges on your repository.

## Clone everything (not really)
Clone `yourwebsite.com` on your server **without** the `--recursive` flag
```bash
git clone git@github.com:yourgithubname/yourwebsite.com.git
```

You don't need to use the `--recursive` flag because your server doesn't need
the `public/` directory since it is actually the github mirror.

## Script everything
In `yourwebsite.com` root create this two scripts.

### deploy.sh
```bash
#!/bin/bash

# Pulling the changes from github.
git pull
# Pulling the theme changes
git submodule update --init themes/yourhugotheme
# Build the project.
hugo
```
Use this script from the server to sync the changes and deploy.

### github-deploy.sh
```bash
#!/bin/bash

# Set the github address in the config
sed -i.bak "s/yourwebsite.com/yourgithubname.github.io/" config.toml
# Build the project.
hugo 
# Go To Public folder
pushd public
# Add changes to git.
git add .
# Commit changes.
msg="New Commit - `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
# Push source and build repos.
git push
# Come Back up to the Project Root
popd
# Restore the old config
mv config.toml.bak config.toml
```
Use this script from your computer to deploy the changes to the github mirror.

## The end (?)
No, the start! Now you can work from your pc and easilly deploy to both github
and your server :D
