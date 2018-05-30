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
  INDEX="https://packages.ubuntu.com/en/xenial/amd64/$package/download"
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
  # rvm do lots of things on OSX when cwd changing.. use bash without rvm to prevent
  /bin/bash --norc -c 'mkdir keystone/build && cd keystone/build && ../make-share.sh'
}

setup_linux()
{
  sudo apt-get update
  sudo apt-get install --force-yes gcc-multilib g++-multilib binutils
  # install capstone
  install_deb libcapstone3
  export LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/usr/lib:$LD_LIBRARY_PATH

  # install keystone
  install_keystone_from_source
  export LD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/keystone/build/llvm/lib:$LD_LIBRARY_PATH
}

setup_osx()
{
  # install capstone
  brew install capstone
  export DYLD_LIBRARY_PATH=/usr/local/opt/capstone/lib:$DYLD_LIBRARY_PATH

  # install keystone
  install_keystone_from_source
  ln -s keystone/build/llvm/lib/libkeystone.dylib libkeystone.dylib # hack, don't know why next line has no effect
  # export DYLD_LIBRARY_PATH=$TRAVIS_BUILD_DIR/keystone/build/llvm/lib:$DYLD_LIBRARY_PATH
}

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  setup_osx
elif [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  setup_linux
fi
set +e +x
