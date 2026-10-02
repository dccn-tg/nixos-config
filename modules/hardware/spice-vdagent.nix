# A system-wide daemon that communicates with the hypervisor over a virtio serial port for
#  - clipboard sharing
#  - automatic resolution adjustment
#  - file transfer
#  - seamless mouse integration
# in a VM environment. This is useful for virtual machines running on QEMU/KVM, VirtualBox, and VMware.
{
  services.spice-vdagentd.enable = true;
}