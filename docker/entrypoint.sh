#!/usr/bin/dumb-init bash

# Copyright (C) 2025 Codiax Sweden AB
# SPDX-License-Identifier: GPL-2.0-or-later

# Check for USERID and set it automatically to owner of workdir if not given
[ -z "${USERID}" ] && USERID=$(stat -c '%u' .)
[ -z "${GROUPID}" ] && GROUPID=$(stat -c '%g' .)

# Do not allow for instance USERID=0
(( "${USERID}" < 1000 )) && { echo "USERID must be >= 1000"; exit 1; }
(( "${GROUPID}" == 0 )) && { echo "GROUPID must be != 0"; exit 1; }

# Recent versions of Ubuntu come with a pre-created "ubuntu" user with id 1000
# Make sure USERID is not taken by some other user than "user"
# Avoid to remove any files to not create a security problem if user's home
# is mapped to some dir on the host
groupadd user -g ${GROUPID} -o 2>/dev/null \
	|| groupmod user -g ${GROUPID} -o
useradd user -u ${USERID} -g user -o --create-home 2>/dev/null \
	|| usermod user -u ${USERID} -g user -o -d /home/user
mkdir -p /home/user && chown user:user /home/user

/usr/sbin/gosu user "$@"
