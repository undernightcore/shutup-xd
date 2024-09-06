#!/bin/bash

# Check that the Docker host IPMI device (the iDRAC) has been exposed to the Docker container
if [ ! -e "/dev/ipmi0" ] && [ ! -e "/dev/ipmi/0" ] && [ ! -e "/dev/ipmidev/0" ]; then
echo "/!\ Could not open device at /dev/ipmi0 or /dev/ipmi/0 or /dev/ipmidev/0, check that you added the device to your Docker container or stop using local mode. Exiting." >&2
exit 1
fi

ipmitool -I open sdr type temperature