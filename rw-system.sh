#!/system/bin/sh

#Uncomment me to output sh -x of this script to /cache/phh/logs
#if [ -z "$debug" ];then
#	mkdir -p /cache/phh
#	debug=1 exec sh -x "$(readlink -f -- "$0")" > /cache/phh/logs 2>&1
#fi

vndk="$(getprop persist.sys.vndk)"
[ -z "$vndk" ] && vndk="$(getprop ro.vndk.version |grep -oE '^[0-9]+')"
setprop sys.usb.ffs.aio_compat true

fixSPL() {
    if [ "$(getprop ro.product.cpu.abi)" = "armeabi-v7a" ]; then
        setprop ro.keymaster.mod 'AOSP on ARM32'
    else
        setprop ro.keymaster.mod 'AOSP on ARM64'
    fi
    img="$(find /dev/block -type l -name kernel"$(getprop ro.boot.slot_suffix)" | grep by-name | head -n 1)"
    [ -z "$img" ] && img="$(find /dev/block -type l -name boot"$(getprop ro.boot.slot_suffix)" | grep by-name | head -n 1)"
    if [ -n "$img" ]; then
        #Rewrite SPL/Android version if needed
        Arelease="$(getSPL "$img" android)"
        setprop ro.keymaster.xxx.release "$Arelease"
        setprop ro.keymaster.xxx.security_patch "$(getSPL "$img" spl)"

        getprop ro.vendor.build.fingerprint | grep -qiE '^samsung/' && return 0
        for f in \
            /vendor/lib64/hw/android.hardware.keymaster@3.0-impl-qti.so /vendor/lib/hw/android.hardware.keymaster@3.0-impl-qti.so \
            /system/lib64/vndk-26/libsoftkeymasterdevice.so /vendor/bin/teed \
            /system/lib64/vndk/libsoftkeymasterdevice.so /system/lib/vndk/libsoftkeymasterdevice.so \
            /system/lib/vndk-26/libsoftkeymasterdevice.so \
            /system/lib/vndk-27/libsoftkeymasterdevice.so /system/lib64/vndk-27/libsoftkeymasterdevice.so; do
            [ ! -f "$f" ] && continue
            # shellcheck disable=SC2010
            ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
            b="$(echo "$f" | tr / _)"

            cp -a "$f" "/mnt/phh/$b"
            sed -i \
                -e 's/ro.build.version.release/ro.keymaster.xxx.release/g' \
                -e 's/ro.build.version.security_patch/ro.keymaster.xxx.security_patch/g' \
                -e 's/ro.product.model/ro.keymaster.mod/g' \
                "/mnt/phh/$b"
            chcon "$ctxt" "/mnt/phh/$b"
            mount -o bind "/mnt/phh/$b" "$f"
        done
        if [ "$(getprop init.svc.keymaster-3-0)" = "running" ]; then
            setprop ctl.restart keymaster-3-0
        fi
        if [ "$(getprop init.svc.teed)" = "running" ]; then
            setprop ctl.restart teed
        fi
    fi
}

