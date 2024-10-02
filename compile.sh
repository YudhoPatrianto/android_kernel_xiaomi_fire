#!/usr/bin/env bash

# Environment BOT
read -p "Input Your Telegram Token BOT: " token
read -p "Input Your Chat ID Or UserID: " chat_id
export endpoint="https://api.telegram.org/bot${token}"

# Environment Build
read -p "Input Your Path Of Clang Example: (/home/user/clang/bin): " clang_dir
codename=$1
defconfig=$(find arch/arm64/configs -name "*${codename}_defconfig*" | sed 's|arch/arm64/configs/||')
kernel_url=$(git remote -v | head -n 1 | sed 's/ (fetch)//; s/^origin[[:space:]]\+//; s/https:\/\/[^@]*@/https:\/\//')
kernel_branch=$(git branch | sed 's/* //' | head -n 1)
workdir=$(pwd)
clang_version=$(${clang_dir}/clang --version | head -n 1 | sed 's|git (https://github.com/llvm/llvm-project f2f9cdd22171f0c54cad7c6b183857f3d856c344)||')

# Notify Build
function alert_build() {
    curl -s -X POST "${endpoint}/sendMessage" \
    -d chat_id="${chat_id}" \
    -d text="<b>Kernel URL Repository:</b> <code>${kernel_url}</code>%0A\
<b>Kernel URL Branch:</b> <code>${kernel_branch}</code>%0A\
<b>Defconfig:</b> <code>${defconfig}</code>%0A\
<b>Codename:</b> <code>${codename}</code>%0A\
<b>Workdir:</b> <code>${workdir}</code>%0A\
<b>Clang Version:</b> <code>${clang_version}</code>%0A\
%0A%0A<b>Build Started!!</b>" \
    -d parse_mode='HTML' \
    > /dev/null 2>&1
}

alert_build # Alert Build

function build_kernel() {
    # Information Kernel
    export BUILD_USERNAME="YudhoPatrianto"
    export BUILD_HOSTNAME="YudhoPRJKT"
    export KBUILD_BUILD_USER=${BUILD_USERNAME}
    export KBUILD_BUILD_HOST=${BUILD_HOSTNAME}
    
    # Create Directory out
    mkdir -p out

    # Build Kernel
    export PATH="${clang_dir}:${PATH}"
    export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
        make -j$(nproc --all) O=out ARCH=arm64 ${defconfig} 2>&1 | tee out/compile_${defconfig}.log 
        make -j$(nproc --all) ARCH=arm64 O=out \
                                CC=clang \
                                CROSS_COMPILE_COMPAT=aarch64-linux-gnu- \
                                CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee out/compile_${defconfig}.log
}

function time_utils() {
    start=$(date +%s)
    build_kernel
    end=$(date +%s)
    result=$((end - start))

    # Export Time Into Variable
    hours=$((result / 3600))
    minutes=$(((result % 3600) / 60))
    seconds=$((result % 60))
}

time_utils # Start Time Utils
export log_dir=${workdir}/out/compile_${defconfig}.log

read_logs=$(cat ${log_dir})

if [[ "${read_logs}" == *"error"* ]]; then
    curl -s -X POST ${endpoint}/SendDocument \
    -F chat_id=${chat_id} \
    -F "disable_web_page_preview=true" \
    -F "document=@${log_dir}" \
    -F "caption=*Build Failed Took* \`${hours}\`*h* \`${minutes}\`*m* \`${seconds}\`*s*" \
    -F parse_mode="Markdown" \
    > /dev/null 2>&1
else
    curl -s -X GET "${endpoint}/SendDocument" \
    -F chat_id=${chat_id} \
    -F "disable_web_page_preview=true" \
    -F "document=@${log_dir}" \
    -F "caption=*Build Success Took \`${hours}\`*h* \`${minutes}\`*m* \`${seconds}\`*s*" \
    -F parse_mode="Markdown" \
    > /dev/null 2>&1
fi

rm -rf out
