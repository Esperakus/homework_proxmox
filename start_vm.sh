#!/bin/bash

ssh -l ${PROXMOX_USER} ${PROXMOX_ADDR} qm set ${VM_ID} --kvm 0 
ssh -l ${PROXMOX_USER} ${PROXMOX_ADDR} qm start ${VM_ID}