changeKeylayout() {
    cp -a /system/usr/keylayout /mnt/phh/keylayout
    changed=false

    if getprop ro.vendor.build.fingerprint |
        grep -qE -e "^samsung"; then
        changed=true

        cp /system/phh/samsung-gpio_keys.kl /mnt/phh/keylayout/gpio_keys.kl
        cp /system/phh/samsung-sec_touchscreen.kl /mnt/phh/keylayout/sec_touchscreen.kl
        chmod 0644 /mnt/phh/keylayout/gpio_keys.kl /mnt/phh/keylayout/sec_touchscreen.kl
    fi

    if getprop ro.vendor.build.fingerprint | grep -iq \
        -e xiaomi/polaris -e xiaomi/sirius -e xiaomi/dipper \
        -e xiaomi/wayne -e xiaomi/jasmine -e xiaomi/jasmine_sprout \
        -e xiaomi/platina -e iaomi/perseus -e xiaomi/ysl \
        -e xiaomi/nitrogen -e xiaomi/daisy -e xiaomi/sakura \
        -e xiaomi/whyred -e xiaomi/tulip; then
        if [ ! -f /mnt/phh/keylayout/uinput-goodix.kl ]; then
          cp /system/phh/empty /mnt/phh/keylayout/uinput-goodix.kl
          chmod 0644 /mnt/phh/keylayout/uinput-goodix.kl
          changed=true
        fi
        if [ ! -f /mnt/phh/keylayout/uinput-fpc.kl ]; then
          cp /system/phh/empty /mnt/phh/keylayout/uinput-fpc.kl
          chmod 0644 /mnt/phh/keylayout/uinput-fpc.kl
          changed=true
        fi
    fi

    if getprop ro.vendor.build.fingerprint | grep -qi oneplus/oneplus6/oneplus6; then
        cp /system/phh/oneplus6-synaptics_s3320.kl /mnt/phh/keylayout/synaptics_s3320.kl
        chmod 0644 /mnt/phh/keylayout/synaptics_s3320.kl
        changed=true
    fi

    if getprop ro.vendor.build.fingerprint | grep -iq -e iaomi/perseus -e iaomi/cepheus; then
        cp /system/phh/mimix3-gpio-keys.kl /mnt/phh/keylayout/gpio-keys.kl
        chmod 0644 /mnt/phh/keylayout/gpio-keys.kl
        changed=true
    fi

    if getprop ro.vendor.build.fingerprint | grep -iq -E -e '^Sony/G834'; then
        cp /system/phh/sony-gpio-keys.kl /mnt/phh/keylayout/gpio-keys.kl
        chmod 0644 /mnt/phh/keylayout/gpio-keys.kl
        changed=true
    fi

    if [ "$changed" = true ]; then
        mount -o bind /mnt/phh/keylayout /system/usr/keylayout
        restorecon -R /system/usr/keylayout
    fi
}

if mount -o remount,rw /system; then
    resize2fs "$(grep ' /system ' /proc/mounts | cut -d ' ' -f 1)" || true
elif mount -o remount,rw /; then
    major="$(stat -c '%D' /.|sed -E 's/^([0-9a-f]+)([0-9a-f]{2})$/\1/g')"
    minor="$(stat -c '%D' /.|sed -E 's/^([0-9a-f]+)([0-9a-f]{2})$/\2/g')"
    mknod /dev/tmp-phh b $((0x$major)) $((0x$minor))
    resize2fs /dev/root || true
    resize2fs /dev/tmp-phh || true
fi



if [ "$(getprop ro.hardware)" = "hi3650" ]; then
    libs=( "android.hardware.camera.common@1.0.so" "android.hardware.configstore@1.0.so" "libcamera_metadata.so" "libnativebridge.so" "libpng.so" "libziparchive.so" "android.hardware.camera.device@1.0.so" "android.hardware.configstore-utils.so" "libdng_sdk.so" "libicui18n.so" "libnativehelper.so" "libskia.so" "android.hardware.camera.device@3.2.so" "android.hidl.allocator@1.0.so" "libexpat.so" "libicuuc.so" "libnativeloader.so" "libui.so" "android.hardware.camera.provider@2.4.so" "libbinder.so" "libfmq.so" "libjpeg.so" "libvulkan.so" "libpiex.so" )

    mkdir /system/lib/sphal-compat || true
    for lib in "${libs[@]}"
        do
           : 
           touch /system/lib/sphal-compat/$lib || true
           chmod 644 /system/lib/sphal-compat/$lib
           mount -o bind /system/lib/vndk-26/$lib /system/lib/sphal-compat/$lib || true
        done
    touch /system/lib/sphal-compat/libft2.so || true
    mount -o bind /system/lib/libft2.so /system/lib/sphal-compat/libft2.so || true
    chmod 755 /system/lib/sphal-compat
