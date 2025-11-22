TARGET := iphone:clang:latest
INSTALL_TARGET_PROCESSES = TikTok Aweme
THEOS_DEVICE_IP = 192.168.100.246
THEOS_DEVICE_USER = root
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BHTikTok

BHTikTok_FILES = \
  Tweak.x \
  BHDownload.m \
  BHMultipleDownload.m \
  BHIManager.m \
  SecurityViewController.m \
  $(wildcard JGProgressHUD/*.m) \
  Settings/CountryTable.m \
  Settings/LiveActions.m \
  Settings/PlaybackSpeed.m \
  Settings/ViewController.m
BHTikTok_FRAMEWORKS = UIKit Foundation CoreGraphics Photos CoreServices SystemConfiguration SafariServices Security QuartzCore
BHTikTok_IPHONEOS_DEPLOYMENT_TARGET = 12.0
ARCHS = arm64
BHTikTok_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-value -Wno-deprecated-declarations -Wno-nullability-completeness -Wno-unused-function -Wno-incompatible-pointer-types -I$(CURDIR)/Settings
BHTikTok_RESOURCE_DIRS = Resources
BHTikTok_INSTALL_PATH = /Library/Application Support/BHTikTok

include $(THEOS_MAKE_PATH)/tweak.mk
