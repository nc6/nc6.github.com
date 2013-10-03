---
layout: post
title: Running CernVM-FS client on Ubuntu
date: 2013-01-25 11:32
author: Nick
comments: true
categories: [cernvs-fs, work]
---

As a follow-up to [yesterday's post](2013-01-24-building-cernvm-fs-server-on-ubuntu.html), this is a post about getting the client to run correctly. We're trying to get the client to run using FUSE in order that people lacking root can mount the filesystem - this is likely to be important for getting it to run on our clusters. I'm not quite sure how plausible this it likely to be.

<!-- more -->

The most useful tool I found in getting this working was ```cvmfs_config chksetup```, which gives a listing of any problems it finds with your configuration. For me, the problems were thus:

- Autofs needs to be installed, which is isn't by default in Ubuntu: la la la la

        apt-get install autofs

- Then, you need to add the cvmfs entry to /etc/auto.master:

        /cvmfs /etc/auto.cvmfs

- Add cvmfs to the group 'fuse':

        gpasswd -a fuse cvmfs

Following the steps given by running ```cvmfs_config info <reponame>``` on the server, we also have:

- Copy the public key across to ```/etc/cvmfs/keys/repo.name.pub``` on the client.
- Modify ```/etc/cvmfs/default.local``` (or create it) to include:

        CVMFS_REPOSITORIES=repo.name

- Create ```/etc/cvmfs/config.d/repo.name``` to contain:

        CVMFS_SERVER_URL=http://server.hostname.example.com/cvmfs/repo.name
        CVMFS_PUBLIC_KEY=/etc/cvmfs/keys/repo.name.pub
        CVMFS_HTTP_PROXY=DIRECT

Or using whatever proxy settings you need to.

This was enough to have autofs mounting the repositories specified under /cvmfs. To get fuse working properly, it seemed to help to add myself into the fuse group (although it seemed to work without this, only throwing a complaint on being unable to read /etc/fuse.conf).
