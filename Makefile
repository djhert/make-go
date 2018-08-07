# Makefile for a Golang project
## Common settings for the project are changed here
### All settings are exported

### How Verbose should this be?
#### 0 = quiet
#### 1 = verbose = ECHO, EECHO, EEECHO
#### 2 = Show all file operations = EECHO, EEECHO
#### 3 = Show debug file operations only = EEECHO
VERBOSITY = 3

## Get OS
ifeq ($(OS),Windows_NT)
_OS := Windows
else
_OS := $(shell uname -s)
endif

### Go Compiler
GOCC       = go build
DEFGOFLAGS = -ldflags '-s -w'

### Common Commands
SHELL      = /bin/bash
PRINT      = printf

### Settings for Verbosity levels
ifeq ($(VERBOSITY), 1)
RM         = rm -rvf
ECHO       = printf
EECHO      = printf
EEECHO     = printf
MKDIR      = mkdir -pv
LN         = ln -svf
CP         = cp -avf
MV         = mv -vf
else ### 0 and everything else
RM         = rm -rf
ECHO       = printf $@ > /dev/null 2> /dev/null
EECHO      = printf $@ > /dev/null 2> /dev/null
EEECHO     = printf $@ > /dev/null 2> /dev/null
MKDIR      = mkdir -p
LN         = ln -sf
CP         = cp -af
MV         = mv -f
endif

ifeq ($(VERBOSITY), 2)
RM         = rm -rvf
EECHO      = printf
EEECHO     = printf
MKDIR      = mkdir -pv
LN         = ln -svf
CP         = cp -avf
MV         = mv -vf
endif

ifeq ($(VERBOSITY), 3)
EEECHO     = printf
endif

### Export Settings
export GOCC DEFGOFLAGS SHELL PRINT _OS RM ECHO EECHO EEECHO MKDIR LN CP MV

### Current Project (get from dirname, ensure all lowercase)
Name = $(shell basename $(CURDIR)| tr '[:upper:]' '[:lower:]')

### Set executable name
ifeq ($(_OS),Windows)
G_Name   = $(Name).exe
else
G_Name   = $(Name)
endif

### Vendor Location
Lib       = $(CURDIR)/lib

### Build folders
Build     = $(CURDIR)/build
Bin       = $(Build)/bin
Src       = $(Build)/src

### Go Flags
GoFlags  = $(DEFGOFLAGS)

### Export Current Project
export Name G_Name Build Bin Src Lib GoFlags

### Finally, set the GOPATH
export GOPATH = $(Lib):$(shell printenv GOPATH)
export GOBIN  = $(Lib)/bin:$(shell printenv GOBIN)

## Include optional Makefiles if they exist
-include Makefile.install
-include Makefile.$(Name)

### Make
## Force Default
.DEFAULT_GOAL := default
## Define specifc targets
.PHONY: default help help-data help-install help-custom index build build-debug exec clean

## Default to show help
default: help

## Help function, default
#### Shows help-data, help-install, help-custom in that order
### help-data is the local help function
### help-install is reserved for the Makefile.install
### help-custom is reserved for the Makefile.$(Name)
#### if reserved help functions do not exist, nothing happens
help: help-data help-install help-custom
	@$(PRINT) "\n" ## Gives it a nice trailing newline

## Local help
help-data:
	@$(PRINT) "\n## $(Name) make\n"
	@$(EEECHO) "\n# OS: $(_OS)\n# GOPATH: $(GOPATH)\n\n"
	@$(PRINT) "### Options:\n"
	@$(PRINT) "   run\t\t\tBuild $(Name) and execute, clean once done\n"
	@$(PRINT) "   test\t\t\tBuild debug $(Name) and execute, clean once done\n"
	@$(PRINT) "   help (default)\tDisplay this help\n"
	@$(PRINT) "   build\t\tBuild $(Name) with:\n\t\t\t  $(GOCC) $(GoFlags) -tags release $(GOTAGS)\n"
	@$(PRINT) "   build-debug\t\tBuild debug $(Name) with\n\t\t\t  $(GOCC) $(GoFlags) -tags debug $(GOTAGS)\n"
	@$(PRINT) "   clean\t\tDelete files made for build\n"
	@$(PRINT) "   vendor\t\tGo get files for vendoring in project\n"
	@$(PRINT) "   set-verbosity\tSet the verbosity of the build process\n"

