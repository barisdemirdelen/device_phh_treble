#Huawei devices don't declare fingerprint and telephony hardware feature
#TODO: Proper detection
PRODUCT_COPY_FILES := \
	frameworks/native/data/etc/android.hardware.fingerprint.xml:system/etc/permissions/android.hardware.fingerprint.xml \
	frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
	frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
	frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \

#Use a more decent APN config
PRODUCT_COPY_FILES += \
	device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

BOARD_PLAT_PRIVATE_SEPOLICY_DIR += device/phh/treble/sepolicy
DEVICE_PACKAGE_OVERLAYS += \
	device/phh/treble/overlay \
	device/phh/treble/overlay-lineage

$(call inherit-product, vendor/hardware_overlay/overlay.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

#Those overrides are here because Huawei's init read properties
#from /system/etc/prop.default, then /vendor/build.prop, then /system/build.prop
#So we need to set our props in prop.default
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
	ro.build.version.sdk=$(PLATFORM_SDK_VERSION) \
	ro.build.version.codename=$(PLATFORM_VERSION_CODENAME) \
	ro.build.version.all_codenames=$(PLATFORM_VERSION_ALL_CODENAMES) \
	ro.build.version.release=$(PLATFORM_VERSION) \
	ro.build.version.security_patch=$(PLATFORM_SECURITY_PATCH) \
	ro.adb.secure=0 \
	ro.logd.auditd=true
	
#Huawei HiSuite (also other OEM custom programs I guess) it's of no use in AOSP builds
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
	persist.sys.usb.config=adb \
	ro.cust.cdrom=/dev/null	

#VNDK config files
PRODUCT_COPY_FILES += \
	device/phh/treble/vndk-detect:system/bin/vndk-detect \
	device/phh/treble/vndk.rc:system/etc/init/vndk.rc \
	device/phh/treble/ld.config.26.txt:system/etc/ld.config.26.txt \
	device/phh/treble/ld.config.hi3650.txt:system/etc/ld.config.hi3650.txt \

#USB Audio
PRODUCT_COPY_FILES += \
	frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml

# NFC:
#   Provide default libnfc-nci.conf file for devices that does not have one in
#   vendor/etc
PRODUCT_COPY_FILES += \
	device/phh/treble/nfc/libnfc-nci.conf:system/phh/libnfc-nci-oreo.conf \
	device/phh/treble/nfc/libnfc-nci-huawei.conf:system/phh/libnfc-nci-huawei.conf

# LineageOS build may need this to make NFC work
PRODUCT_PACKAGES += \
        NfcNci  

PRODUCT_COPY_FILES += \
	device/phh/treble/rw-system.sh:system/bin/rw-system.sh \
	device/phh/treble/fixSPL/getSPL.arm:system/bin/getSPL

PRODUCT_COPY_FILES += \
	device/phh/treble/empty:system/phh/empty \
	device/phh/treble/phh-on-boot.sh:system/bin/phh-on-boot.sh

PRODUCT_PACKAGES += \
	treble-environ-rc

PRODUCT_PACKAGES += \
	bootctl \
	vintf

# Fix Offline Charging on Huawmeme
PRODUCT_PACKAGES += \
	huawei-charger
PRODUCT_COPY_FILES += \
	$(call find-copy-subdir-files,*,device/phh/treble/huawei_charger/files,system/etc/charger)

PRODUCT_COPY_FILES += \
	device/phh/treble/twrp/twrp.rc:system/etc/init/twrp.rc \
	device/phh/treble/twrp/twrp.sh:system/bin/twrp.sh \
	device/phh/treble/twrp/busybox-armv7l:system/bin/busybox_phh

PRODUCT_PACKAGES += \
    simg2img_simple

ifneq (,$(wildcard external/exfat))
PRODUCT_PACKAGES += \
	mkfs.exfat \
	fsck.exfat
endif

PRODUCT_PACKAGES += \
	android.hardware.wifi.hostapd-V1.0-java \
	vendor.huawei.hardware.biometrics.fingerprint-V2.1-java \
	vendor.huawei.hardware.tp-V1.0-java \
	vendor.qti.hardware.radio.am-V1.0-java \
	vendor.qti.qcril.am-V1.0-java \

PRODUCT_COPY_FILES += \
	device/phh/treble/interfaces.xml:system/etc/permissions/interfaces.xml

PRODUCT_COPY_FILES += \
	device/phh/treble/files/samsung-gpio_keys.kl:system/phh/samsung-gpio_keys.kl \
	device/phh/treble/files/samsung-sec_touchscreen.kl:system/phh/samsung-sec_touchscreen.kl \
	device/phh/treble/files/oneplus6-synaptics_s3320.kl:system/phh/oneplus6-synaptics_s3320.kl \
	device/phh/treble/files/huawei-fingerprint.kl:system/phh/huawei/fingerprint.kl \
	device/phh/treble/files/samsung-sec_e-pen.idc:system/usr/idc/sec_e-pen.idc \
	device/phh/treble/files/samsung-9810-floating_feature.xml:system/ph/sam-9810-flo_feat.xml \
	device/phh/treble/files/cam.hi3650.sh:system/bin/cam.hi3650.sh \
	device/phh/treble/files/cameraserver-hi3650.sh:system/bin/cameraserver-hi3650.sh \
	device/phh/treble/files/camerainit-hi3650.sh:system/bin/camerainit-hi3650.sh \
	device/phh/treble/files/cameradaemon-hi3650.sh:system/bin/cameradaemon-hi3650.sh \
	device/phh/treble/files/mimix3-gpio-keys.kl:system/phh/mimix3-gpio-keys.kl

SELINUX_IGNORE_NEVERALLOWS := true

# Universal NoCutoutOverlay
PRODUCT_PACKAGES += \
    NoCutoutOverlay

PRODUCT_PACKAGES += \
    lightsctl \
    uevent

PRODUCT_COPY_FILES += \
	device/phh/treble/files/adbd.rc:system/etc/init/adbd.rc

#MTK incoming SMS fix
PRODUCT_PACKAGES += \
	mtk-sms-fwk-ready

# Helper to debug Xiaomi motorized camera
PRODUCT_PACKAGES += \
	xiaomi-motor

PRODUCT_PACKAGES += \
	Stk

PRODUCT_PACKAGES += \
	resetprop

PRODUCT_PACKAGES += \
	 HwCamera2 \
   HuaweiParts

PRODUCT_COPY_FILES += \
	openkirinaddons/bin/cameradaemon-hi3650.sh:system/bin/cameradaemon-hi3650.sh \
	openkirinaddons/bin/camerainit-hi3650.sh:system/bin/camerainit-hi3650.sh \
	openkirinaddons/bin/cameraserver-hi3650.sh:system/bin/cameraserver-hi3650.sh \
	openkirinaddons/bin/cam.hi3650.sh:system/bin/cam.hi3650.sh \
	openkirinaddons/emui/base/global/ons.bin:system/emui/base/global/ons.bin \
	openkirinaddons/etc/permissions/com.huawei.hwpostcamera.xml:system/etc/permissions/com.huawei.hwpostcamera.xml \
	openkirinaddons/etc/permissions/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
	openkirinaddons/etc/permissions/privapp-permissions-hwcamera.xml:system/etc/permissions/privapp-permissions-hwcamera.xml \
	openkirinaddons/framework/hwpostcamera.jar:system/framework/hwpostcamera.jar \
	openkirinaddons/lib/libdisplayenginesvc_1_0.so:system/lib/libdisplayenginesvc_1_0.so \
	openkirinaddons/lib/libHwPostCamera_jni.so:system/lib/libHwPostCamera_jni.so \
	openkirinaddons/lib/libhwpwmanager_jni.so:system/lib/libhwpwmanager_jni.so \
	openkirinaddons/lib/libmrc_cg_beauty.so:system/lib/libmrc_cg_beauty.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.camResource@1.0.so:system/lib/vendor.huawei.hardware.camera.camResource@1.0.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.camResource@1.1.so:system/lib/vendor.huawei.hardware.camera.camResource@1.1.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.camResource@1.2.so:system/lib/vendor.huawei.hardware.camera.camResource@1.2.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.camResource@1.3.so:system/lib/vendor.huawei.hardware.camera.camResource@1.3.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.camResource.orbService@1.0.so:system/lib/vendor.huawei.hardware.camera.camResource.orbService@1.0.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.cfgsvr@1.0.so:system/lib/vendor.huawei.hardware.camera.cfgsvr@1.0.so\
	openkirinaddons/lib/vendor.huawei.hardware.camera.cfgsvr@1.1.so:system/lib/vendor.huawei.hardware.camera.cfgsvr@1.1.so \
	openkirinaddons/lib/vendor.huawei.hardware.camera.factory@1.0.so:system/lib/vendor.huawei.hardware.camera.factory@1.0.so \
	openkirinaddons/lib64/libdisplayenginesvc_1_0.so:system/lib64/libdisplayenginesvc_1_0.so \
	openkirinaddons/lib64/libHwPostCamera_jni.so:system/lib64/libHwPostCamera_jni.so \
	openkirinaddons/lib64/libhwpwmanager_jni.so:system/lib64/libhwpwmanager_jni.so \
	openkirinaddons/lib64/libmrc_cg_beauty.so:system/lib64/libmrc_cg_beauty.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.camResource@1.0.so:system/lib64/vendor.huawei.hardware.camera.camResource@1.0.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.camResource@1.1.so:system/lib64/vendor.huawei.hardware.camera.camResource@1.1.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.camResource@1.2.so:system/lib64/vendor.huawei.hardware.camera.camResource@1.2.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.camResource@1.3.so:system/lib64/vendor.huawei.hardware.camera.camResource@1.3.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.camResource.orbService@1.0.so:system/lib64/vendor.huawei.hardware.camera.camResource.orbService@1.0.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.cfgsvr@1.0.so:system/lib64/vendor.huawei.hardware.camera.cfgsvr@1.0.so\
	openkirinaddons/lib64/vendor.huawei.hardware.camera.cfgsvr@1.1.so:system/lib64/vendor.huawei.hardware.camera.cfgsvr@1.1.so \
	openkirinaddons/lib64/vendor.huawei.hardware.camera.factory@1.0.so:system/lib64/vendor.huawei.hardware.camera.factory@1.0.so \
	openkirinaddons/priv-app/HwCamera2/oat/arm/HwCamera2.odex:system/priv-app/HwCamera2/oat/arm/HwCamera2.odex \
	openkirinaddons/priv-app/HwCamera2/oat/arm/HwCamera2.vdex:system/priv-app/HwCamera2/oat/arm/HwCamera2.vdex \
	openkirinaddons/lib/sphal-compat/android.hardware.camera.common@1.0.so:system/lib/sphal-compat/android.hardware.camera.common@1.0.so \
	openkirinaddons/lib/sphal-compat/android.hardware.camera.device@1.0.so:system/lib/sphal-compat/android.hardware.camera.device@1.0.so \
	openkirinaddons/lib/sphal-compat/android.hardware.camera.device@3.2.so:system/lib/sphal-compat/android.hardware.camera.device@3.2.so \
	openkirinaddons/lib/sphal-compat/android.hardware.camera.provider@2.4.so:system/lib/sphal-compat/android.hardware.camera.provider@2.4.so \
	openkirinaddons/lib/sphal-compat/android.hardware.configstore@1.0.so:system/lib/sphal-compat/android.hardware.configstore@1.0.so \
	openkirinaddons/lib/sphal-compat/android.hardware.configstore-utils.so:system/lib/sphal-compat/android.hardware.configstore-utils.so \
	openkirinaddons/lib/sphal-compat/android.hidl.allocator@1.0.so:system/lib/sphal-compat/android.hidl.allocator@1.0.so \
	openkirinaddons/lib/sphal-compat/libbinder.so:system/lib/sphal-compat/libbinder.so \
	openkirinaddons/lib/sphal-compat/libcamera_metadata.so:system/lib/sphal-compat/libcamera_metadata.so \
	openkirinaddons/lib/sphal-compat/libdng_sdk.so:system/lib/sphal-compat/libdng_sdk.so \
	openkirinaddons/lib/sphal-compat/libexpat.so:system/lib/sphal-compat/libexpat.so \
	openkirinaddons/lib/sphal-compat/libfmq.so:system/lib/sphal-compat/libfmq.so \
	openkirinaddons/lib/sphal-compat/libft2.so:system/lib/sphal-compat/libft2.so \
	openkirinaddons/lib/sphal-compat/libicui18n.so:system/lib/sphal-compat/libicui18n.so \
	openkirinaddons/lib/sphal-compat/libicuuc.so:system/lib/sphal-compat/libicuuc.so \
	openkirinaddons/lib/sphal-compat/libjpeg.so:system/lib/sphal-compat/libjpeg.so \
	openkirinaddons/lib/sphal-compat/libnativebridge.so:system/lib/sphal-compat/libnativebridge.so \
	openkirinaddons/lib/sphal-compat/libnativehelper.so:system/lib/sphal-compat/libnativehelper.so \
	openkirinaddons/lib/sphal-compat/libnativeloader.so:system/lib/sphal-compat/libnativeloader.so \
	openkirinaddons/lib/sphal-compat/libpiex.so:system/lib/sphal-compat/libpiex.so \
	openkirinaddons/lib/sphal-compat/libpng.so:system/lib/sphal-compat/libpng.so \
	openkirinaddons/lib/sphal-compat/libskia.so:system/lib/sphal-compat/libskia.so \
	openkirinaddons/lib/sphal-compat/libui.so:system/lib/sphal-compat/libui.so \
	openkirinaddons/lib/sphal-compat/libvulkan.so:system/lib/sphal-compat/libvulkan.so \
	openkirinaddons/lib/sphal-compat/libziparchive.so:system/lib/sphal-compat/libziparchive.so \
	openkirinaddons/lib/libui.so:system/lib/libui.so

PRODUCT_COPY_FILES += \
	device/phh/treble/phh-securize.sh:system/bin/phh-securize.sh \