fi



mount -o remount,ro /system || true
mount -o remount,ro / || true

mkdir -p /mnt/phh/
mount -t tmpfs -o rw,nodev,relatime,mode=755,gid=0 none /mnt/phh || true
mkdir /mnt/phh/empty_dir
fixSPL

changeKeylayout

mount /system/phh/empty /vendor/bin/vendor.samsung.security.proca@1.0-service || true

if grep vendor.huawei.hardware.biometrics.fingerprint /vendor/manifest.xml; then
    mount -o bind system/phh/huawei/fingerprint.kl /vendor/usr/keylayout/fingerprint.kl
fi

if ! grep android.hardware.biometrics.fingerprint /vendor/manifest.xml && ! grep android.hardware.biometrics.fingerprint /vendor/etc/vintf/manifest.xml; then
    mount -o bind system/phh/empty /system/etc/permissions/android.hardware.fingerprint.xml
fi

if ! grep android.hardware.bluetooth /vendor/manifest.xml && ! grep android.hardware.bluetooth /vendor/etc/vintf/manifest.xml; then
    mount -o bind system/phh/empty /system/etc/permissions/android.hardware.bluetooth.xml
    mount -o bind system/phh/empty /system/etc/permissions/android.hardware.bluetooth_le.xml
fi

if getprop ro.hardware | grep -qF qcom && [ -f /sys/class/backlight/panel0-backlight/max_brightness ] &&
    grep -qvE '^255$' /sys/class/backlight/panel0-backlight/max_brightness; then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/backlight/panel0-backlight/max_brightness)"
fi

#Sony don't use Qualcomm HAL, so they don't have their mess
if getprop ro.vendor.build.fingerprint | grep -qE 'Sony/'; then
    setprop persist.sys.qcom-brightness -1
fi

if getprop ro.vendor.build.fingerprint | grep -qi oneplus/oneplus6/oneplus6; then
    resize2fs /dev/block/platform/soc/1d84000.ufshc/by-name/userdata
fi

if getprop ro.vendor.build.fingerprint | grep -q full_k50v1_64 || getprop ro.hardware | grep -q mt6580; then
    setprop persist.sys.overlay.nightmode false
fi

if getprop ro.wlan.mtk.wifi.5g | grep -q 1; then
    setprop persist.sys.overlay.wifi5g true
fi

if grep -qF 'mkdir /data/.fps 0770 system fingerp' vendor/etc/init/hw/init.mmi.rc; then
    mkdir -p /data/.fps
    chmod 0770 /data/.fps
    chown system:9015 /data/.fps

    chown system:9015 /sys/devices/soc/soc:fpc_fpc1020/irq
    chown system:9015 /sys/devices/soc/soc:fpc_fpc1020/irq_cnt
fi

if getprop ro.vendor.build.fingerprint | grep -q -i \
    -e xiaomi/clover -e xiaomi/wayne -e xiaomi/sakura \
    -e xiaomi/nitrogen -e xiaomi/whyred -e xiaomi/platina \
    -e xiaomi/ysl -e nubia/nx60 -e nubia/nx61 -e xiaomi/tulip -e xiaomi/lavender; then
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
fi

if getprop ro.vendor.product.device |grep -iq -e RMX1801 -e RMX1803 -e RMX1807;then	
    setprop persist.sys.qcom-brightness "$(cat /sys/class/leds/lcd-backlight/max_brightness)"
fi

