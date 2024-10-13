---
layout: post
title: Homelab:\ Storage
date: 2024-10-13 10:15 -0700
---

- buying drives?
  - https://forums.serverbuilds.net/t/guide-3-3v-sata-power-cable-mod-3-3v-wire-removal/9806
- realistic sizing
  - 14TB disk has 14000519643136 bytes
  ```
$ sudo fdisk -l                                                                                                        
Disk /dev/sda: 465.76 GiB, 500107862016 bytes, 976773168 sectors                                                       
Disk model: Samsung SSD 870                                                                                            
Units: sectors of 1 * 512 = 512 bytes                                                                                  
Sector size (logical/physical): 512 bytes / 512 bytes                                                                  
I/O size (minimum/optimal): 512 bytes / 512 bytes                                                                      
Disklabel type: gpt                                                                                                    
Disk identifier: 251ED6EA-AAF1-4F61-BD4A-21C723C61CAE      
                                                                                                                       
Device     Start       End   Sectors   Size Type    
/dev/sda1   2048 976773119 976771072 465.8G Linux filesystem
                                                           
                                                           
Disk /dev/sdb: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
Disk model: HGST HTS541010A7                           
Units: sectors of 1 * 512 = 512 bytes                      
Sector size (logical/physical): 512 bytes / 4096 bytes 
I/O size (minimum/optimal): 4096 bytes / 4096 bytes                                                                    
Disklabel type: dos                                                                                                    
Disk identifier: 0xe6251734                                
                                                           
Device     Boot Start        End    Sectors   Size Id Type                                                             
/dev/sdb1        2048 1953523711 1953521664 931.5G 83 Linux 
                                                           
                                                                                                                       
Disk /dev/sdc: 12.73 TiB, 14000519643136 bytes, 27344764928 sectors
Disk model: WDC  WUH721414AL                           
Units: sectors of 1 * 512 = 512 bytes                
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes    
Disklabel type: gpt                                                                                                    
Disk identifier: 6CC0A9C8-CA05-4D29-A5AE-D3E543E228AB                                                                  
                                                                                                                       
Device           Start         End     Sectors  Size Type                                                              
/dev/sdc1         2048 22978496511 22978494464 10.7T Linux RAID
/dev/sdc2  22978496512 27344762879  4366266368    2T Linux filesystem
                                                                                                                       

Disk /dev/nvme0n1: 1.82 TiB, 2000398934016 bytes, 3907029168 sectors
Disk model: Samsung SSD 990 PRO 2TB                 
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: A50C394B-D86A-4440-8E28-B621DD37A14E
  ```
  - 14000519643136 / (14 * (1024 * 1024 * 1024 * 1024))
  - empirically settled on a factor of 0.89 * advertised to be sure
- disk > gpt > partition
  - integritysetup
    - bit rot is unlikely, but costs us very little to protect against and is disastrous when it happens
    - xxhash64 for speed. we don't need protection against tampering
      - physical attackers have other ways of inserting themselves, whether the goal is spoofing data or code exec
    - systemd-integritysetup-generator
  - cryptsetup
    - keyfile on root
    - systemd-cryptsetup-generator