## Setup the build directory for the Go project
### Called By:  build, run
index:
	@$(ECHO) "\n## $(Name) Index\n#####\n"
	@$(EEECHO) "## Linking $(Name) source\n"
	@$(MKDIR) $(Src)
	@$(eval GoSource := $(shell find 'source' -type f -name '*.go' -printf '$(CURDIR)/source/%P\n'))
	@$(foreach o, $(GoSource), $(LN) $(o) $(Src);)
	@$(ECHO) "## Done\n#####\n"

## Build the release project
### Called By:  run
build: index
	@$(ECHO) "\n## $(Name) Build\n#####\n"
	@$(EEECHO) "## Changing Directory: $(Src)\n### Running: $(GOCC) $(GoFlags) -tags release $(GOTAG) -o $(Bin)/$(G_Name)\n"
	@cd $(Src) && $(GOCC) $(GoFlags) -tags release -o $(Bin)/$(G_Name)
	@$(ECHO) "## Done\n#####\n"

## Build the debug project
### Called By:  test
build-debug: index
	@$(ECHO) "\n## $(Name) Debug\n#####\n"
	@$(EEECHO) "## Changing Directory: $(Src)\n### Running: $(GOCC) $(GoFlags) -tags debug $(GOTAG) -o $(Bin)/$(G_Name)\n"
	@cd $(Src) && $(GOCC) $(GoFlags) -tags debug -o $(Bin)/$(G_Name)
	@$(ECHO) "## Done\n#####\n"

## Shortcut to run the debug build
test: build-debug exec clean

## Shortcut to run the release build
run: build exec clean

## Execure the project if exists
### Called By:  run, test
exec:
	@if [ ! -f $(Bin)/$(G_Name) ]; then \
		$(PRINT) "Error:  $(Name) is not built\n"; \
		$(PRINT) "   Try: make build\n"; \
		exit 1; \
	fi
	@$(ECHO) "\n## $(Name) Run\n#####\n"
	@$(EEECHO) "## Executing $(Bin)/$(G_Name)...\n"
	@exec $(Bin)/$(G_Name)
	@$(ECHO) "## Done\n#####\n"

## Clean the project if built
### Called By:  run, test
clean::
	@$(ECHO) "\n## $(Name) Clean\n#####\n"
	@if [ ! -d $(Build) ]; then \
		$(PRINT) "Error:  $(Name) is not built\n"; \
		$(PRINT) "   Nothing to clean\n"; \
	else \
		$(EEECHO) "## Removing build folder at: $(Build)\n"; \
		$(RM) $(Build); \
	fi
	@$(ECHO) "## Done\n#####\n"

## Set the verbosity level
### Uses sed to replace first instance of "Verbosity" in this file with new value
#### Does no validation. If Verbosity is set outside of 0-3 then 0 is used by default
set-verbosity:
	@$(PRINT) "\n## $(Name) Verbosity\n\n"
	@$(PRINT) "   0 - Quiet, no output (used if VERBOSITY is invalid)\n"
	@$(PRINT) "   1 - Show all Output\n"
	@$(PRINT) "   2 - Show all file operations and messages\n"
	@$(PRINT) "   3 - Show messages only\n"
	@$(PRINT) "\n### Choice [0|1|2|3]: "
	@read n; \
	$(EEECHO) "## Updating Makefile\n"; \
	sed -i "0,/VERBOSITY/{s/VERBOSITY .*/VERBOSITY = $$n/}" Makefile

## Pull Go libraries into Vendor
vendor:
	@$(ECHO) "\n## $(Name) Vendor\n#####\n"
	@$(MKDIR) $(Lib)
	@$(ECHO) "Library will be vendored into: "
	@$(ECHO) "\t$(LIB)\n"
	@$(PRINT) "go get: "
	@read n; git submodule add "https://$$n" "lib/src/$$n"
	@$(ECHO) "\n## Done\n#####\n"

## Update all Vendor libraries
vendor-update:
	@$(ECHO) "\n## $(Name) Vendor Update\n#####\n"
	@$(EEECHO) "\n####\n!! WARNING !!\n####\nThis may break your code\n\n"
	@$(EECHO) "## Updating all vendors to latest commits...\n"
	@git submodule -q foreach git pull -q origin master
	@$(ECHO) "\n## Done\n#####\n"