if getprop ro.vendor.build.fingerprint | grep -iq \
    -e Xiaomi/beryllium/beryllium -e Xiaomi/sirius/sirius \
    -e Xiaomi/dipper/dipper -e Xiaomi/ursa/ursa -e Xiaomi/polaris/polaris \
    -e motorola/ali/ali -e iaomi/perseus/perseus -e iaomi/platina/platina \
    -e iaomi/equuleus/equuleus -e motorola/nora -e xiaomi/nitrogen \
    -e motorola/hannah -e motorola/james -e motorola/pettyl -e iaomi/cepheus \
    -e iaomi/grus -e xiaomi/cereus -e iaomi/raphael -e iaomi/davinci;then
    mount -o bind /mnt/phh/empty_dir /vendor/lib64/soundfx
    mount -o bind /mnt/phh/empty_dir /vendor/lib/soundfx
    setprop  ro.audio.ignore_effects true
fi

if [ "$(getprop ro.vendor.product.manufacturer)" = "motorola" ] || [ "$(getprop ro.product.vendor.manufacturer)" = "motorola" ]; then
    if getprop ro.vendor.product.device | grep -q -e nora -e ali -e hannah -e evert -e jeter -e deen -e james -e pettyl -e jater; then
        if [ "$vndk" -ge 28 ]; then
            f="/vendor/lib/libeffects.so"
            # shellcheck disable=SC2010
            ctxt="$(ls -lZ $f | grep -oE 'u:object_r:[^:]*:s0')"
            b="$(echo "$f" | tr / _)"

            cp -a $f "/mnt/phh/$b"
            sed -i \
                's/%zu errors during loading of configuration: %s/%zu errors during loading of configuration: ss/g' \
                "/mnt/phh/$b"
            chcon "$ctxt" "/mnt/phh/$b"
            mount -o bind "/mnt/phh/$b" $f
        else
            mount -o bind /mnt/phh/empty_dir /vendor/lib64/soundfx
            mount -o bind /mnt/phh/empty_dir /vendor/lib/soundfx
        fi
    fi
fi

if getprop ro.vendor.build.fingerprint | grep -q -i -e xiaomi/wayne -e xiaomi/jasmine; then
    setprop persist.imx376_sunny.low.lux 310
    setprop persist.imx376_sunny.light.lux 280
    setprop persist.imx376_ofilm.low.lux 310
    setprop persist.imx376_ofilm.light.lux 280
    echo "none" > /sys/class/leds/led:torch_2/trigger
fi

for f in /vendor/lib/mtk-ril.so /vendor/lib64/mtk-ril.so /vendor/lib/libmtk-ril.so /vendor/lib64/libmtk-ril.so; do
    [ ! -f $f ] && continue

    setprop persist.sys.phh.radio.force_cognitive true
    setprop persist.sys.radio.ussd.fix true

    if getprop persist.sys.mtk.disable.incoming.fix | grep -q 1; then break; fi

    # shellcheck disable=SC2010
    ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
    b="$(echo "$f" | tr / _)"

    cp -a "$f" "/mnt/phh/$b"
    sed -i \
        -e 's/AT+EAIC=2/AT+EAIC=3/g' \
        "/mnt/phh/$b"
    chcon "$ctxt" "/mnt/phh/$b"
    mount -o bind "/mnt/phh/$b" "$f"
done

mount -o bind /system/phh/empty /vendor/overlay/SysuiDarkTheme/SysuiDarkTheme.apk || true
mount -o bind /system/phh/empty /vendor/overlay/SysuiDarkTheme/SysuiDarkThemeOverlay.apk || true

if grep -qF 'PowerVR Rogue GE8100' /vendor/lib/egl/GLESv1_CM_mtk.so ||
    grep -qF 'PowerVR Rogue' /vendor/lib/egl/libGLESv1_CM_mtk.so ||
    ( (getprop ro.product.board; getprop ro.board.platform) | grep -qiE -e msm8917 -e msm8937 -e msm8940); then

    setprop debug.hwui.renderer opengl
fi

#If we have both Samsung and AOSP power hal, take Samsung's
if [ -f /vendor/bin/hw/vendor.samsung.hardware.miscpower@1.0-service ] && [ "$vndk" -lt 28 ]; then
    mount -o bind /system/phh/empty /vendor/bin/hw/android.hardware.power@1.0-service
