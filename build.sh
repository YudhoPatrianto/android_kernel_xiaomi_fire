#!/bin/bash

function compile() 
{
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G
export ARCH=arm64
export KBUILD_BUILD_HOST="ECLIPSExDEV"
export KBUILD_BUILD_USER="Shub"

if [ -d "clang" ];
then
echo Clang directory already exists
else
wget --quiet https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/529a8adc22e54aecc2278960d1a6d84967fb7318/clang-r433403b.tar.gz -O "aosp-clang.tar.gz"
mkdir clang && tar -xf aosp-clang.tar.gz -C clang && rm -f aosp-clang.tar.gz
fi
git clone --depth=1 https://github.com/shub876/aarch64-linux-android-4.9.git arm64
git clone --depth=1 https://github.com/shub876/arm-linux-androideabi-4.9.git arm32

rm -rf out
mkdir out
rm -rf Anykernel3
rm -rf error.log

make O=out ARCH=arm64 fire_defconfig
PATH="${PWD}/clang/bin:${PWD}/arm64/bin:${PWD}/arm32/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      LLVM=1 \
                      LLVM_IAS=1 \
                      ARCH=arm64 \
                      CC="clang" \
                      LD=ld.lld \
                      STRIP=llvm-strip \
                      AS=llvm-as \
		              AR=llvm-ar \
		              NM=llvm-nm \
		              OBJCOPY=llvm-objcopy \
		              OBJDUMP=llvm-objdump \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${PWD}/arm64/bin/aarch64-linux-android-" \
                      CROSS_COMPILE_ARM32="${PWD}/arm32/bin/arm-linux-androideabi-" \
		              CROSS_COMPILE_COMPAT="${PWD}/arm32/bin/arm-linux-androideabi-" \
                      CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log 
}

function upload()
{	
git clone --depth=1 https://github.com/shub876/Anykernel3.git -b fire Anykernel3
cp out/arch/arm64/boot/Image.gz Anykernel3
cd Anykernel3
zip -r9 ECLIPSE-OSS-KERNEL-FIRE-T.zip *
curl --upload-file "ECLIPSE-OSS-KERNEL-FIRE-T.zip" https://free.keep.sh
curl bashupload.com -T ECLIPSE-OSS-KERNEL-FIRE-T.zip
}
compile
upload
