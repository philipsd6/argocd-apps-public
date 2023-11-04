#!/bin/sh

if uname -a | grep -q x86_64; then
	echo "x86_64"
	platform="amd64"
elif uname -a | grep -q aarch64; then
	echo "aarch64"
	platform="arm64"
else # neither amd64 or arm64
	echo "Unsupported CPU vendor: $(uname -a)" >&2
	exit 1
fi

asset_url=$(wget -q https://api.github.com/repos/cue-lang/cue/releases/latest -O- | awk -v platform="$platform" -F\" '$0 ~ "browser.*linux_"platform {print $4}')
wget "$asset_url" -O- |
	tar xz &&
	mv cue /usr/local/bin/cue &&
	chmod +x /usr/local/bin/cue
