##Resource allocation (captured at step start)
CPUs (nproc): 4

### Memory (free -h):
               total        used        free      shared  buff/cache   available
Mem:           5.9Gi       2.3Gi       2.8Gi        69Mi       810Mi       3.2Gi
Swap:          2.1Gi       1.6Gi       463Mi

### Disk (df -h for repo root):
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda3        98G   62G   33G  66% /


## Resoruce allocation (captured during build)

### Memory (free -h):
               total        used        free      shared  buff/cache   available
Mem:           5.9Gi       3.3Gi       1.6Gi        79Mi       1.0Gi       2.2Gi
Swap:          2.1Gi       1.6Gi       472Mi

### Disk (df -h)
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           601M  2.0M  599M   1% /run
/dev/sda3        98G   62G   32G  66% /
tmpfs           3.0G  151M  2.8G   6% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/sda2       512M  6.1M  506M   2% /boot/efi
tmpfs           601M  104K  601M   1% /run/user/1000
/dev/sr1        4.7G  4.7G     0 100% /media/brad/Ubuntu 22.04.4 LTS amd64