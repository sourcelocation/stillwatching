
export SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk

THEOS_DEVICE_IP = 192.168.1.110
THEOS_DEVICE_PORT = 22

TARGET := iphone:clang:latest:7.0
# INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = stillwatching

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_EXTRA_FRAMEWORKS += Cephei
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MediaRemote Celestial

after-install::
	install.exec "killall -9 SpringBoard"
include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += stillwatchingprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
