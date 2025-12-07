#!/bin/bash

# Create a new user account on macOS
# Usage: ./create_user.sh username "Full Name"

USERNAME=$1
FULLNAME=$2

if [ -z "$USERNAME" ] || [ -z "$FULLNAME" ]; then
    echo "Usage: $0 username \"Full Name\""
    exit 1
fi

# Get the next available UID
MAXID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
NEWID=$((MAXID + 1))

# Create user
sudo dscl . -create /Users/$USERNAME
sudo dscl . -create /Users/$USERNAME UserShell /bin/zsh
sudo dscl . -create /Users/$USERNAME RealName "$FULLNAME"
sudo dscl . -create /Users/$USERNAME UniqueID $NEWID
sudo dscl . -create /Users/$USERNAME PrimaryGroupID 20
sudo dscl . -create /Users/$USERNAME NFSHomeDirectory /Users/$USERNAME

# Create home directory
sudo createhomedir -c -u $USERNAME

# Set password
sudo dscl . -passwd /Users/$USERNAME

echo "User $USERNAME created successfully with UID $NEWID"
