#!/bin/bash
#==============================================================================
# register-system-using-rhel-key.sh
#
# Registers a RHEL system using a Red Hat Developer (or other) activation key.
# Free Red Hat Developer accounts give full access to all RHEL repos for up to
# 16 systems.
#
# Create your activation key here:
#   https://console.redhat.com/insights/connector/activation-keys
#
# Find your Organization ID by clicking your name in the top-right corner of
# the Hybrid Cloud Console.
#==============================================================================

set -euo pipefail

# ----------------------------- Configuration --------------------------------
KEYNAME="jtif-rhel8-rhel9-developer-key"
ORGID="16649499"
# -----------------------------------------------------------------------------

echo "=== RHEL Registration Script ==="
echo "Key name : $KEYNAME"
echo "Org ID   : $ORGID"
echo

# Reliable way to check if the system is already registered
if subscription-manager identity &>/dev/null; then
    echo "This system is ALREADY registered."
    echo
    echo "To re-register with a different key you must first unregister:"
    echo
    echo "  subscription-manager unregister"
    echo
    echo "After unregistering, run this script again."
    exit 1
fi

echo "System is not registered. Proceeding with registration..."
echo

# Attempt registration
if subscription-manager register --org="$ORGID" --activationkey="$KEYNAME"; then
    echo
    echo "✓ Registration successful!"
    echo "You can now sync repositories."
    exit 0
else
    echo
    echo "✗ Registration failed."
    echo
    echo "Please try the command manually as root:"
    echo
    echo "  subscription-manager register --org=\"$ORGID\" --activationkey=\"$KEYNAME\""
    echo
    exit 1
fi
