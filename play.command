#!/bin/sh
cd -- "$(dirname -- "$0")" || exit 1
if command -v love >/dev/null 2>&1; then
    exec love .
elif [ -x /Applications/love.app/Contents/MacOS/love ]; then
    exec /Applications/love.app/Contents/MacOS/love .
else
    echo 'Install LÖVE 11.5 from https://love2d.org, then run this launcher again.'
    read -r answer
fi
