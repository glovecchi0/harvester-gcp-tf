#!/bin/bash

LOGFILE="/var/log/restart_harvester_vms_script.log"

# Restart nested VMs that for some reason are not running ('shut off' state)
virsh list --all | awk '$3 == "shut" {print $2}' | while read -r vm; do
    if [[ -n "$vm" ]]; then
        echo "$(date): Starting VM $vm" | tee -a "$LOGFILE"
        virsh start "$vm" >>"$LOGFILE" 2>&1
    fi
done
