---
layout: post
title: Practicing\ Convenient\ Disk\ Encryption
---

- want: a tin-foil hat for my hard disk
  - threat model is that I or someone close to me becomes a person of interest in the future, and someone wants to shame me online by hiring a professional hacker
  - if a thief breaks into my apartment, they should not get access to my proprietary hentai
- annoyance: my password is too secure
  - both in the time it takes to type it, and the fact that I have another step to turn on my computer
    1. power on computer
    2. wait for password prompt
    3. enter password
    4. wait for confirmation that password is correct
    5. once booted, use computer
  - without password
    1. power on computer
    2. once booted, use computer
  - for a headless homelab, this becomes 1 step
  - solution: passless-boot.sh
    - drawback: it doesn't fit our threat model
- passless-reboot-uefi
  - credit to abatori
  - pros compared to passless-boot.sh
    - security
  - cons compared to passless-boot.sh
    - can only reboot, cannot set up next boot as passwordless
  - as it turns out, there is no friendly interface to volatile EFI variables
    - f8b8404337de4e2466e2e1139ea68b1f8295974f in kernel tree
  - we could store in a non-volatile EFI variable, then clear it on successful boot
    - but EFI variable storage is in NVRAM, which is ultimately another flash chip on the motherboard
- passless-reboot-tpm
  - pass the buck to someone else. TPM threat model satisfies ours (barring a CPU bug)
  - systemd-autorenroll has done most of the hard work for us
    - encrypt a luks keyfile with the platform private key in TPM, saving the wrapped key and metadata in a token slot in luks (encrypted on the hard disk, but with a different key)
  - majority of the work here was correctness and paranoid checks for success
