# Environment

- 1 SSD type OS disk (50GB)
- 3 SSD type data disks (3x350GB - /mnt/datadisk1, /mnt/datadisk2, and /mnt/datadisk3)
- *europe-west8* Region (Milan)

```bash
$ df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
/dev/sda3      xfs        50G   11G   40G  22% /
devtmpfs       devtmpfs  4.0M  8.0K  4.0M   1% /dev
tmpfs          tmpfs      63G     0   63G   0% /dev/shm
efivarfs       efivarfs   56K   24K   27K  48% /sys/firmware/efi/efivars
tmpfs          tmpfs      26G   26M   26G   1% /run
/dev/sda2      vfat       20M  3.8M   17M  19% /boot/efi
/dev/sdb1      ext4      344G   46G  281G  14% /mnt/datadisk1
/dev/sdc1      ext4      344G   42G  285G  13% /mnt/datadisk2
/dev/sdd1      ext4      344G   42G  285G  13% /mnt/datadisk3
tmpfs          tmpfs      13G  8.0K   13G   1% /run/user/1008
```

# Performance tests

## 1_ W/R test with *dd* (GCP Disks)

### Writing

```bash
# Quick tests
dd if=/dev/zero of=/mnt/datadisk1/testfile bs=1G count=2 oflag=direct
dd if=/dev/zero of=/mnt/datadisk2/testfile bs=1G count=2 oflag=direct
dd if=/dev/zero of=/mnt/datadisk3/testfile bs=1G count=2 oflag=direct
# Slow tests
dd if=/dev/zero of=/mnt/datadisk1/testfile bs=1M oflag=sync
dd if=/dev/zero of=/mnt/datadisk2/testfile bs=1M oflag=sync
dd if=/dev/zero of=/mnt/datadisk2/testfile bs=1M oflag=sync
```

#### Explanation

- `if=/dev/zero`: Generates "empty" data to write to disk.
- `of=/mnt/datadiskX/testfile`: Writes to one of your disks.
- `bs=1G count=2`: Writes 2GB of data in 1GB blocks.
- `oflag=direct`: Avoid system cache for more realistic testing.

For completeness of information:
- `oflag=direct`: Writes data directly to disk, bypassing the operating system cache. Improve real-world disk performance tests.
- `oflag=sync`: Each write operation is immediately written to disk, without waiting for the buffer to be emptied. Simulate a more realistic load for latency-sensitive applications.
- `oflag=dsync`: Similar to *sync*, but ensures that the file's metadata is updated before writing is completed.

#### Results

```bash
# Quick tests
$ dd if=/dev/zero of=/mnt/datadisk1/testfile bs=1G count=2 oflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 3.21338 s, 668 MB/s
$ dd if=/dev/zero of=/mnt/datadisk2/testfile bs=1G count=2 oflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 3.19158 s, 673 MB/s
$ dd if=/dev/zero of=/mnt/datadisk3/testfile bs=1G count=2 oflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 3.12686 s, 687 MB/s
# Slow test
$ dd if=/dev/zero of=/mnt/datadisk1/testfile bs=1M oflag=sync
dd: error writing '/mnt/datadisk1/testfile': No space left on device
304935+0 records in
304934+0 records out
319747141632 bytes (320 GB, 298 GiB) copied, 847.729 s, 377 MB/s
...
...
...
```

### Reading 

```bash
# Quick tests
$ dd if=/mnt/datadisk1/testfile of=/dev/null bs=1G count=2 iflag=direct
$ dd if=/mnt/datadisk2/testfile of=/dev/null bs=1G count=2 iflag=direct
$ dd if=/mnt/datadisk3/testfile of=/dev/null bs=1G count=2 iflag=direct
```

#### Explanation

- `if=/mnt/datadiskX/testfile`: Reads the file just written.
- `of=/dev/null`: Discards the read data.
- `iflag=direct`: Avoid system cache.

#### Results

```bash
$ dd if=/mnt/datadisk1/testfile of=/dev/null bs=1G count=2 iflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 2.65317 s, 809 MB/s
$ dd if=/mnt/datadisk2/testfile of=/dev/null bs=1G count=2 iflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 2.71187 s, 792 MB/s
$ dd if=/mnt/datadisk3/testfile of=/dev/null bs=1G count=2 iflag=direct
2+0 records in
2+0 records out
2147483648 bytes (2.1 GB, 2.0 GiB) copied, 2.6786 s, 802 MB/s
```

**Remember to delete files after testing to free up space.**

```bash
rm /mnt/datadisk1/testfile
rm /mnt/datadisk2/testfile
rm /mnt/datadisk3/testfile
```

## 2_ Random I/O test with *fio* (GCP Disks)

### Download *fio*

```bash
$ sudo zypper install fio libaio libaio-devel
```

### 2.1_ Sequential Writing (1 Job)

```bash
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
```

#### Explanation

