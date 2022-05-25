#!/bin/bash

if [ -z "$1" ]; then
	echo "usage: $0 <linux_dir>"
	exit 1
fi

linux_ver="5.9 5.10 5.11 5.12 5.13 5.14 5.15 5.16 5.17"

curdir=.
cd $1

for ver in $linux_ver; do
	git checkout -b linux-$ver.y origin/linux-$ver.y
	if [ -f scripts/bpf_helpers_doc.py ]; then
		cp -v scripts/bpf_helpers_doc.py $curdir/scripts/bpf_doc-$ver.py
	elif [ -f scripts/bpf_doc.py ]; then
		cp -v scripts/bpf_doc.py $curdir/scripts/bpf_doc-$ver.py
	fi
done
