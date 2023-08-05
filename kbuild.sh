#! /bin/bash

#
# Copyright (C) 2020 StarLight5234
# Copyright (C) 2021-22 GhostMaster69-dev
#

export DEVICE="VINCE"
export TC_PATH="$HOME/proton"
export ZIP_DIR="$(pwd)/AnyKernel3"
export KSU_DIR="$(pwd)/KernelSU"
export KERNEL_DIR=$(pwd)
export KBUILD_BUILD_VERSION="1"
export KBUILD_BUILD_USER="r"
export KBUILD_BUILD_HOST="r"
export KBUILD_BUILD_TIMESTAMP="$(TZ='Asia/Jakarta' date)"
export PLATFORM_VERSION="13"
export BUILD_ID="TQ3A.230705.001"
FINAL_KERNEL_ZIP=Unitrix-Kernel-vince-$(date '+%Y%m%d').zip

# Ask Telegram Channel/Chat ID
if [[ -z ${CHANNEL_ID} ]]; then
    echo -n "CHANNEL ID IS ${TG_CH}"
    CHANNEL_ID="${TG_CH}"
fi

# Ask Telegram Bot API Token
if [[ -z ${TELEGRAM_TOKEN} ]]; then
    echo -n "CHANNEL API IS: ${TG_API}"
    TELEGRAM_TOKEN="${TG_API}"
fi

if [[ -z ${UNITRIX_CHANNEL_ID} ]]; then
    UNITRIX_CHANNEL_ID=$CHANNEL_ID
fi

# Upload buildlog to group
tg_erlog()
{
	ERLOG=$HOME/build/build${BUILD}.txt
	curl -F document=@"$ERLOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build ran into errors after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs"
}

# Upload zip to channel
tg_pushzip() 
{
	FZIP=$ZIP_DIR/$ZIP
	curl -F document=@"$FZIP"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
		   -F chat_id=$UNITRIX_CHANNEL_ID
}

# Send Updates
function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id="${CHANNEL_ID}" \
		-d "disable_web_page_preview=true"
}

# Send a sticker
function start_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="CAACAgUAAxkBAAMPXvdff5azEK_7peNplS4ywWcagh4AAgwBAALQuClVMBjhY-CopowaBA" \
        -d chat_id=$CHANNEL_ID
}

function error_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="$STICKER" \
        -d chat_id=$CHANNEL_ID
}
function clone_tc() {
[ -d ${TC_PATH} ] || mkdir ${TC_PATH}
git clone --depth=1 https://github.com/kdrag0n/proton-clang.git ${TC_PATH}
PATH="${TC_PATH}/bin:$PATH"
export COMPILER=$(${TC_PATH}/bin/clang -v 2>&1 | grep ' version ' | sed 's/([^)]*)[[:space:]]//' | sed 's/([^)]*)//')
}

function clone_ksu() {
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
}

function clone_anykernel3() {
	if ! [ -d $ZIP_DIR ]; then
		git clone -b master https://github.com/AOSP-Silicon/AnyKernel3 $ZIP_DIR
	fi
}

# Make Kernel
build_kernel() {
DATE=`date`
BUILD_START=$(date +"%s")
make LLVM=1 LLVM_IAS=1 defconfig
make LLVM=1 LLVM_IAS=1 -j$(nproc --all) |& tee -a $HOME/build/build${BUILD}.txt
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
}

function make_flashable() {

cd $ZIP_DIR
cp $KERN_IMG $ZIP_DIR
ls $ZIP_DIR
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP
curl -T "../$FINAL_KERNEL_ZIP" https://pixeldrain.com/api/file/
if [ "$BRANCH" == "test" ]; then
	make test &>/dev/null
elif [ "$BRANCH" == "beta" ]; then
	make beta &>/dev/null
else
	make stable &>/dev/null
fi
ZIP="../$FINAL_KERNEL_ZIP"
tg_pushzip

}

# Credits: @madeofgreat
BTXT="$HOME/build/buildno.txt" #BTXT is Build number TeXT
if ! [ -a "$BTXT" ]; then
	mkdir $HOME/build
	touch $HOME/build/buildno.txt
	echo $RANDOM > $BTXT
fi

BUILD=$(cat $BTXT)
BUILD=$(($BUILD + 1))
echo ${BUILD} > $BTXT

stick=$(($RANDOM % 5))

if [ "$stick" == "0" ]; then
	STICKER="CAACAgUAAxkBAAMQXvdgEdkCuvPzzQeXML3J6srMN4gAAvIAA3PMoVfqdoREJO6DahoE"
elif [ "$stick" == "1" ];then
	STICKER="CAACAgQAAxkBAAMRXveCWisHv4FNMrlAacnmFRWSL0wAAgEBAAJyIUgjtWOZJdyKFpMaBA"
elif [ "$stick" == "2" ];then
	STICKER="CAACAgUAAxkBAAMSXveCj7P1y5I5AAGaH2wt2tMCXuqZAAL_AAO-xUFXBB9-5f3MjMsaBA"
elif [ "$stick" == "3" ];then
	STICKER="CAACAgUAAxkBAAMTXveDSSQq2q8fGrIvpmJ4kPx8T1AAAhEBAALKhyBVEsDSQXY-jrwaBA"
elif [ "$stick" == "4" ];then
	STICKER="CAACAgUAAxkBAAMUXveDrb4guQZSu7mP7ZptE4547PsAAugAA_scAAFXWZ-1a2wWKUcaBA"
fi

# Upload build logs file on telegram channel
function tg_push_logs() {
	LOG=$HOME/build/build${BUILD}.txt
	curl -F document=@"$LOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
        -F chat_id=$CHANNEL_ID \
        -F caption="Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
}

# Start cloning toolchain
clone_tc
clone_ksu

COMMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
KERNEL_DIR=$(pwd)
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
VENDOR_MODULEDIR="$ZIP_DIR/modules/vendor/lib/modules"
export KERN_VER=$(echo "$(make --no-print-directory kernelversion)")

# Cleaning source
make mrproper && rm -rf out

start_sticker
tg_sendinfo "$(echo -e "======= <b>$DEVICE</b> =======\n
Build-Host   :- <b>$KBUILD_BUILD_HOST</b>
Build-User   :- <b>$KBUILD_BUILD_USER</b>\n 
Version      :- <u><b>$KERN_VER</b></u>
Compiler     :- <i>$COMPILER</i>\n
on Branch    :- <b>$BRANCH</b>
Commit       :- <b>$COMMIT</b>\n")"

build_kernel
clone_anykernel3

# Check if kernel img is there or not and make flashable accordingly

if ! [ -a "$KERN_IMG" ]; then
	tg_erlog && error_sticker
	exit 1
else
	tg_push_logs && make_flashable
fi