- `--ioengine=libaio`: Asynchronous I/O engine for better performance.
- `--bs=1M`: 1M blocks.
- `--size=250G`: Test on 250GB of data.
- `--direct=1`: Bypass OS caching for more realistic results.
- `--iodepth=128`: Simulates requests in parallel (128 queued operations).
- `--group_reporting`: Generate aggregate reports for all jobs.

#### Results

```bash
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 1 (f=0): [f(1)][100.0%][w=743MiB/s][w=743 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=21545: Tue Feb 11 09:26:57 2025
  write: IOPS=765, BW=765MiB/s (803MB/s)(100GiB/133789msec); 0 zone resets
    slat (usec): min=27, max=174039, avg=121.82, stdev=2826.23
    clat (msec): min=3, max=455, avg=167.11, stdev=29.78
     lat (msec): min=3, max=455, avg=167.23, stdev=29.67
    clat percentiles (msec):
     |  1.00th=[   36],  5.00th=[  159], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  167], 80.00th=[  169], 90.00th=[  169], 95.00th=[  190],
     | 99.00th=[  296], 99.50th=[  313], 99.90th=[  330], 99.95th=[  334],
     | 99.99th=[  426]
   bw (  KiB/s): min=528384, max=1044480, per=100.00%, avg=784476.04, stdev=45106.62, samples=267
   iops        : min=  516, max= 1020, avg=766.09, stdev=44.05, samples=267
  lat (msec)   : 4=0.01%, 10=0.22%, 20=0.36%, 50=0.82%, 100=1.58%
  lat (msec)   : 250=94.74%, 500=2.29%
  cpu          : usr=4.28%, sys=1.34%, ctx=96660, majf=0, minf=357
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=0,102400,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
  WRITE: bw=765MiB/s (803MB/s), 765MiB/s-765MiB/s (803MB/s-803MB/s), io=100GiB (107GB), run=133789-133789msec

Disk stats (read/write):
  sdb: ios=9/410918, merge=0/3959, ticks=5593/69790028, in_queue=69795766, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=769MiB/s][w=769 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=22363: Tue Feb 11 09:29:50 2025
  write: IOPS=766, BW=767MiB/s (804MB/s)(100GiB/133528msec); 0 zone resets
    slat (usec): min=25, max=172039, avg=100.32, stdev=2215.08
    clat (msec): min=3, max=402, avg=166.80, stdev=29.77
     lat (msec): min=3, max=403, avg=166.90, stdev=29.70
    clat percentiles (msec):
     |  1.00th=[   27],  5.00th=[  163], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  167], 80.00th=[  169], 90.00th=[  169], 95.00th=[  184],
     | 99.00th=[  292], 99.50th=[  317], 99.90th=[  330], 99.95th=[  338],
     | 99.99th=[  388]
   bw (  KiB/s): min=548864, max=1034240, per=100.00%, avg=786562.89, stdev=39577.23, samples=266
   iops        : min=  536, max= 1010, avg=768.14, stdev=38.65, samples=266
  lat (msec)   : 4=0.01%, 10=0.40%, 20=0.40%, 50=0.82%, 100=1.45%
  lat (msec)   : 250=94.93%, 500=1.99%
  cpu          : usr=4.35%, sys=1.16%, ctx=93928, majf=0, minf=375
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=0,102400,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
  WRITE: bw=767MiB/s (804MB/s), 767MiB/s-767MiB/s (804MB/s-804MB/s), io=100GiB (107GB), run=133528-133528msec

Disk stats (read/write):
  sdc: ios=0/410053, merge=0/2563, ticks=0/65711022, in_queue=65711037, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=769MiB/s][w=768 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=23033: Tue Feb 11 09:33:11 2025
  write: IOPS=767, BW=767MiB/s (804MB/s)(100GiB/133494msec); 0 zone resets
    slat (usec): min=27, max=167380, avg=169.57, stdev=3751.30
    clat (msec): min=8, max=340, avg=166.69, stdev=43.48
     lat (msec): min=8, max=340, avg=166.86, stdev=43.34
    clat percentiles (msec):
     |  1.00th=[   10],  5.00th=[   81], 10.00th=[  144], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  169], 80.00th=[  176], 90.00th=[  190], 95.00th=[  243],
     | 99.00th=[  309], 99.50th=[  321], 99.90th=[  330], 99.95th=[  330],
     | 99.99th=[  334]
   bw (  KiB/s): min=528384, max=1042395, per=100.00%, avg=786737.49, stdev=86515.62, samples=266
   iops        : min=  516, max= 1017, avg=768.29, stdev=84.48, samples=266
  lat (msec)   : 10=1.10%, 20=0.90%, 50=1.55%, 100=3.04%, 250=89.21%
  lat (msec)   : 500=4.20%
  cpu          : usr=4.41%, sys=1.11%, ctx=74369, majf=0, minf=745
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=0,102400,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
  WRITE: bw=767MiB/s (804MB/s), 767MiB/s-767MiB/s (804MB/s-804MB/s), io=100GiB (107GB), run=133494-133494msec

Disk stats (read/write):
  sdd: ios=6/412220, merge=0/2470, ticks=254/59712502, in_queue=59712795, util=100.00%
```