fi

if [ "$vndk" = 27 ] || [ "$vndk" = 26 ]; then
    mount -o bind /system/phh/libnfc-nci-oreo.conf /system/etc/libnfc-nci.conf
fi

if busybox_phh unzip -p /vendor/app/ims/ims.apk classes.dex | grep -qF -e Landroid/telephony/ims/feature/MmTelFeature -e Landroid/telephony/ims/feature/MMTelFeature; then
    mount -o bind /system/phh/empty /vendor/app/ims/ims.apk
fi

if getprop ro.hardware | grep -qF samsungexynos -e mt6771; then
    setprop debug.sf.latch_unsignaled 1
fi

if getprop ro.product.model | grep -qF -e ANE; then
    setprop debug.sf.latch_unsignaled 1
fi

if getprop ro.vendor.build.fingerprint | grep -iq -E -e 'huawei|honor' || getprop persist.sys.overlay.huawei | grep -iq -E -e 'true'; then
    p=/product/etc/nfc/libnfc_nxp_*_*.conf
    mount -o bind "$p" /system/etc/libnfc-nxp.conf ||
        mount -o bind /product/etc/libnfc-nxp.conf /system/etc/libnfc-nxp.conf || true

    p=/product/etc/nfc/libnfc_brcm_*_*.conf
    mount -o bind "$p" /system/etc/libnfc-brcm.conf ||
        mount -o bind /product/etc/libnfc-nxp.conf /system/etc/libnfc-nxp.conf || true

    mount -o bind /system/phh/libnfc-nci-huawei.conf /system/etc/libnfc-nci.conf
fi

if getprop ro.vendor.build.fingerprint | grep -qE -e ".*(crown|star)[q2]*lte.*" -e ".*(SC-0[23]K|SCV3[89]).*" && [ "$vndk" -lt 28 ]; then
    for f in /vendor/lib/libfloatingfeature.so /vendor/lib64/libfloatingfeature.so; do
        [ ! -f "$f" ] && continue
        # shellcheck disable=SC2010
        ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
        b="$(echo "$f" | tr / _)"

        cp -a "$f" "/mnt/phh/$b"
        sed -i \
            -e 's;/system/etc/floating_feature.xml;/system/ph/sam-9810-flo_feat.xml;g' \
            "/mnt/phh/$b"
        chcon "$ctxt" "/mnt/phh/$b"
        mount -o bind "/mnt/phh/$b" "$f"

	setprop ro.audio.monitorRotation true
    done
fi

# This matches both Razer Phone 1 & 2
if getprop ro.vendor.build.fingerprint |grep -qE razer/cheryl;then
	setprop ro.audio.monitorRotation true
fi

if getprop ro.vendor.build.fingerprint | grep -qiE '^samsung'; then
    if getprop ro.hardware | grep -q qcom; then
        setprop persist.sys.overlay.devinputjack false
    fi

    if getprop ro.hardware | grep -q -e samsungexynos7870 -e qcom; then
        if [ "$vndk" -le 27 ]; then
            setprop persist.sys.phh.sdk_override /vendor/bin/hw/rild=27
        fi
    fi
fi

if getprop ro.vendor.build.fingerprint | grep -qE '^xiaomi/(daisy|wayne)/(daisy|wayne).*'; then
    # Fix camera on DND, ugly workaround but meh
    setprop audio.camerasound.force true
fi

mount -o bind /mnt/phh/empty_dir /vendor/etc/audio || true

for f in /vendor/lib{,64}/hw/com.qti.chi.override.so;do
    [ ! -f $f ] && continue
    # shellcheck disable=SC2010
    ctxt="$(ls -lZ "$f" | grep -oE 'u:object_r:[^:]*:s0')"
    b="$(echo "$f" | tr / _)"

    cp -a "$f" "/mnt/phh/$b"
    sed -i \
        -e 's/ro.product.manufacturer/sys.phh.xx.manufacturer/g' \
        "/mnt/phh/$b"
    chcon "$ctxt" "/mnt/phh/$b"
    mount -o bind "/mnt/phh/$b" "$f"

    setprop sys.phh.xx.manufacturer "$(getprop ro.product.vendor.manufacturer)"
