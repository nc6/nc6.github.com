---
layout: post
title: Building CernVM-FS server on Ubuntu
date: 2013-01-24 11:07
author: Nick
comments: true
categories: [work, cernvm-fs] 
---

The past couple of days I've been looking at running [CernVM-FS](http://cernvm.cern.ch/portal/filesystem/) at work to support our genetic pipelining software. As a first step, I've been trying to compile and run a CernVM-FS server on our systems. The details on how exactly to build a 'Stratum-0' server aren't exactly clear, so this is a set of notes of how I managed to get the server up and running.

<!-- more -->

Cern packages the cvmfs server for RHEL, Scientific Linux and even a package for Fedora 17. Unfortunately, most of our infrastructure here is Debian based, and getting hold of a RHEL based VM is slightly tricky, so instead we're building from source. The comments on the CernVM-FS website seem to suggest that the 2.0 release of the server is somewhat flaky and only works on SL5, so I'm using the 2.1BETA release.

1. Install the following packages:
	- libfuse-dev
	- apache2
	- attr
1. Grab the source from https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.1.5/cvmfs-2.1.5.tar.gz
2. Extract to a working directory.
3. ```cmake .```
4. ```make```
5. ```make install```
6. The apache2 configuration requires mod_headers to be enabled, so we enable this now: ```sudo a2enmod headers``` and then restart apache: ```sudo /etc/init.d/apache2 restart```.
7. ```sudo cvmfs_server mkfs test``` should now work correctly and give the following response:
	> Creating configuration files... done
	> Creating CernVM-FS master key for test.repo in /etc/cvmfs/keys/test.repo.pub... done
	> Creating self-signed certificate for test.repo in /etc/cvmfs/keys/test.repo.crt... done
	> Create CernVM-FS Storage... done
	> Create Initial Repository... done
	> Mounting CernVM-FS Storage... done
	> Initial commit... New CernVM-FS repository for test.repo
	> 
	> Before you can install anything, call `cvmfs_server transaction`
	> to enable write access on your repository. Then install your
	> software in /cvmfs/test.repo as user nc6.
	> Once you're happy, publish using `cvmfs_server publish`
	> 
	> For client configuration, have a look at 'cvmfs_server info'
	> 
	> If you go for production, backup you software signing keys in /etc/cvmfs/keys/!
8. Begin a transaction using ```cvmfs_server transaction test.repo```
9. At this point, you can drop some data in /cvmfs/test.repo/.
10. ```cvmfs_server publish test.repo```

You should at this point be able to see the repo in a web browser by browsing to <server address>/cvmfs/test.repo.