### 2.2_ Sequential Reading (1 Job)

```bash
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
```

#### Results

```bash
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 1 (f=1): [R(1)][100.0%][r=768MiB/s][r=767 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=23660: Tue Feb 11 09:41:09 2025
  read: IOPS=768, BW=768MiB/s (806MB/s)(100GiB/133287msec)
    slat (usec): min=6, max=342, avg=13.13, stdev= 8.96
    clat (msec): min=11, max=336, avg=166.58, stdev=19.45
     lat (msec): min=11, max=336, avg=166.59, stdev=19.45
    clat percentiles (msec):
     |  1.00th=[   85],  5.00th=[  161], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  169], 50.00th=[  169], 60.00th=[  171],
     | 70.00th=[  171], 80.00th=[  174], 90.00th=[  178], 95.00th=[  180],
     | 99.00th=[  192], 99.50th=[  199], 99.90th=[  215], 99.95th=[  262],
     | 99.99th=[  321]
   bw (  KiB/s): min=638976, max=864256, per=100.00%, avg=787417.50, stdev=10911.52, samples=266
   iops        : min=  624, max=  844, avg=768.97, stdev=10.66, samples=266
  lat (msec)   : 20=0.06%, 50=0.03%, 100=4.55%, 250=95.30%, 500=0.06%
  cpu          : usr=0.16%, sys=1.24%, ctx=101968, majf=0, minf=587
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=102400,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=768MiB/s (806MB/s), 768MiB/s-768MiB/s (806MB/s-806MB/s), io=100GiB (107GB), run=133287-133287msec

Disk stats (read/write):
  sdb: ios=409263/21, merge=0/5, ticks=67063742/43391, in_queue=67107135, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
Jobs: 1 (f=1): [R(1)][100.0%][r=769MiB/s][r=768 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=23876: Tue Feb 11 09:43:54 2025
  read: IOPS=768, BW=768MiB/s (806MB/s)(100GiB/133286msec)
    slat (usec): min=6, max=1384, avg=12.90, stdev= 9.79
    clat (msec): min=12, max=331, avg=166.58, stdev=20.32
     lat (msec): min=12, max=331, avg=166.59, stdev=20.32
    clat percentiles (msec):
     |  1.00th=[   85],  5.00th=[   89], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  169], 50.00th=[  169], 60.00th=[  171],
     | 70.00th=[  171], 80.00th=[  174], 90.00th=[  178], 95.00th=[  182],
     | 99.00th=[  194], 99.50th=[  199], 99.90th=[  218], 99.95th=[  264],
     | 99.99th=[  317]
   bw (  KiB/s): min=647168, max=862208, per=100.00%, avg=787425.20, stdev=10548.68, samples=266
   iops        : min=  632, max=  842, avg=768.97, stdev=10.30, samples=266
  lat (msec)   : 20=0.06%, 50=0.03%, 100=4.97%, 250=94.89%, 500=0.06%
  cpu          : usr=0.21%, sys=1.16%, ctx=102200, majf=0, minf=650
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=102400,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=768MiB/s (806MB/s), 768MiB/s-768MiB/s (806MB/s-806MB/s), io=100GiB (107GB), run=133286-133286msec

Disk stats (read/write):
  sdc: ios=409175/24, merge=0/10, ticks=67014490/234726, in_queue=67249216, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --iodepth=128 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=128
fio-3.23
Starting 1 process
Jobs: 1 (f=1): [R(1)][100.0%][r=770MiB/s][r=770 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=1): err= 0: pid=24357: Tue Feb 11 09:51:02 2025
  read: IOPS=768, BW=768MiB/s (806MB/s)(100GiB/133285msec)
    slat (usec): min=6, max=396, avg=12.61, stdev= 8.29
    clat (msec): min=11, max=340, avg=166.58, stdev=18.99
     lat (msec): min=11, max=340, avg=166.59, stdev=18.99
    clat percentiles (msec):
     |  1.00th=[   85],  5.00th=[  163], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  169], 50.00th=[  169], 60.00th=[  171],
     | 70.00th=[  171], 80.00th=[  174], 90.00th=[  178], 95.00th=[  180],
     | 99.00th=[  190], 99.50th=[  197], 99.90th=[  236], 99.95th=[  266],
     | 99.99th=[  326]
   bw (  KiB/s): min=645120, max=858112, per=100.00%, avg=787425.20, stdev=10509.60, samples=266
   iops        : min=  630, max=  838, avg=768.97, stdev=10.26, samples=266
  lat (msec)   : 20=0.06%, 50=0.03%, 100=4.32%, 250=95.54%, 500=0.06%
  cpu          : usr=0.19%, sys=1.14%, ctx=102297, majf=0, minf=653
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=99.9%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=102400,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=768MiB/s (806MB/s), 768MiB/s-768MiB/s (806MB/s-806MB/s), io=100GiB (107GB), run=133285-133285msec

Disk stats (read/write):
  sdd: ios=409183/32, merge=0/3, ticks=67076342/191595, in_queue=67267938, util=100.00%
```

