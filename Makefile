TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Spotify

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SposifyFix

$(TWEAK_NAME)_FILES = Tweak.xm UIImage+Icon.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
