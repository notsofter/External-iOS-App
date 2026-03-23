ARCHS := arm64
DEBUG = 0
FINALPACKAGE = 1
TARGET = iphone:clang:14.5
USE_MODULAR_HEADERS = 0
export TARGET_CC = /Users/gordeygordeev/Hikari_LLVM19.1.7.xctoolchain/usr/bin/clang
export TARGET_CXX = /Users/gordeygordeev/Hikari_LLVM19.1.7.xctoolchain/usr/bin/clang++

SOURCE_ROOT_ORIGINAL ?= src
SOURCE_ROOT := $(SOURCE_ROOT_ORIGINAL)
SOURCE_ROOT_ORIGINAL_ABS := $(CURDIR)/$(SOURCE_ROOT_ORIGINAL)

ENABLE_OBJC_OBFUSCATION ?= 1
OBJC_OBFUSCATION_FORCE ?= 0
OBJC_OBFUSCATED_ROOT ?= build/objc_obfuscated_src
OBJC_OBFUSCATED_ROOT_ABS := $(CURDIR)/$(OBJC_OBFUSCATED_ROOT)
OBJC_OBFUSCATOR_SCRIPT := $(CURDIR)/tools/ObjcClassNameObfuscator/obfuscate.py
OBJC_OBFUSCATOR_PYTHON ?= python3
OBJC_OBFUSCATOR_EXTRA_ARGS ?=

ifneq ($(filter 1,$(OBJC_OBFUSCATION_FORCE)),)
OBJC_OBFUSCATION_SHOULD_RUN := 1
else
OBJC_OBFUSCATION_SHOULD_RUN := $(and $(filter 1,$(ENABLE_OBJC_OBFUSCATION)),$(filter 1,$(FINALPACKAGE)))
endif

ifeq ($(OBJC_OBFUSCATION_SHOULD_RUN),1)
SOURCE_ROOT := $(OBJC_OBFUSCATED_ROOT)
endif


include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = nsftr

# Declaration of file names 'src'
ORIGINAL_SRC_FILES := $(shell find $(SOURCE_ROOT_ORIGINAL) -type f \( -name '*.m' -o -name '*.mm' -o -name '*.c' -o -name '*.cpp'  -o -name '*.swift' \))
ifeq ($(SOURCE_ROOT),$(SOURCE_ROOT_ORIGINAL))
SRC_FILES := $(ORIGINAL_SRC_FILES)
else
SRC_FILES := $(patsubst $(SOURCE_ROOT_ORIGINAL)/%,$(SOURCE_ROOT)/%,$(ORIGINAL_SRC_FILES))
endif
$(APPLICATION_NAME)_FILES += $(SRC_FILES)

# Declaration of file names 'dependencies'
DPD_FILES := $(shell find dependencies/lib -type f \( -name '*.m' -o -name '*.mm' -o -name '*.c' -o -name '*.cpp' \))
$(APPLICATION_NAME)_FILES += $(DPD_FILES) 

# Setting FLAGS 
$(APPLICATION_NAME)_CFLAGS += -include hud-prefix.pch -Wno-deprecated-declarations -mllvm -hikari
$(APPLICATION_NAME)_CFLAGS += -fno-modules
$(APPLICATION_NAME)_CFLAGS += -Idependencies/include/libjailbreak
$(APPLICATION_NAME)_CFLAGS += $(shell find dependencies/include -type d -exec echo -I{} \;)
$(APPLICATION_NAME)_CFLAGS += -DCONFIG_HEADER_RELATIVE_PATH=\"$(SOURCE_ROOT)/Config.h\"
$(APPLICATION_NAME)_LDFLAGS += -L./dependencies/lib
$(APPLICATION_NAME)_LDFLAGS += -lchoma -lxpf
$(foreach file,$(DPD_FILES),$(eval $(file)_CFLAGS = -fobjc-arc -fvisibility=hidden -w))
$(foreach file,$(SRC_FILES),$(eval $(file)_CFLAGS = -fobjc-arc -fvisibility=hidden -w -mllvm -enable-strcry -mllvm -enable-bcfobf -mllvm -enable-cffobf -mllvm -enable-splitobf -mllvm -enable-indibran))

# Setting specific flags 
$(SOURCE_ROOT)/Menu/MenuView.mm_CFLAGS += -mllvm -strcry_prob=0

# Setting frameworks
$(APPLICATION_NAME)_FRAMEWORKS += UIKit Foundation MetalKit CoreGraphics CoreServices Metal QuartzCore
$(APPLICATION_NAME)_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit IOSurface SpringBoardServices

# Setting entitlements
$(APPLICATION_NAME)_CODESIGN_FLAGS += -Sent.xml

all:: objc-obfuscate-symbols

.PHONY: objc-obfuscate-symbols
objc-obfuscate-symbols:
	@if [ "$(OBJC_OBFUSCATION_SHOULD_RUN)" = "1" ]; then \
		mkdir -p "$(OBJC_OBFUSCATED_ROOT_ABS)" && \
		rsync -a --delete "$(SOURCE_ROOT_ORIGINAL_ABS)/" "$(OBJC_OBFUSCATED_ROOT_ABS)/" && \
		$(OBJC_OBFUSCATOR_PYTHON) "$(OBJC_OBFUSCATOR_SCRIPT)" --source-root "$(OBJC_OBFUSCATED_ROOT_ABS)"; \
	else \
		true; \
	fi

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)/Applications/nsftr.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr nsftr.tipa Payload; cd -;$(ECHO_END)

clean::
	@rm -rf "$(OBJC_OBFUSCATED_ROOT_ABS)"