done

if [ -n "$(getprop ro.boot.product.hardware.sku)" ] && [ -z "$(getprop ro.hw.oemName)" ];then
	setprop ro.hw.oemName "$(getprop ro.boot.product.hardware.sku)"
fi

if getprop ro.vendor.build.fingerprint | grep -qiE '^samsung/' && [ "$vndk" -ge 28 ];then
	setprop persist.sys.phh.samsung_fingerprint 0
	#obviously broken perms
	if [ "$(stat -c '%A' /sys/class/sec/tsp/ear_detect_enable)" == "-rw-rw-r--" ] &&
		[ "$(stat -c '%U' /sys/class/sec/tsp/ear_detect_enable)" == "root" ] &&
		[ "$(stat -c '%G' /sys/class/sec/tsp/ear_detect_enable)" == "root" ];then

		chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/ear_detect_enable
		chown system /sys/class/sec/tsp/ear_detect_enable

		chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/cmd{,_list,_result,_status}
		chown system /sys/class/sec/tsp/cmd{,_list,_result,_status}

		chown system /sys/class/power_supply/battery/wc_tx_en
		chcon u:object_r:sysfs_app_writable:s0 /sys/class/power_supply/battery/wc_tx_en

	fi

	if [ "$(stat -c '%U' /sys/class/sec/tsp/input/enabled)" == "root" ] &&
		[ "$(stat -c '%G' /sys/class/sec/tsp/input/enabled)" == "root" ];then
			chown system:system /sys/class/sec/tsp/input/enabled
			chcon u:object_r:sysfs_ss_writable:s0 /sys/class/sec/tsp/input/enabled
			setprop ctl.restart sec-miscpower-1-0
	fi
fi

if [ -f /system/phh/secure ];then
    copyprop() {
        p="$(getprop "$2")"
        if [ "$p" ]; then
            resetprop "$1" "$(getprop "$2")"
        fi
    }

    copyprop ro.build.device ro.vendor.build.device
    copyprop ro.bootimage.build.fingerprint ro.vendor.build.fingerprint
    copyprop ro.build.fingerprint ro.vendor.build.fingerprint
    copyprop ro.build.device ro.vendor.product.device
    copyprop ro.product.device ro.vendor.product.device
    copyprop ro.product.device ro.product.vendor.device
    copyprop ro.product.name ro.vendor.product.name
    copyprop ro.product.name ro.product.vendor.device
    copyprop ro.product.brand ro.vendor.product.brand
    copyprop ro.product.model ro.vendor.product.model
    copyprop ro.product.model ro.product.vendor.model
    copyprop ro.build.product ro.vendor.product.model
    copyprop ro.build.product ro.product.vendor.model
    copyprop ro.product.manufacturer ro.vendor.product.manufacturer
    copyprop ro.product.manufacturer ro.product.vendor.manufacturer
    copyprop ro.build.version.security_patch ro.keymaster.xxx.security_patch
    copyprop ro.build.version.security_patch ro.vendor.build.security_patch
    resetprop ro.build.tags release-keys
    resetprop ro.boot.vbmeta.device_state locked
    resetprop ro.boot.verifiedbootstate green
    resetprop ro.boot.flash.locked 1
    resetprop ro.boot.veritymode enforcing
    resetprop ro.boot.warranty_bit 0
    resetprop ro.warranty_bit 0
    resetprop ro.debuggable 0
    resetprop ro.secure 1
    resetprop ro.build.type user
    resetprop ro.build.selinux 0

    resetprop ro.adb.secure 1
    setprop ctl.restart adbd
fi
