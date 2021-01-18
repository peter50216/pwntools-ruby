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
  package=$1
  echo "Installing $package"
  INDEX="https://packages.ubuntu.com/en/bionic/amd64/$package/download"
  URL=$(curl "$INDEX" | grep -Eo "https?://.*$package.*\.deb" | head -1)
  local_deb_extract "$URL"
}

install_keystone_from_source()
{
  # keystone can only build from source
  # https://github.com/keystone-engine/keystone/blob/master/docs/COMPILE-NIX.md
  #
  # XXX(david942j): How to prevent compile every time on Travis-CI?
  git clone https://github.com/keystone-engine/keystone.git
  # rvm does lots of things on OSX when cwd changing.. use bash without rvm to prevent this.
  /bin/bash --norc -c 'mkdir keystone/build && cd keystone/build && ../make-share.sh'
}

setup_linux()
{
  sudo apt update
  sudo apt install --force-yes gcc-multilib g++-multilib binutils socat
  # install capstone
  sudo apt install libcapstone3

  # install keystone
  install_keystone_from_source
}

setup_osx()
{
  # install capstone
  brew install capstone

  # install keystone
  install_keystone_from_source
  # hack, don't know why set DYLD_LIBRARY_PATH has no effect
  ln -s keystone/build/llvm/lib/libkeystone.dylib libkeystone.dylib

  # install socat
  brew install socat
}

if [[ "$1" == "macOS" ]]; then
  setup_osx
elif [[ "$1" == "Linux" ]]; then
  setup_linux
fi

set +e +x