**Remember to delete files after testing to free up space.**

```bash
rm /mnt/datadisk1/testfile
rm /mnt/datadisk2/testfile
rm /mnt/datadisk3/testfile
```

### 2.3_ Sequential Writing (4 Jobs)

```bash
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
```

#### Results

```bash
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 2 (f=1): [W(1),_(1),f(1),_(1)][100.0%][w=761MiB/s][w=760 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=25846: Tue Feb 11 10:18:27 2025
  write: IOPS=767, BW=767MiB/s (804MB/s)(400GiB/533878msec); 0 zone resets
    slat (usec): min=23, max=236609, avg=139.07, stdev=3250.58
    clat (msec): min=2, max=462, avg=166.66, stdev=15.51
     lat (msec): min=2, max=462, avg=166.79, stdev=15.19
    clat percentiles (msec):
     |  1.00th=[  107],  5.00th=[  165], 10.00th=[  167], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  167], 80.00th=[  167], 90.00th=[  169], 95.00th=[  169],
     | 99.00th=[  203], 99.50th=[  259], 99.90th=[  317], 99.95th=[  326],
     | 99.99th=[  338]
   bw (  KiB/s): min=520192, max=1022454, per=100.00%, avg=786975.07, stdev=6916.45, samples=4260
   iops        : min=  508, max=  997, avg=768.46, stdev= 6.75, samples=4260
  lat (msec)   : 4=0.01%, 10=0.05%, 20=0.09%, 50=0.21%, 100=0.55%
  lat (msec)   : 250=98.52%, 500=0.57%
  cpu          : usr=1.14%, sys=0.35%, ctx=402646, majf=0, minf=277
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,409600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=767MiB/s (804MB/s), 767MiB/s-767MiB/s (804MB/s-804MB/s), io=400GiB (429GB), run=533878-533878msec

Disk stats (read/write):
  sdb: ios=21/1640467, merge=0/2051, ticks=6441/298553303, in_queue=298559766, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 4 (f=4): [W(4)][99.8%][w=767MiB/s][w=766 IOPS][eta 00m:01s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=27077: Tue Feb 11 10:31:19 2025
  write: IOPS=765, BW=766MiB/s (803MB/s)(400GiB/534758msec); 0 zone resets
    slat (usec): min=26, max=171415, avg=99.82, stdev=2187.18
    clat (msec): min=2, max=397, avg=166.97, stdev=12.19
     lat (msec): min=2, max=397, avg=167.07, stdev=12.01
    clat percentiles (msec):
     |  1.00th=[  142],  5.00th=[  165], 10.00th=[  167], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  167], 80.00th=[  169], 90.00th=[  169], 95.00th=[  169],
     | 99.00th=[  192], 99.50th=[  226], 99.90th=[  300], 99.95th=[  313],
     | 99.99th=[  326]
   bw (  KiB/s): min=559104, max=1005568, per=100.00%, avg=785619.07, stdev=6142.98, samples=4268
   iops        : min=  546, max=  982, avg=767.20, stdev= 6.00, samples=4268
  lat (msec)   : 4=0.01%, 10=0.02%, 20=0.04%, 50=0.11%, 100=0.49%
  lat (msec)   : 250=99.00%, 500=0.33%
  cpu          : usr=1.11%, sys=0.34%, ctx=410871, majf=0, minf=305
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,409600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=766MiB/s (803MB/s), 766MiB/s-766MiB/s (803MB/s-803MB/s), io=400GiB (429GB), run=534758-534758msec

Disk stats (read/write):
  sdc: ios=10/1639296, merge=0/1266, ticks=7312/300545714, in_queue=300553037, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=write --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write-4-jobs: Laying out IO file (1 file / 102400MiB)
Jobs: 4 (f=4): [W(4)][100.0%][w=768MiB/s][w=768 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=29964: Tue Feb 11 11:08:10 2025
  write: IOPS=764, BW=765MiB/s (802MB/s)(400GiB/535552msec); 0 zone resets
    slat (usec): min=22, max=267301, avg=100.31, stdev=2222.74
    clat (msec): min=2, max=471, avg=167.22, stdev=13.22
     lat (msec): min=3, max=471, avg=167.32, stdev=13.05
    clat percentiles (msec):
     |  1.00th=[  146],  5.00th=[  165], 10.00th=[  167], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  167], 60.00th=[  167],
     | 70.00th=[  167], 80.00th=[  169], 90.00th=[  169], 95.00th=[  169],
     | 99.00th=[  209], 99.50th=[  241], 99.90th=[  309], 99.95th=[  326],
     | 99.99th=[  418]
   bw (  KiB/s): min=360448, max=1083392, per=100.00%, avg=784480.60, stdev=7170.40, samples=4275
   iops        : min=  352, max= 1058, avg=766.08, stdev= 7.00, samples=4275
  lat (msec)   : 4=0.01%, 10=0.02%, 20=0.04%, 50=0.11%, 100=0.48%
  lat (msec)   : 250=98.90%, 500=0.44%
  cpu          : usr=1.15%, sys=0.34%, ctx=409047, majf=0, minf=351
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,409600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=765MiB/s (802MB/s), 765MiB/s-765MiB/s (802MB/s-802MB/s), io=400GiB (429GB), run=535552-535552msec

Disk stats (read/write):
  sdd: ios=0/1638768, merge=0/1825, ticks=0/276328609, in_queue=276328645, util=100.00%
```

