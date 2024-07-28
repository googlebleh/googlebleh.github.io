---
layout: post
title: nginx and Let's Encrypt
date: 2024-07-26 21:56 -0700
---

I ran into issues bringing up nginx unprivileged and serving over HTTPS.

## Background

I want to run a web server, nginx. I'd like to reduce the server's risk of
exposing it over the network by running it as a non-root user, and I'd like to
help users by serving HTTPS.

I accomplished the former by using
[this](https://wiki.archlinux.org/title/Nginx#Running_unprivileged_using_systemd)
systemd override
```systemd
[Service]
User=nginx
Group=nginx
ExecStart=
ExecStart=/usr/bin/nginx -g 'pid /run/nginx/nginx.pid; error_log stderr;'
ExecReload=
ExecReload=/usr/bin/nginx -s reload -g 'pid /run/nginx/nginx.pid; error_log stderr;'
PIDFile=/run/nginx/nginx.pid
RuntimeDirectory=nginx
StateDirectory=nginx
LogsDirectory=nginx
AmbientCapabilities=
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=yes
```

## Problem

However, to accomplish the latter HTTPS, Let's Encrypt's
[certbot](https://wiki.archlinux.org/title/Certbot#Nginx) expects to be run as
`root`. This means that it can guard your private key with elevated permissions
and manage `/etc/nginx/nginx.conf`, but it is not smart enough to automatically
make sure that nginx can use the files it has installed, leading to errors like
```
systemd[1]: Starting nginx web server...
nginx[27666]: 2024/07/25 17:04:43 [emerg] 27666#27666: cannot load certificate "/etc/letsencrypt/live/zopie.dev/fullchain.pem": BIO_new_file() failed (SSL: error:8000000D:system library::Permission denied:calling fopen(/etc/letsencrypt/live/zopie.dev/fullchain.pem, r) error:10080002:BIO routines::system lib)
systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
systemd[1]: nginx.service: Failed with result 'exit-code'.
systemd[1]: Failed to start nginx web server.
systemd[1]: nginx.service: Scheduled restart job, restart counter is at 1.
```
and similarly
```
nginx[28194]: 2024/07/25 17:08:24 [emerg] 28194#28194: cannot load certificate key "": BIO_new_file() failed (SSL: error:8000000D:system library::Permission denied:calling fopen(/etc/letsencrypt/live/zopie.dev/privkey.pem, r) error:10080002:BIO routines::system lib)
```
It appears that the `nginx` user cannot read the two paths that `certbot`
specified as this server's
[`ssl_certificate`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate)
and
[`ssl_certificate_key`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key)
in its config file. I confirmed this by inspecting the file system.
```
$ sudo ls -lRh /etc/letsencrypt
/etc/letsencrypt:
total 28K
drwx------ 3 root root 4.0K Jul 24 15:20 accounts
drwx------ 3 root root 4.0K Jul 25 11:12 archive
drwx------ 3 root root 4.0K Jul 25 11:12 live
-rw-r--r-- 1 root root  774 Jul 24 15:20 options-ssl-nginx.conf
drwxr-xr-x 2 root root 4.0K Jul 25 11:12 renewal
drwxr-xr-x 5 root root 4.0K Jul 24 15:20 renewal-hooks
-rw-r--r-- 1 root root  424 Jul 24 15:20 ssl-dhparams.pem
...
/etc/letsencrypt/archive:
total 4.0K
drwxr-xr-x 2 root root 4.0K Jul 25 17:06 zopie.dev

/etc/letsencrypt/archive/zopie.dev:
total 24K
-rw-r--r-- 1 root root 1.3K Jul 25 11:12 cert1.pem
-rw-r--r-- 1 root root 1.6K Jul 25 11:12 chain1.pem
-rw-r--r-- 1 root root 2.8K Jul 25 17:05 fullchain1.pem
-rw------- 1 root root  241 Jul 25 11:12 privkey1.pem

/etc/letsencrypt/live:
total 8.0K
-rw-r--r-- 1 root root  740 Jul 25 11:12 README
drwxr-xr-x 2 root root 4.0K Jul 25 11:12 zopie.dev

/etc/letsencrypt/live/zopie.dev:
total 4.0K
lrwxrwxrwx 1 root root  33 Jul 25 11:12 cert.pem -> ../../archive/zopie.dev/cert1.pem
lrwxrwxrwx 1 root root  34 Jul 25 11:12 chain.pem -> ../../archive/zopie.dev/chain1.pem
lrwxrwxrwx 1 root root  38 Jul 25 11:12 fullchain.pem -> ../../archive/zopie.dev/fullchain1.pem
lrwxrwxrwx 1 root root  36 Jul 25 11:12 privkey.pem -> ../../archive/zopie.dev/privkey1.pem
-rw-r--r-- 1 root root 692 Jul 25 11:12 README
...
```
`/etc/letsencrypt/live/zopie.dev/fullchain.pem` is a symlink to
`/etc/letsencrypt/archive/zopie.dev/fullchain.pem`, which are both
world-readable, but not all of their parent directories are.
`/etc/letsencrypt/archive` and `/etc/letsencrypt/live` are only readable by
`root`, so the `nginx` user's `fopen()` call is denied.

## Resolution

These crypto files are managed by certbot, run as `root`, and used by nginx,
run as `nginx`. Rather than elevate `nginx`'s privileges just to read files, I
chose to align permissions of the file to how they are used, and see if there
were more integration issues running nginx unprivileged.
```bash
sudo chmod g=rx /etc/letsencrypt/archive /etc/letsencrypt/live
sudo chmod g=r /etc/letsencrypt/archive/zopie.dev-0001/privkey1.pem
sudo chown :nginx /etc/letsencrypt/archive /etc/letsencrypt/live /etc/letsencrypt/archive/zopie.dev-0001/privkey1.pem
```
This allows the nginx group to read a few more files, but I made sure none of
them were too sensitive for a web server to see.

Reading `fullchain.pem` and `privkey.pem` were the only two errors I saw while
following these guides. Since copy-pasting the error messages into a search bar
didn't yield any relevant solutions, I home this finds someone else with a
similar problem!
