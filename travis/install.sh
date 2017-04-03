#!/usr/bin/env bash
set -e -x
local_deb_extract()
{
  wget $1
  ar vx *.deb
  tar xvf data.tar.*
  rm -f *.tar.* *deb*
}

install_deb()
{
  version=${2:-zesty}
  package=$1
  echo "Installing $package"
  INDEX="http://packages.ubuntu.com/en/$version/amd64/$package/download"
  URL=$(curl "$INDEX" | grep -Eo "https?://.*$package.*\.deb" | head -1)
  local_deb_extract "$URL"
}

install_keystone_from_source()
{
  # keystone can only build from source
  # https://github.com/keystone-engine/keystone/blob/master/docs/COMPILE-NIX.md
  #
  # XXX: how to prevent compile every time on Travis-CI?
  git clone https://github.com/keystone-engine/keystone.git -o keystone || echo 'clone keystone done'
  mkdir keystone/build && cd keystone/build
  ../make-share.sh
  cd ../..
  export LD_LIBRARY_PATH=$PWD/keystone/build/llvm/lib:$LD_LIBRARY_PATH
}

setup_linux()
{
  sudo apt-get install -qq --force-yes gcc-multilib g++-multilib binutils > /dev/null
  # install capstone
  install_deb libcapstone3
  export LD_LIBRARY_PATH=$PWD/usr/lib:$LD_LIBRARY_PATH

  # install keystone
  install_keystone_from_source
}

setup_osx()
{
  # install capstone
  brew install capstone
  export DYLD_LIBRARY_PATH=/usr/local/opt/capstone/lib/:$DYLD_LIBRARY_PATH

  # install keystone
  install_keystone_from_source
}

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  setup_osx
elif [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  setup_linux
fi
set +e +x