### 2.4_ Sequential Reading (4 Jobs)

```bash
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
```

#### Results

```bash
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
Jobs: 4 (f=4): [R(4)][99.8%][r=767MiB/s][r=767 IOPS][eta 00m:01s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=31804: Tue Feb 11 11:29:53 2025
  read: IOPS=764, BW=765MiB/s (802MB/s)(400GiB/535657msec)
    slat (usec): min=6, max=1940, avg=15.29, stdev= 8.51
    clat (msec): min=41, max=321, avg=167.35, stdev=13.29
     lat (msec): min=41, max=321, avg=167.36, stdev=13.29
    clat percentiles (msec):
     |  1.00th=[   86],  5.00th=[  165], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  169], 60.00th=[  169],
     | 70.00th=[  169], 80.00th=[  171], 90.00th=[  174], 95.00th=[  176],
     | 99.00th=[  194], 99.50th=[  197], 99.90th=[  201], 99.95th=[  205],
     | 99.99th=[  247]
   bw (  KiB/s): min=651264, max=856064, per=100.00%, avg=784299.57, stdev=5245.83, samples=4276
   iops        : min=  636, max=  836, avg=765.91, stdev= 5.12, samples=4276
  lat (msec)   : 50=0.02%, 100=2.12%, 250=97.85%, 500=0.01%
  cpu          : usr=0.10%, sys=0.36%, ctx=409838, majf=0, minf=2544
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=409600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=765MiB/s (802MB/s), 765MiB/s-765MiB/s (802MB/s-802MB/s), io=400GiB (429GB), run=535657-535657msec

Disk stats (read/write):
  sdb: ios=1638361/638, merge=0/33, ticks=269985736/22516844, in_queue=292502583, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
Jobs: 4 (f=4): [R(4)][99.8%][r=765MiB/s][r=765 IOPS][eta 00m:01s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=13119: Tue Feb 11 14:56:19 2025
  read: IOPS=767, BW=768MiB/s (805MB/s)(400GiB/533635msec)
    slat (usec): min=6, max=1126, avg=14.69, stdev= 7.41
    clat (msec): min=9, max=326, avg=166.72, stdev=12.16
     lat (msec): min=9, max=326, avg=166.73, stdev=12.16
    clat percentiles (msec):
     |  1.00th=[   86],  5.00th=[  165], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  169], 60.00th=[  169],
     | 70.00th=[  169], 80.00th=[  171], 90.00th=[  171], 95.00th=[  174],
     | 99.00th=[  180], 99.50th=[  182], 99.90th=[  190], 99.95th=[  194],
     | 99.99th=[  245]
   bw (  KiB/s): min=714752, max=860160, per=100.00%, avg=787249.71, stdev=2919.30, samples=4260
   iops        : min=  698, max=  840, avg=768.80, stdev= 2.85, samples=4260
  lat (msec)   : 10=0.01%, 20=0.01%, 50=0.01%, 100=1.94%, 250=98.03%
  lat (msec)   : 500=0.01%
  cpu          : usr=0.10%, sys=0.35%, ctx=409912, majf=0, minf=2411
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=409600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=768MiB/s (805MB/s), 768MiB/s-768MiB/s (805MB/s-805MB/s), io=400GiB (429GB), run=533635-533635msec

Disk stats (read/write):
  sdc: ios=1637657/21, merge=0/1, ticks=269185734/165307, in_queue=269351042, util=100.00%
$ fio --name=seq-write-4-jobs --ioengine=libaio --rw=read --bs=1M --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write-4-jobs: (g=0): rw=read, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
Jobs: 4 (f=4): [R(4)][100.0%][r=766MiB/s][r=766 IOPS][eta 00m:00s]
seq-write-4-jobs: (groupid=0, jobs=4): err= 0: pid=12434: Tue Feb 11 14:45:34 2025
  read: IOPS=768, BW=768MiB/s (805MB/s)(400GiB/533281msec)
    slat (usec): min=6, max=679, avg=15.06, stdev= 7.90
    clat (msec): min=4, max=317, avg=166.62, stdev=13.18
     lat (msec): min=5, max=317, avg=166.64, stdev=13.18
    clat percentiles (msec):
     |  1.00th=[   86],  5.00th=[  165], 10.00th=[  165], 20.00th=[  167],
     | 30.00th=[  167], 40.00th=[  167], 50.00th=[  169], 60.00th=[  169],
     | 70.00th=[  169], 80.00th=[  171], 90.00th=[  174], 95.00th=[  174],
     | 99.00th=[  178], 99.50th=[  180], 99.90th=[  184], 99.95th=[  190],
     | 99.99th=[  251]
   bw (  KiB/s): min=745472, max=862208, per=100.00%, avg=787775.52, stdev=2753.46, samples=4256
   iops        : min=  728, max=  842, avg=769.31, stdev= 2.69, samples=4256
  lat (msec)   : 10=0.01%, 20=0.01%, 50=0.01%, 100=2.34%, 250=97.64%
  lat (msec)   : 500=0.01%
  cpu          : usr=0.10%, sys=0.35%, ctx=409856, majf=0, minf=2397
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=409600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=768MiB/s (805MB/s), 768MiB/s-768MiB/s (805MB/s-805MB/s), io=400GiB (429GB), run=533281-533281msec

Disk stats (read/write):
  sdd: ios=1637979/31, merge=0/5, ticks=268849265/1847858, in_queue=270697124, util=100.00%
```

