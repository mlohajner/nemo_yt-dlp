#!/bin/bash

if [ "$1" = "$HOME/Desktop" ]; then
	exit 1
fi

[ -d "$1" ]
