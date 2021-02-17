#!/bin/bash
clear
echo "#######################################"
echo "##### OKAMI Kernel - Build Script #####"
echo "#######################################"
# Built in Functions
# ==================
has_param(){
  local term="$1"
  shift
  for arg; do
    if [[ -z "$arg" ]]; then
      return 2
    fi
    if [[ $arg == "$term" ]]; then
      return 0
    fi
  done
  return 1
}

# ENV configuration
# =================
if [ -z "$LOUP_WORKING_DIR" ]
then
  export LOUP_WORKING_DIR=$(dirname "$(pwd)")
fi

# Create "out" dir to avoid compilation issues
mkdir -p $(pwd)/out

start=$SECONDS

# Want custom kernel flags?
# =========================
# KBUILD_LOUP_CFLAGS: Here you can set custom compilation 
# flags to turn off unwanted warnings, or even set a 
# different optimization level. 
# To see how it works, check the Makefile ... file, 
# line 625 to 628, located in the root dir of this kernel.
KBUILD_OKAMI_CFLAGS="-mtune=cortex-a53 -march=armv8-a+crc+simd+crypto -mcpu=cortex-a53 -O2"

# Kernel Configuration
# ====================
if [ -f "out/.config" ]
  then    
    echo -e "\033[0;32m> Config file already exists\033[0;0m\n"
  else
    echo -e "\033[0;31m> Config file not found, copying santoni_defconfig as .config...\033[0;0m\n" 
    cp arch/arm64/configs/santoni_defconfig out/.config
fi

# Test if we need menuconfig or not
# source: https://stackoverflow.com/a/56431189
# =================================
if has_param '-no-menuconfig' "$@"; then
  echo -e "> Skipping menuconfig...\n"
else
  echo -e "> Opening .config file...\n"
  make menuconfig O=out ARCH=arm64
fi

PATH="$LOUP_WORKING_DIR/proton-clang/bin:$PATH" \
make -j$(nproc --all) O=out \
	ARCH=arm64 \
	SUBARCH=arm64 \
	CC=clang \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	KBUILD_OKAMI_CFLAGS="$KBUILD_OKAMI_CFLAGS"

if [ $? -eq 0 ]
then
  # Get current kernel version
  LOUP_VERSION=$(head -n3 Makefile | sed -E 's/.*(^\w+\s[=]\s)//g' | xargs | sed -E 's/(\s)/./g')
  echo -e "\n\n> Packing Ōkami Kernel v$LOUP_VERSION\n\n"
  # Pack the kernel as a flashable TWRP zip. Nougat Edition
  $LOUP_WORKING_DIR/AnyKernel3/build.sh $LOUP_VERSION 10 Ōkami

  end=$SECONDS
  duration=$(( end - start ))
  printf "\n\033[0;33m> Completed in %dh:%dm:%ds\n" $(($duration/3600)) $(($duration%3600/60)) $(($duration%60))
  echo -e "=====================================\033[0;0m\n"
else
  echo -e "\033[0;31m> Compilation failed, exiting...\033[0;0m\n"
  exit 1
fi