**Remember to delete files after testing to free up space.**

```bash
rm /mnt/datadisk1/testfile
rm /mnt/datadisk2/testfile
rm /mnt/datadisk3/testfile
```

### 2.5_ Random Writing

```bash
fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
```

#### Results

```bash
$ fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write: Laying out IO file (1 file / 102400MiB)
Jobs: 4 (f=4): [w(4)][100.0%][w=152MiB/s][w=38.9k IOPS][eta 00m:01s]
seq-write: (groupid=0, jobs=4): err= 0: pid=14982: Tue Feb 11 15:59:47 2025
  write: IOPS=38.1k, BW=149MiB/s (156MB/s)(400GiB/2751700msec); 0 zone resets
    slat (nsec): min=1560, max=464714k, avg=11823.48, stdev=328533.98
    clat (usec): min=159, max=508470, avg=3346.04, stdev=2039.97
     lat (usec): min=168, max=568006, avg=3357.97, stdev=2063.80
    clat percentiles (usec):
     |  1.00th=[  717],  5.00th=[ 2835], 10.00th=[ 2900], 20.00th=[ 2966],
     | 30.00th=[ 3064], 40.00th=[ 3163], 50.00th=[ 3294], 60.00th=[ 3392],
     | 70.00th=[ 3458], 80.00th=[ 3556], 90.00th=[ 3654], 95.00th=[ 3785],
     | 99.00th=[ 6390], 99.50th=[ 8291], 99.90th=[32637], 99.95th=[45876],
     | 99.99th=[77071]
   bw (  KiB/s): min=54032, max=431704, per=100.00%, avg=152655.77, stdev=2438.06, samples=21976
   iops        : min=13508, max=107926, avg=38163.95, stdev=609.52, samples=21976
  lat (usec)   : 250=0.01%, 500=0.35%, 750=0.72%, 1000=0.47%
  lat (msec)   : 2=0.86%, 4=95.07%, 10=2.16%, 20=0.18%, 50=0.14%
  lat (msec)   : 100=0.04%, 250=0.01%, 500=0.01%, 750=0.01%
  cpu          : usr=1.56%, sys=9.51%, ctx=78022196, majf=0, minf=1742
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,104857600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=149MiB/s (156MB/s), 149MiB/s-149MiB/s (156MB/s-156MB/s), io=400GiB (429GB), run=2751700-2751700msec

Disk stats (read/write):
  sdb: ios=1/107126272, merge=0/24000826, ticks=4/347604314, in_queue=347607437, util=100.00%
$ fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write: Laying out IO file (1 file / 102400MiB)
Jobs: 2 (f=2): [w(2),_(2)][100.0%][w=152MiB/s][w=38.8k IOPS][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=20071: Tue Feb 11 17:09:08 2025
  write: IOPS=38.1k, BW=149MiB/s (156MB/s)(400GiB/2750079msec); 0 zone resets
    slat (nsec): min=1524, max=304306k, avg=11742.30, stdev=304892.71
    clat (usec): min=164, max=327711, avg=3344.23, stdev=1909.80
     lat (usec): min=187, max=332808, avg=3356.06, stdev=1930.84
    clat percentiles (usec):
     |  1.00th=[  742],  5.00th=[ 2802], 10.00th=[ 2868], 20.00th=[ 2966],
     | 30.00th=[ 3032], 40.00th=[ 3163], 50.00th=[ 3294], 60.00th=[ 3392],
     | 70.00th=[ 3458], 80.00th=[ 3556], 90.00th=[ 3687], 95.00th=[ 3818],
     | 99.00th=[ 6063], 99.50th=[ 8356], 99.90th=[32900], 99.95th=[44827],
     | 99.99th=[69731]
   bw (  KiB/s): min=61328, max=437592, per=100.00%, avg=152743.26, stdev=2364.14, samples=21963
   iops        : min=15332, max=109398, avg=38185.81, stdev=591.03, samples=21963
  lat (usec)   : 250=0.01%, 500=0.34%, 750=0.68%, 1000=0.45%
  lat (msec)   : 2=0.82%, 4=94.88%, 10=2.48%, 20=0.18%, 50=0.15%
  lat (msec)   : 100=0.03%, 250=0.01%, 500=0.01%
  cpu          : usr=1.50%, sys=9.52%, ctx=77541826, majf=0, minf=1729
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,104857600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=149MiB/s (156MB/s), 149MiB/s-149MiB/s (156MB/s-156MB/s), io=400GiB (429GB), run=2750079-2750079msec

Disk stats (read/write):
  sdc: ios=0/107054385, merge=0/23934400, ticks=0/346722162, in_queue=346725441, util=100.00%
$ fio --name=seq-write --ioengine=libaio --rw=randwrite --bs=4k --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write: Laying out IO file (1 file / 102400MiB)
Jobs: 4 (f=3): [w(3),f(1)][100.0%][w=152MiB/s][w=38.9k IOPS][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=17967: Wed Feb 12 09:59:00 2025
  write: IOPS=38.1k, BW=149MiB/s (156MB/s)(400GiB/2750742msec); 0 zone resets
    slat (usec): min=2, max=440200, avg=15.66, stdev=367.05
    clat (usec): min=181, max=454181, avg=3340.90, stdev=2221.06
     lat (usec): min=197, max=454199, avg=3356.69, stdev=2248.21
    clat percentiles (usec):
     |  1.00th=[  660],  5.00th=[ 2769], 10.00th=[ 2900], 20.00th=[ 2999],
     | 30.00th=[ 3064], 40.00th=[ 3163], 50.00th=[ 3294], 60.00th=[ 3359],
     | 70.00th=[ 3458], 80.00th=[ 3523], 90.00th=[ 3654], 95.00th=[ 3785],
     | 99.00th=[ 6849], 99.50th=[ 8717], 99.90th=[34866], 99.95th=[51119],
     | 99.99th=[86508]
   bw (  KiB/s): min=32976, max=385373, per=100.00%, avg=152713.66, stdev=2444.96, samples=21968
   iops        : min= 8244, max=96343, avg=38178.42, stdev=611.24, samples=21968
  lat (usec)   : 250=0.01%, 500=0.42%, 750=0.89%, 1000=0.66%
  lat (msec)   : 2=1.41%, 4=93.78%, 10=2.43%, 20=0.20%, 50=0.15%
  lat (msec)   : 100=0.05%, 250=0.01%, 500=0.01%
  cpu          : usr=2.47%, sys=12.06%, ctx=72426067, majf=0, minf=4124
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,104857600,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=149MiB/s (156MB/s), 149MiB/s-149MiB/s (156MB/s-156MB/s), io=400GiB (429GB), run=2750742-2750742msec

Disk stats (read/write):
  sdd: ios=11/107077919, merge=0/24043780, ticks=24/341958655, in_queue=341962671, util=100.00%
```

