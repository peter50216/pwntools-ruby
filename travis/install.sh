#!/usr/bin/env bash -e
set -e
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

setup_linux()
{
  export LD_LIBRARY_PATH=$PWD/usr/lib:$LD_LIBRARY_PATH
  sudo apt-get install -qq --force-yes libgd2-xpm ia32-libs ia32-libs-multiarch binutils > /dev/null
  install_deb libcapstone3
}

setup_osx()
{
  brew install capstone
  export DYLD_LIBRARY_PATH=/usr/local/opt/capstone/lib/:$DYLD_LIBRARY_PATH
}

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  setup_osx
elif [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  setup_linux
fi
set +e