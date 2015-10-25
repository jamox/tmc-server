#!/bin/bash
SANDBOX=$(git submodule status ext/tmc-sandbox | grep -E -o  "[0-9a-f]{40}")
if [ -d sandbox-cache/$SANDBOX ]
then
  cp sandbox-cache/$SANDBOX/{linux.uml,initrd.img,rootfs.squashfs} ext/tmc-sandbox/uml
else
  echo $(git submodule status ext/tmc-sandbox | grep -E -o  "[0-9a-f]{40}")
  wget  http://testmycode.net/travis/sandbox-$(git submodule status ext/tmc-sandbox | grep -E -o  "[0-9a-f]{40}").tar.gz -O sandbox.tar.gz
  tar xvz sandbox.tar.gz -C ext/
fi
