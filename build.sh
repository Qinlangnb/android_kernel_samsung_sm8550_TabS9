#!/bin/bash
TOOLCHAIN=$(realpath "/home/kokuban/PlentyofToolchain/toolchainS23/prebuilts")

export PATH=$TOOLCHAIN/build-tools/linux-x86/bin:$PATH
export PATH=$TOOLCHAIN/build-tools/path/linux-x86:$PATH
export PATH=$TOOLCHAIN/clang/host/linux-x86/clang-r450784e/bin:$PATH
export PATH=$TOOLCHAIN/clang-tools/linux-x86/bin:$PATH

echo $PATH

set -e

LTO=thin

TARGET_DEFCONFIG=${1:-kalama_gki_defconfig}

cd "$(dirname "$0")"

LOCALVERSION=-android13-Kokuban-Hutao-CYD9-LKM

ARGS="
CC=clang
ARCH=arm64
LLVM=1 LLVM_IAS=1
LOCALVERSION=$LOCALVERSION
"

# build kernel
make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS} $TARGET_DEFCONFIG

./scripts/config --file out/.config \
  -d UH \
  -d RKP \
  -d KDP \
  -d SECURITY_DEFEX \
  -d INTEGRITY \
  -d FIVE \
  -d TRIM_UNUSED_KSYMS

if [ "$LTO" = "thin" ]; then
  ./scripts/config --file out/.config -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS}

# pack AnyKernel3
cd out
if [ ! -d AnyKernel3 ]; then
  git clone --depth=1 https://github.com/YuzakiKokuban/AnyKernel3.git -b kalama_tab
fi
cp arch/arm64/boot/Image AnyKernel3/zImage
name=TabS9_kernel_`cat include/config/kernel.release`_`date '+%Y_%m_%d'`
cd AnyKernel3
zip -r ${name}.zip * -x *.zip
echo "AnyKernel3 package output to $(realpath $name).zip"