### 2.6_ Random Reading

```bash
fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
```

#### Results

```bash
$ fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk1/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write: Laying out IO file (1 file / 102400MiB)
Jobs: 3 (f=0): [f(2),_(1),f(1)][100.0%][r=146MiB/s][r=37.4k IOPS][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=22399: Wed Feb 12 10:50:53 2025
  read: IOPS=38.8k, BW=152MiB/s (159MB/s)(400GiB/2699643msec)
    slat (nsec): min=1772, max=16769k, avg=8577.58, stdev=5298.88
    clat (usec): min=159, max=43557, avg=3285.76, stdev=150.28
     lat (usec): min=178, max=43566, avg=3294.45, stdev=150.22
    clat percentiles (usec):
     |  1.00th=[ 3097],  5.00th=[ 3163], 10.00th=[ 3195], 20.00th=[ 3228],
     | 30.00th=[ 3228], 40.00th=[ 3261], 50.00th=[ 3261], 60.00th=[ 3294],
     | 70.00th=[ 3326], 80.00th=[ 3359], 90.00th=[ 3392], 95.00th=[ 3458],
     | 99.00th=[ 3589], 99.50th=[ 3687], 99.90th=[ 4113], 99.95th=[ 4555],
     | 99.99th=[ 6718]
   bw (  KiB/s): min=152032, max=689752, per=100.00%, avg=155596.67, stdev=1821.07, samples=21564
   iops        : min=38008, max=172438, avg=38899.17, stdev=455.27, samples=21564
  lat (usec)   : 250=0.01%, 500=0.03%, 750=0.05%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=99.77%, 10=0.13%, 20=0.01%, 50=0.01%
  cpu          : usr=2.31%, sys=9.83%, ctx=85669011, majf=0, minf=295
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=104857600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=152MiB/s (159MB/s), 152MiB/s-152MiB/s (159MB/s-159MB/s), io=400GiB (429GB), run=2699643-2699643msec

Disk stats (read/write):
  sdb: ios=104849478/227991, merge=0/22116, ticks=344182896/533296, in_queue=344719336, util=100.00%
$ fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk2/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
seq-write: Laying out IO file (1 file / 102400MiB)
Jobs: 4 (f=4): [r(4)][100.0%][r=152MiB/s][r=38.9k IOPS][eta 00m:01s]
seq-write: (groupid=0, jobs=4): err= 0: pid=26409: Wed Feb 12 11:58:59 2025
  read: IOPS=38.8k, BW=152MiB/s (159MB/s)(400GiB/2699604msec)
    slat (nsec): min=1734, max=18477k, avg=6811.24, stdev=5674.05
    clat (usec): min=160, max=41722, avg=3287.29, stdev=154.45
     lat (usec): min=202, max=41729, avg=3294.22, stdev=154.38
    clat percentiles (usec):
     |  1.00th=[ 3097],  5.00th=[ 3163], 10.00th=[ 3195], 20.00th=[ 3228],
     | 30.00th=[ 3228], 40.00th=[ 3261], 50.00th=[ 3294], 60.00th=[ 3294],
     | 70.00th=[ 3326], 80.00th=[ 3359], 90.00th=[ 3392], 95.00th=[ 3458],
     | 99.00th=[ 3589], 99.50th=[ 3687], 99.90th=[ 4178], 99.95th=[ 4621],
     | 99.99th=[ 6980]
   bw (  KiB/s): min=151544, max=690584, per=100.00%, avg=155605.55, stdev=1829.84, samples=21561
   iops        : min=37886, max=172646, avg=38901.39, stdev=457.46, samples=21561
  lat (usec)   : 250=0.01%, 500=0.02%, 750=0.05%, 1000=0.02%
  lat (msec)   : 2=0.02%, 4=99.75%, 10=0.14%, 20=0.01%, 50=0.01%
  cpu          : usr=2.38%, sys=8.28%, ctx=86839963, majf=0, minf=1929
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=104857600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=152MiB/s (159MB/s), 152MiB/s-152MiB/s (159MB/s-159MB/s), io=400GiB (429GB), run=2699604-2699604msec

Disk stats (read/write):
  sdc: ios=104851587/233575, merge=0/37697, ticks=344570433/572783, in_queue=345146866, util=100.00%
$ fio --name=seq-write --ioengine=libaio --rw=randread --bs=4k --filename=/mnt/datadisk3/testfile --size=100GB --direct=1 --numjobs=4 --iodepth=32 --group_reporting
seq-write: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.23
Starting 4 processes
Jobs: 4 (f=4): [r(4)][100.0%][r=152MiB/s][r=38.8k IOPS][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=560: Wed Feb 12 13:57:24 2025
  read: IOPS=38.9k, BW=152MiB/s (159MB/s)(400GiB/2698908msec)
    slat (nsec): min=1732, max=22302k, avg=6395.42, stdev=4847.74
    clat (usec): min=42, max=51788, avg=3286.98, stdev=163.38
     lat (usec): min=225, max=51796, avg=3293.50, stdev=163.32
    clat percentiles (usec):
     |  1.00th=[ 3097],  5.00th=[ 3163], 10.00th=[ 3195], 20.00th=[ 3228],
     | 30.00th=[ 3228], 40.00th=[ 3261], 50.00th=[ 3294], 60.00th=[ 3294],
     | 70.00th=[ 3326], 80.00th=[ 3359], 90.00th=[ 3392], 95.00th=[ 3458],
     | 99.00th=[ 3556], 99.50th=[ 3654], 99.90th=[ 4080], 99.95th=[ 4490],
     | 99.99th=[ 7046]
   bw (  KiB/s): min=148753, max=686729, per=100.00%, avg=155638.14, stdev=1810.86, samples=21556
   iops        : min=37188, max=171682, avg=38909.54, stdev=452.71, samples=21556
  lat (usec)   : 50=0.01%, 250=0.01%, 500=0.03%, 750=0.06%, 1000=0.01%
  lat (msec)   : 2=0.02%, 4=99.78%, 10=0.11%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%
  cpu          : usr=2.31%, sys=7.91%, ctx=87561713, majf=0, minf=6003
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=100.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=104857600,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=152MiB/s (159MB/s), 152MiB/s-152MiB/s (159MB/s-159MB/s), io=400GiB (429GB), run=2698908-2698908msec

Disk stats (read/write):
  sdd: ios=104853821/227228, merge=0/21238, ticks=344623312/527267, in_queue=345153507, util=100.00%
```

**Remember to delete files after testing to free up space.**

```bash
rm /mnt/datadisk1/testfile
rm /mnt/datadisk2/testfile
rm /mnt/datadisk3/testfile
```

## 3_ Random I/O test with *fio* (Longhorn Volumes)
