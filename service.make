#
#   service.make
#
#   Makefile rules to build GNUstep-based services.
#
#   Copyright (C) 1998 Free Software Foundation, Inc.
#
#   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
#   Based on the makefiles by Scott Christley.
#
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# prevent multiple inclusions
ifeq ($(SERVICE_MAKE_LOADED),)
SERVICE_MAKE_LOADED=yes

#
# Include in the common makefile rules
#
include $(GNUSTEP_MAKEFILES)/rules.make

#
# The name of the service is in the SERVICE_NAME variable.
# The NSServices info should be in $(SERVICE_NAME)Info.plist
# The list of service resource file are in xxx_RESOURCE_FILES
# The list of service resource directories are in xxx_RESOURCE_DIRS
# where xxx is the service name
#

ifeq ($(INTERNAL_svc_NAME),)
# This part gets included by the first invoked make process.
internal-all:: $(SERVICE_NAME:=.all.svc.variables)

internal-install:: $(SERVICE_NAME:=.install.svc.variables)

internal-uninstall:: $(SERVICE_NAME:=.uninstall.svc.variables)

internal-clean:: $(SERVICE_NAME:=.clean.svc.variables)

internal-distclean:: $(SERVICE_NAME:=.distclean.svc.variables)

$(SERVICE_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory $@.all.svc.variables

else

# Libraries that go before the GUI libraries
ALL_GUI_LIBS = $(ADDITIONAL_GUI_LIBS) $(AUXILIARY_GUI_LIBS) $(BACKEND_LIBS) \
   $(GUI_LIBS) $(ADDITIONAL_TOOL_LIBS) $(AUXILIARY_TOOL_LIBS) \
   $(FND_LIBS) $(ADDITIONAL_OBJC_LIBS) $(AUXILIARY_OBJC_LIBS) $(OBJC_LIBS) \
   $(SYSTEM_LIBS) $(TARGET_SYSTEM_LIBS)

ALL_GUI_LIBS := \
    $(shell $(WHICH_LIB_SCRIPT) $(LIB_DIRS_NO_SYSTEM) $(ALL_GUI_LIBS) \
	debug=$(debug) profile=$(profile) shared=$(shared) libext=$(LIBEXT) \
	shared_libext=$(SHARED_LIBEXT))


# Don't include these definitions the first time make is invoked. This part is
# included when make is invoked the second time from the %.build rule (see
# rules.make).
SERVICE_DIR_NAME = $(INTERNAL_svc_NAME:=.service)
SERVICE_RESOURCE_DIRS =  $(foreach d, $(RESOURCE_DIRS), $(SERVICE_DIR_NAME)/Resources/$(d))
ifeq ($(strip $(RESOURCE_FILES)),)
  override RESOURCE_FILES=""
endif

#
# Internal targets
#

$(SERVICE_FILE): $(C_OBJ_FILES) $(OBJC_OBJ_FILES)
	$(LD) $(ALL_LDFLAGS) $(LDOUT)$@ $(C_OBJ_FILES) $(OBJC_OBJ_FILES) \
		$(ALL_LIB_DIRS) $(ALL_GUI_LIBS)
	@$(TRANSFORM_PATHS_SCRIPT) `echo $(ALL_LIB_DIRS) | sed 's/-L//g'` \
	>$(SERVICE_DIR_NAME)/$(GNUSTEP_TARGET_CPU)/$(GNUSTEP_TARGET_OS)/$(LIBRARY_COMBO)/library_paths.openapp

#
# Compilation targets
#
internal-svc-all:: before-$(TARGET)-all $(GNUSTEP_OBJ_DIR) \
   $(SERVICE_DIR_NAME)/$(GNUSTEP_TARGET_DIR)/$(LIBRARY_COMBO) $(SERVICE_FILE) \
   svc-resource-files after-$(TARGET)-all

before-$(TARGET)-all::

after-$(TARGET)-all::

$(SERVICE_DIR_NAME)/$(GNUSTEP_TARGET_DIR)/$(LIBRARY_COMBO):
	@$(GNUSTEP_MAKEFILES)/mkinstalldirs \
		$(SERVICE_DIR_NAME)/$(GNUSTEP_TARGET_DIR)/$(LIBRARY_COMBO)

svc-resource-dir::
	@$(GNUSTEP_MAKEFILES)/mkinstalldirs \
		$(SERVICE_RESOURCE_DIRS)

svc-resource-files:: $(SERVICE_DIR_NAME)/Resources/Info-gnustep.plist svc-resource-dir
	@(if [ "$(RESOURCE_FILES)" != "" ]; then \
	  echo "Copying resources into the service wrapper..."; \
	  cp -r $(RESOURCE_FILES) $(SERVICE_DIR_NAME)/Resources; \
	fi)

$(SERVICE_DIR_NAME)/Resources/Info-gnustep.plist: $(SERVICE_DIR_NAME)/Resources
	@(echo "{"; echo '  NOTE = "Automatically generated, do not edit!";'; \
	  echo "  NSExecutable = $(INTERNAL_svc_NAME);"; \
	  cat $(INTERNAL_svc_NAMESERVICE_NAME)Info.plist; \
	  echo "}") >$@
	make_services --test $@

$(SERVICE_DIR_NAME)/Resources:
	@$(GNUSTEP_MAKEFILES)/mkinstalldirs $@

internal-svc-install::
	rm -rf $(GNUSTEP_APPS)/$(SERVICE_DIR_NAME)
	$(TAR) cf - $(SERVICE_DIR_NAME) | (cd $(GNUSTEP_APPS); $(TAR) xf -)

internal-svc-uninstall::
	(cd $(GNUSTEP_APPS); rm -rf $(SERVICE_DIR_NAME))

#
# Cleaning targets
#
internal-svc-clean::
	rm -rf $(GNUSTEP_OBJ_PREFIX)/$(GNUSTEP_TARGET_CPU)/$(GNUSTEP_TARGET_OS)/$(LIBRARY_COMBO)
ifeq ($(OBJC_COMPILER), NeXT)
	rm -f *.iconheader
	for f in *.service; do \
	  rm -f $$f/`basename $$f .service`; \
	done
else
	rm -rf *.service/$(GNUSTEP_TARGET_CPU)/$(GNUSTEP_TARGET_OS)/$(LIBRARY_COMBO)
endif


internal-svc-distclean::
	rm -rf shared_obj static_obj shared_debug_obj shared_profile_obj \
	  static_debug_obj static_profile_obj shared_profile_debug_obj \
	  static_profile_debug_obj *.app *.debug *.profile *.iconheader

endif

endif
# service.make loaded

## Local variables:
## mode: makefile
## End:
