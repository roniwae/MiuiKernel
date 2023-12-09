#!/usr/bin/env bash
#
# Copyright (C) 2023 Edwiin Kusuma Jaya (ryuzenn)
#
# Simple Local Kernel Build Script
#
# Configured for Redmi Note 8 / ginkgo custom kernel source
#
# Setup build env with akhilnarang/scripts repo
#
# Use this script on root of kernel directory

SECONDS=0 # builtin bash timer
ZIPNAME="RyzenKernel-MiuiQ-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
TC_DIR="/workspace/clang"
AK3_DIR="/workspace/android/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"
sudo apt remove python* -y
sudo apt install python2 -y
export PATH="$TC_DIR/bin:${PATH}"
export KBUILD_BUILD_USER="@ronisaja"
export KBUILD_BUILD_HOST="CahaKemplo"
export KBUILD_BUILD_VERSION="1"

if ! [ -d "${TC_DIR}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
if ! git clone -b clang-12.0 --depth=1 https://github.com/roniwae/RastaMod69-Clang.git ${TC_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$TC_DIR/bin/aarch64-linux-gnu- CROSS_COMPILE_ARM32=$TC_DIR/bin/arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- 

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -b MIUI https://github.com/roniwae/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
bash <(curl -s https://devuploads.com/upload.sh) -f $ZIPNAME -k 23669v32wmlklwe4ir68j
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
rm $ZIPNAME
else
echo -e "\nCompilation failed!"
exit 1
fi
