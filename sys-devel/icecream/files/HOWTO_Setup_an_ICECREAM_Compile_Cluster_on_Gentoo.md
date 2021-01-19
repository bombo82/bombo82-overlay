# HOWTO Setup an ICECREAM Compile Cluster on Gentoo
[Icecream](https://github.com/icecc/icecream) was created by SUSE based on [distcc](https://github.com/distcc/distcc). Like distcc, icecream takes compile jobs from a build and distributes them among remote machines allowing a parallel build. But unlike distcc, icecream uses a central server that dynamically schedules the compile jobs to the fastest free build server. This advantage pays off mostly for shared computers, and if you're the only user on x machines, you have full control over them. Unlike distcc, icecream does not require the same versions of GCC and libraries on all machines.

## Requirements
Two or more GNU/Linux hosts connected to the same network. They do not all need to be running [Gentoo](http://gentoo.org), but if no one runs Gentoo, there is something wrong! If you use a different GNU/Linux distribution or platform on the other nodes, make sure to install the same icecream version on all machines, as the communication protocol may change between versions. The use of [ccache](https://github.com/ccache/ccache) is optional, and icecream plays nicely with ccache.

## Installation
As of January 2021, portage contains an old version of icecream, so you need to install it from an overlay. I suggest using the [bombo82](https://github.com/bombo82/bombo82-overlay) repository because it is the ebuild repository used to write this article.

> **NOTE:** starting from here, I assume you are using Gentoo and had installed (or you will to install) icecream from bombo82 overlay.

There are a lot of different ways to add an overlay. You can use the one you usually use, but if you don't know how to add a repository, you can follow these instructions:

1. add the repository using *eselect*
```bash
# emerge --ask app-eselect/eselect-repository
# eselect repository enable bombo82
```

2. unmask the latest package version by adding the following line to `/etc/portage/package.keywords`
```
acct-group/icecream
acct-user/icecream
sys-devel/icecream
```

3. install icecream package
```bash
# emerge --ask sys-devel/icecream
```

I highly recommend you to install [icemon](https://github.com/icecc/icemon) or [icecream-sundae](https://github.com/JPEWdev/icecream-sundae) with icecream.

### Install icemon
This step is optional.

As of January 2021, portage contains an old version of icemon, so you need to install it from an overlay. I suggest using the bombo82 repository because it is already added and enabled on your machine (see the previous chapter).

1. unmask the latest package version by adding the following line to `/etc/portage/package.keywords`
```
dev-util/icemon
```

2. install icemon package
```bash
# emerge --ask dev-util/icemon
```

### Install icecream-sundae
This step is optional.

As of January 2021, portage does not contain any icecream-sundae versions, so you need to install it from an overlay. I suggest using the bombo82 repository because it is already added and enabled on your machine (see the previous chapter).

1. unmask the latest package version by adding the following line to `/etc/portage/package.keywords`
```
dev-util/icecream-sundae
```

2. install icemon package
```bash
# emerge --ask dev-util/icecream-sundae
```

## Setting up
You need at least one machine that runs the scheduler (icecc-scheduler) and many machines that run the compile daemon (iceccd). It is possible to run the scheduler and the compile daemon on the same machine. For example, you can run the scheduler and the compile daemon on one machine and only the compile daemon on another one, thus forming a compile cluster with two compiling nodes, and this is a minimum cluster configuration.

> **SECURITY WARNING:** never use icecream in untrusted environments. Run the daemons and the scheduler as an unprivileged user in such networks if you have to! But you will have to rely on homogeneous networks then.

### Scheduler
You may run a scheduler on Gentoo or another GNU/Linux distribution or supported platform. This article is related only to Gentoo.

The scheduler is automatically installed and should work out-of-the-box. The configuration file is `/etc/conf.d/icecc-scheduler`. You can start the scheduler using openrc or systemd, but my ebuild does not support systemd. Feel free to add the systemd support and share your improvement!
```bash
# rc-service icecc-scheduler start
```

Next, add icecc-scheduler to the default runlevel if you like to run the scheduler on startup:
```bash
# rc-update add icecc-scheduler default
```

### Compile daemon
You may run a compile daemon on Gentoo or another GNU/Linux distribution or supported platform, but I am sure that you want to speed up the build on your Gentoo machine. This article is related only to Gentoo.

The compile daemon is automatically installed and should work out-of-the-box as a client that executes jobs incoming from other nodes. The configuration file is `/etc/conf.d/iceccd`. You can optimize some parameters, such as the number of compile jobs served in parallel or if the host accepts jobs from remote nodes.

> **NOTE:** configure zero as *ICECCD_MAX_PROCESSES* generally is a  bad idea because some jobs need to be executed on the local machine. If you don't want to run jobs from remotes on a specific node, but that node must send jobs, I suggest setting **ICECCD_MAX_PROCESSES=1** and **ICECCD_ALLOW_REMOTE="no"**.

You can start the compiler daemon using openrc or systemd, but my ebuild does not support systemd. Feel free to add the systemd support and share your improvement!
```bash
# rc-service iceccd start
```

Next, add iceccd to the default runlevel if you like to run the scheduler on startup:
```bash
# rc-update add iceccd default
```

### Network setup - firewalls
A short overview of the ports icecream requires:
- TCP/10245 on the daemon computers (required)
- TCP/8765 for the scheduler computer (required)
- TCP/8766 for the telnet interface to the scheduler (optional)
- UDP/8765 for broadcast to find the scheduler (optional)

## How to use

### Portage (emerge)
If you like to use an icecream cluster to build the portage packages, you need to configure portage itself to send the jobs to the compile daemon. Use:
```bash
# PREROOTPATH="/opt/icecream/libexec/icecc/bin" FEATURES="-network-sandbox" emerge bla bla bla
```
Or make this configuration permanent:
- add `-network-sandbox` to your _FEATURES_ list in `/etc/portage/make.conf`
- add `PREROOTPATH="/usr/libexec/icecc/bin"` in `/etc/portage/make.conf`

### Shell
If you like to use an icecream cluster to build with regular `make`, you need to configure your shell environment to do this. Append the following line to your shell environment configuration, e.g., for a system-wide effect, edit `/etc/profile`
```bash
export PREROOTPATH="/usr/libexec/icecc/bin"
```

## Combine ccache with icecream
The easiest way to use ccache with icecream is to set *CCACHE_PREFIX* to icecc (the actual icecream client wrapper). This configuration will make ccache prefix any compilation command it needs to do with icecc, making it use icecream for the compilation (but not for preprocessing alone). To use ccache in front of icecream is the same mechanism as using icecream alone.

Icecc's symlinks in `/usr/libexec/icecc/bin` should **NOT** be in your path and *PREROOTPATH* **NOT** set, as *CACHE_PREFIX* is instructing ccache to explicitly delegate to icecc rather than finding it in the path. If both ccache and icecc's symlinks are in the path, the two wrappers will mistake each other for the real compiler, cacche and icecc will complain that it has recursively invoked itself.

> **NOTE:** however that ccache isn't really worth the trouble if you're not recompiling your project three times a day from scratch. It adds some overhead in comparing the source files and uses quite some disk space.

### Portage (emerge)
Use
```bash
# CCACHE_PREFIX="icecc" FEATURES="ccache -network-sandbox" emerge bla bla bla
```
Or make this configuration permanent:
- add `-network-sandbox` to your _FEATURES_ list in `/etc/portage/make.conf`
- add `ccache` to your _FEATURES_ list in `/etc/portage/make.conf`
- append `CCACHE_PREFIX=icecc` in `/etc/portage/make.conf`
- remove (if present) `PREROOTPATH="/usr/libexec/icecc/bin"` from `/etc/portage/make.conf`

> **NOTE:** I assume that the ccache client wrapper is in your path.

### Shell
Append the following line to your shell environment configuration e.g. for a system-wide effect edit `/etc/profile`
```bash
export CCACHE_PREFIX="icecc" 
export PATH="/usr/lib/ccache/bin:$PATH"
 ```

Remove (if present) the following line to your shell environment configuration, e.g., for a system-wide effect, edit to `/etc/profile`

```bash
export PREROOTPATH="/usr/libexec/icecc/bin"
```

## cross-compiling
TODO
