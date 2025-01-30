# Makefile for the Audio Mixer examples & objects
#
# Author: Jeroen Knoester
# Version 2.2
# Revision: 20250130
#
# To use:
# * Set the COMPILE_C variable to either 0 or 1. If set to 1, the C example
#   will be compiled, if set to 0 the C example will not be compiled.
#
#   Note: if the COMPILE_C variable is set to 1, the make script will create a
#         subdirectory "Data" in the directory given in INSTLOC.
# * Replace the value for INSTLOC with the desired installation location
#   for examples & mixer.o/converter.o
# * Replace the value for SYSTEMDIR with the location of the Amiga NDK (v1.3+)
# * Replace the value for LIBS with the location of the Amiga library file
#   found in the NDK (V1.3+).
# * (optional) Replace the value for VCCFG with the location of the VBCC 
#   configuration file.
#
# Note: make install will attempt to create the directory configured in 
#       INSTLOC if it does not already exist. Likewise, it will attempt to
#       create the subdirectories Mixer and Converter if they don't already
#       exist.
# Note: the default assembler is VASM
#       the default linker is VLINK
#       the default C compiler is VBCC
#       If these are changed, remember to also change the assembler/linker/C
#       compiler flag values as needed.
# Note: this makefile supports both Windows and Unix-like systems (including
#       Linux, BSD and MacOS X
.DEFAULT_GOAL := all
.PHONY: housekeeping
.PHONY: housekeeping_cleanup
.PHONY: clean_internal

# Set flag below to 1 to enable compiling the C programs
COMPILE_C=1

# Setup where executables should be installed
INSTLOC=C:\Development\AmigaEnvironment\AmigaTransfer\AudioMixer

# Setup library location
LIBS=-L C:\Development\AmigaDev\NDK13\INCLUDE-STRIP1.3\LIB
#LIBS=-L C:\Development\AmigaDev\NDK39\Include\linker_libs

# Setup include directories
MAINDIR=.
SYSTEMDIR=C:\Development\AmigaDev\NDK13\INCLUDES1.3\INCLUDE.I
#SYSTEMDIR=C:\Development\AmigaDev\NDK39\Include\include_i

# Setup VBCC configuration file
VCCFG=C:\Development\VBCC\config\kick13

# Setup assembler, linker and C compiler
ASM=vasmm68k_mot
LNK=vlink
CC=vc

# Setup assembler flags
ASMFLAGS_BASE=-nowarn=62 -kick1hunks -Fhunk -m68000 -allmp
ASMFLAGS_STARTUP=-no-opt -nowarn=62 -kick1hunks -Fhunk -m68010 -allmp

# Setup linker flags
LNKFLAGS=$(LIBS) -l amiga -bamigahunk -s -Z

# Setup C compiler flags
CCFLAGS=+$(VCCFG) -c 
CCLNKFLAGS=+$(VCCFG)

# Detect type of OS used (Windows or Unix-like)
# Note: the $(strip \) is used to avoid problems with escaping '\'.
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    SLASH := $(strip \)
	CP := copy /Y >NUL 2>NUL
	RM := del /Q /F >NUL 2>NUL
	MKDIR := mkdir >NUL 
else
    DETECTED_OS := Unix-like
	SLASH := /
	CP := cp -u -f 
	RM := rm -f 
	MKDIR := mkdir -p 
endif

# Setup required suffixes for make
.SUFFIXES: .asm .c .o

# Setup mixer directories
MIXERDIR=$(MAINDIR)$(SLASH)Mixer
CONVERTERDIR=$(MAINDIR)$(SLASH)Converter
PLUGINSDIR=$(MAINDIR)$(SLASH)Plugins

# Setup generic object directories
EXAMPLEDIR=$(MAINDIR)$(SLASH)Examples
GFXDIR=$(EXAMPLEDIR)$(SLASH)GFX
DATADIR=$(EXAMPLEDIR)$(SLASH)Data
PTPLAYERDIR=$(EXAMPLEDIR)$(SLASH)PTPlayer
LSPLAYERDIR=$(EXAMPLEDIR)$(SLASH)LSP
STARTUPDIR=$(EXAMPLEDIR)$(SLASH)Startup
SUPPORTDIR=$(EXAMPLEDIR)$(SLASH)Support

# Detect type of OS used (Windows or Unix-like)
# Note: this part deals with batch processing build artefacts
ifeq ($(OS),Windows_NT)
	# Batch commands for dealing with housekeeping
	CPDIR_MIXER = for /d %%d in ($(EXAMPLEDIR)$(SLASH)*) do if exist %%d\Mixer $(CP) "$(MIXERDIR)$(SLASH)mixer.asm" %%d$(SLASH)Mixer$(SLASH) & $(CP) "$(MIXERDIR)$(SLASH)mixer.i" %%d$(SLASH)Mixer$(SLASH) & $(CP) "$(MIXERDIR)$(SLASH)mixer.h" %%d$(SLASH)Mixer$(SLASH)
	CPDIR_PLUGINS = for /d %%d in ($(EXAMPLEDIR)$(SLASH)*) do if exist %%d\Plugins $(CP) "$(PLUGINSDIR)$(SLASH)plugins.asm" %%d$(SLASH)Plugins$(SLASH) & $(CP) "$(PLUGINSDIR)$(SLASH)plugins.i" %%d$(SLASH)Plugins$(SLASH) & $(CP) "$(PLUGINSDIR)$(SLASH)plugins.h" %%d$(SLASH)Plugins$(SLASH)
	RMDIR_MIXER := $(RM) /S $(EXAMPLEDIR)$(SLASH)mixer.asm $(EXAMPLEDIR)$(SLASH)mixer.i $(EXAMPLEDIR)$(SLASH)mixer.h
	RMDIR_PLUGINS := $(RM) /S $(EXAMPLEDIR)$(SLASH)plugins.asm $(EXAMPLEDIR)$(SLASH)plugins.i $(EXAMPLEDIR)$(SLASH)plugins.h
	
	# Batch commands for dealing with make clean
	RM_CLEAN := $(RM) /S $(MAINDIR)\*.o
else
	# Batch commands for dealing with housekeeping
	CPDIR_MIXER := find Examples -type d -name Mixer -exec $(CP) $(MIXERDIR)/mixer.{asm,i,h} "{}" \;
	CPDIR_PLUGINS := find Examples -type d -name Plugins -exec $(CP) $(PLUGINSDIR)/plugins.{asm,i,h} "{}" \;
	RMDIR_MIXER := $(RM) $(EXAMPLEDIR)/*/Mixer/mixer.{asm,i,h}
	RMDIR_PLUGINS := $(RM) $(EXAMPLEDIR)/*/Plugins/plugins.{asm,i,h}

	# Batch commands for dealing with make clean
	RM_CLEAN := $(RM) -r $(MAINDIR)\*.o
endif

# Set up other directories (individual examples / performance test)
SINGLEMIXERDIR=$(EXAMPLEDIR)$(SLASH)SingleMixerSource
SINGLEMIXERHQDIR=$(EXAMPLEDIR)$(SLASH)SingleMixerHQSource
MULTIMIXERDIR=$(EXAMPLEDIR)$(SLASH)MultiMixerSource
PAIRMIXERDIR=$(EXAMPLEDIR)$(SLASH)MultiPairedMixerSource
MINIMALMIXERDIR=$(EXAMPLEDIR)$(SLASH)MinimalMixerSource

CALLBACKEXAMPLEDIR=$(EXAMPLEDIR)$(SLASH)CallbackSource
PLUGINEXAMPLEDIR=$(EXAMPLEDIR)$(SLASH)PluginSource

PERFTESTDIR=$(MAINDIR)$(SLASH)Tools$(SLASH)PerformanceTestSource

# Set up C program directories
CMIXERDIR=$(EXAMPLEDIR)$(SLASH)CMixerSource
COSLEGALDIR=$(EXAMPLEDIR)$(SLASH)OSLegalSource
CSAMCONVDIR=$(MAINDIR)$(SLASH)Tools$(SLASH)SampleConverterSource

# Setup example/performance test executable names
SINGLEMIXEREXE=SingleMixerExample
SINGLEMIXER=$(EXAMPLEDIR)$(SLASH)$(SINGLEMIXEREXE)
SINGLEMIXERHQEXE=SingleMixerHQExample
SINGLEMIXERHQ=$(EXAMPLEDIR)$(SLASH)$(SINGLEMIXERHQEXE)
MULTIMIXEREXE=MultiMixerExample
MULTIMIXER=$(EXAMPLEDIR)$(SLASH)$(MULTIMIXEREXE)
PAIRMIXEREXE=MultiPairedMixerExample
PAIRMIXER=$(EXAMPLEDIR)$(SLASH)$(PAIRMIXEREXE)
MINIMALEXE=MinimalMixerExample
MINIMALMIXER=$(EXAMPLEDIR)$(SLASH)$(MINIMALEXE)

CALLBACKEXE=CallbackExample
CALLBACKEXAMPLE=$(EXAMPLEDIR)$(SLASH)$(CALLBACKEXE)

PLUGINEXE=PluginExample
PLUGINEXAMPLE=$(EXAMPLEDIR)$(SLASH)$(PLUGINEXE)

PERFTESTEXE=PerformanceTest
PERFTEST=$(MAINDIR)$(SLASH)Tools$(SLASH)$(PERFTESTEXE)

# Setup C executable names
CMIXEREXE=CMixerExample
CMIXER=$(EXAMPLEDIR)$(SLASH)$(CMIXEREXE)
COSLEGALEXE=OSLegalExample
COSLEGAL=$(EXAMPLEDIR)$(SLASH)$(COSLEGALEXE)
CSAMCONVEXE=SampleConverter
CSAMCONV=$(MAINDIR)$(SLASH)Tools$(SLASH)$(CSAMCONVEXE)

# Setup includes
INCLUDE=-I$(MAINDIR) -I$(SYSTEMDIR) -I$(GFXDIR) -I$(DATADIR) -I$(CONVERTERDIR) -I$(PTPLAYERDIR)
INCLUDE_SUPPORT=-I$(SUPPORTDIR)
INCLUDE_MIXER=-I$(MIXERDIR)
INCLUDE_SING=-I$(SINGLEMIXERDIR)$(SLASH)Mixer -I$(SINGLEMIXERDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_SHQ=-I$(SINGLEMIXERHQDIR)$(SLASH)Mixer -I$(SINGLEMIXERHQDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_MULTI=-I$(MULTIMIXERDIR)$(SLASH)Mixer -I$(MULTIMIXERDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_PAIR=-I$(PAIRMIXERDIR)$(SLASH)Mixer -I$(PAIRMIXERDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_MINIMAL=-I$(MINIMALMIXERDIR)$(SLASH)Mixer -I$(MINIMALMIXERDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_CALLBACK=-I$(CALLBACKEXAMPLEDIR)$(SLASH)Mixer -I$(CALLBACKEXAMPLEDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_PLUGIN=-I$(PLUGINEXAMPLEDIR)$(SLASH)Mixer -I$(PLUGINEXAMPLEDIR)$(SLASH)Plugins -I$(SUPPORTDIR) -I$(PLUGINEXAMPLEDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_PERF=-I$(PERFTESTDIR)$(SLASH)Mixer -I$(PERFTESTDIR)$(SLASH)Plugins -I$(PERFTESTDIR)$(SLASH)Support -I$(SUPPORTDIR)
INCLUDE_CEX=-I$(CMIXERDIR)$(SLASH)Mixer -I$(SUPPORTDIR)
INCLUDE_COS=-I$(COSLEGALDIR)$(SLASH)Mixer -I$(SUPPORTDIR)

# Setup assembler flags for individual targets
ASMFLAGS_STD=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_MIXER) $(INCLUDE_SUPPORT)
ASMFLAGS=$(ASMFLAGS_STD)
ASMFLAGS_SING=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_SING)
ASMFLAGS_SHQ=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_SHQ)
ASMFLAGS_MULTI=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_MULTI)
ASMFLAGS_PAIR=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_PAIR)
ASMFLAGS_MINIMAL=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_MINIMAL)
ASMFLAGS_CALLBACK=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_CALLBACK)
ASMFLAGS_PLUGIN=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_PLUGIN)
ASMFLAGS_PERF=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_PERF)
ASMFLAGS_CEX=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_CEX)
ASMFLAGS_STRT=$(ASMFLAGS_STARTUP) $(INCLUDE) $(INCLUDE_SUPPORT)

# Objects
MIXER=$(MIXERDIR)$(SLASH)mixer.o
CONVERTER=$(CONVERTERDIR)$(SLASH)converter.o
PLUGINS=$(PLUGINSDIR)$(SLASH)plugins.o
GFX=$(GFXDIR)$(SLASH)font.o $(GFXDIR)$(SLASH)blitter.o $(GFXDIR)$(SLASH)copperlists.o
SUPPORT=$(SUPPORTDIR)$(SLASH)support.o
DATA=$(DATADIR)$(SLASH)tiles.o $(DATADIR)$(SLASH)samples.o
PERFDATA=$(DATADIR)$(SLASH)tiles.o 
PTPLAYER=$(PTPLAYERDIR)$(SLASH)ptplayer.o
LSPLAYER=$(LSPLAYERDIR)$(SLASH)LightSpeedPlayer.o $(LSPLAYERDIR)$(SLASH)LightSpeedPlayer_cia.o
MODDATA=$(DATADIR)$(SLASH)module.o
STARTUP=$(STARTUPDIR)$(SLASH)PhotonsMiniWrapper.o
SINGOBJS=$(SINGLEMIXERDIR)$(SLASH)SingleMixer.o $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o $(SINGLEMIXERDIR)$(SLASH)Support$(SLASH)strings.o
SHQOBJS=$(SINGLEMIXERHQDIR)$(SLASH)SingleMixerHQ.o $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer.o $(SINGLEMIXERHQDIR)$(SLASH)Support$(SLASH)strings.o
MULTIOBJS=$(MULTIMIXERDIR)$(SLASH)MultiMixer.o $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o $(MULTIMIXERDIR)$(SLASH)Support$(SLASH)strings.o
PAIROBJS=$(PAIRMIXERDIR)$(SLASH)MultiPairedMixer.o $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o $(PAIRMIXERDIR)$(SLASH)Support$(SLASH)strings.o
MINIMALOBJS=$(MINIMALMIXERDIR)$(SLASH)MinimalMixer.o $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o
CALLBOBJS=$(CALLBACKEXAMPLEDIR)$(SLASH)CallbackExample.o $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.o $(CALLBACKEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.o
PLUGINEXOBJS=$(PLUGINEXAMPLEDIR)$(SLASH)PluginExample.o $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.o $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins.o $(PLUGINEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.o
PERFOBJS=$(PERFTESTDIR)$(SLASH)PerformanceTest.o $(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins.o $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer.o $(PERFTESTDIR)$(SLASH)Support$(SLASH)strings.o

# C objects
CMIXOBJS=$(CMIXERDIR)$(SLASH)CMixer.o $(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o $(CMIXERDIR)$(SLASH)Plugins$(SLASH)plugins.o
COSMIXOBJS=$(COSLEGALDIR)$(SLASH)OSLegalMixer.o $(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer.o $(COSLEGALDIR)$(SLASH)Plugins$(SLASH)plugins.o
CSAMCONVOBJS=$(CSAMCONVDIR)$(SLASH)SampleConverter.o

# Combined objects
MIXEROBJECTS=$(MIXER)
PLUGINSOBJECTS=$(PLUGINS)
GENOBJECTS=$(CONVERTER) $(GFX) $(DATA) $(SUPPORT)
MINGENOBJECTS=$(CONVERTER) $(DATA)
PERFGENOBJECTS=$(CONVERTER) $(TTEXT) $(GFX) $(SUPPORT) $(PERFDATA)
STARTUPOBJECT=$(STARTUP)
SINGOBJECTS=$(SINGOBJS) $(PTPLAYER) $(LSPLAYER) $(MODDATA)
SHQOBJECTS=$(SHQOBJS) $(PTPLAYER) $(LSPLAYER) $(MODDATA)
MULTIOBJECTS=$(MULTIOBJS)
PAIROBJECTS=$(PAIROBJS)
MINIMALOBJECTS=$(MINIMALOBJS)
CALLBACKOBJECTS=$(CALLBOBJS)
PLUGINEXOBJECTS=$(PLUGINEXOBJS)
PERFOBJECTS=$(PERFOBJS)
CMIXEROBJECTS=$(CMIXOBJS)
COSLEGALOBJECTS=$(COSMIXOBJS)
CSAMCONVOBJECTS=$(CSAMCONVOBJS)

# Housekeeping
housekeeping:
	$(CPDIR_MIXER)
	$(CPDIR_PLUGINS)

housekeeping_cleanup:
	$(RMDIR_MIXER)
	$(RMDIR_PLUGINS)
	
# Targets
ifeq ($(COMPILE_C),0)
all: housekeeping $(SINGLEMIXER) $(SINGLEMIXERHQ) $(MULTIMIXER) $(PAIRMIXER) $(MINIMALMIXER) $(PERFTEST) $(CALLBACKEXAMPLE) $(PLUGINEXAMPLE) $(MIXEROBJECTS) $(PLUGINSOBJECTS) housekeeping_cleanup
else
all: housekeeping $(SINGLEMIXER) $(SINGLEMIXERHQ) $(MULTIMIXER) $(PAIRMIXER) $(MINIMALMIXER) $(PERFTEST) $(CALLBACKEXAMPLE) $(PLUGINEXAMPLE) $(CMIXER) $(COSLEGAL) $(CSAMCONV) $(MIXEROBJECTS) $(PLUGINSOBJECTS) housekeeping_cleanup
endif

mixer: $(MIXEROBJECTS) $(CONVERTER) $(PLUGINSOBJECTS)

ifeq ($(COMPILE_C),0)
install: housekeeping $(SINGLEMIXER) $(SINGLEMIXERHQ) $(MULTIMIXER) $(PAIRMIXER) $(MINIMALMIXER) $(CALLBACKEXAMPLE) $(PLUGINEXAMPLE) $(PERFTEST) $(MIXEROBJECTS) $(PLUGINSOBJECTS) housekeeping_cleanup
else
install: housekeeping $(SINGLEMIXER) $(SINGLEMIXERHQ) $(MULTIMIXER) $(PAIRMIXER) $(MINIMALMIXER) $(CALLBACKEXAMPLE) $(PLUGINEXAMPLE) $(PERFTEST) $(CMIXER) $(COSLEGAL) $(CSAMCONV) $(MIXEROBJECTS) $(PLUGINSOBJECTS) housekeeping_cleanup
endif
	if not exist $(INSTLOC) $(MKDIR) $(INSTLOC)
	if not exist $(INSTLOC)$(SLASH)Mixer $(MKDIR) $(INSTLOC)$(SLASH)Mixer
	if not exist $(INSTLOC)$(SLASH)Converter $(MKDIR) $(INSTLOC)$(SLASH)Converter
	if not exist $(INSTLOC)$(SLASH)Plugins $(MKDIR) $(INSTLOC)$(SLASH)Plugins
	$(CP) $(SINGLEMIXER) $(INSTLOC)$(SLASH)$(SINGLEMIXEREXE)
	$(CP) $(SINGLEMIXERHQ) $(INSTLOC)$(SLASH)$(SINGLEMIXERHQEXE)
	$(CP) $(MULTIMIXER) $(INSTLOC)$(SLASH)$(MULTIMIXEREXE)
	$(CP) $(PAIRMIXER) $(INSTLOC)$(SLASH)$(PAIRMIXEREXE)
	$(CP) $(MINIMALMIXER) $(INSTLOC)$(SLASH)$(MINIMALEXE)
	$(CP) $(CALLBACKEXAMPLE) $(INSTLOC)$(SLASH)$(CALLBACKEXE)
	$(CP) $(PLUGINEXAMPLE) $(INSTLOC)$(SLASH)$(PLUGINEXE)
	$(CP) $(PERFTEST) $(INSTLOC)$(SLASH)$(PERFTESTEXE)
	$(CP) $(MIXER) $(INSTLOC)$(SLASH)Mixer
	$(CP) $(CONVERTER) $(INSTLOC)$(SLASH)Converter
	$(CP) $(PLUGINS) $(INSTLOC)$(SLASH)Plugins
ifeq ($(COMPILE_C),1)	
	$(CP) $(CMIXER) $(INSTLOC)$(SLASH)$(CMIXEREXE)
	$(CP) $(COSLEGAL) $(INSTLOC)$(SLASH)$(COSLEGALEXE)
	$(CP) $(CSAMCONV) $(INSTLOC)$(SLASH)$(CSAMCONVEXE)
	if not exist $(INSTLOC)$(SLASH)Data $(MKDIR) $(INSTLOC)$(SLASH)Data
	$(CP) $(EXAMPLEDIR)$(SLASH)Data$(SLASH)zap.raw $(INSTLOC)$(SLASH)Data
	$(CP) $(EXAMPLEDIR)$(SLASH)Data$(SLASH)laser.raw $(INSTLOC)$(SLASH)Data
	$(CP) $(EXAMPLEDIR)$(SLASH)Data$(SLASH)power_up.raw $(INSTLOC)$(SLASH)Data
	$(CP) $(EXAMPLEDIR)$(SLASH)Data$(SLASH)explosion.raw $(INSTLOC)$(SLASH)Data
endif

clean_internal:
	$(RM) $(SINGLEMIXER) $(SINGLEMIXERHQ) $(MULTIMIXER) $(PAIRMIXER)
	$(RM) $(MINIMALMIXER) $(CALLBACKEXAMPLE) $(PLUGINEXAMPLE) $(PERFTEST)
	$(RM_CLEAN)
ifeq ($(COMPILE_C),1)
	$(RM) $(CMIXER) $(COSLEGAL) $(CSAMCONV)
endif

clean: clean_internal housekeeping_cleanup
	
# Note: show_depend will not show dependencies for the C example.
#       It also requires the -depend=make flag which may or may not be VASM
#       specific.
show_depend: ASMFLAGS=$(ASMFLAGS_STD) -depend=make -quiet
show_depend: ASMFLAGS_SING=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_SING) -depend=make -quiet
show_depend: ASMFLAGS_SHQ=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_SHQ) -depend=make -quiet
show_depend: ASMFLAGS_MULTI=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_MULTI) -depend=make -quiet
show_depend: ASMFLAGS_PAIR=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_PAIR) -depend=make -quiet
show_depend: ASMFLAGS_CALLBACK=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_CALLBACK) -depend=make -quiet
show_depend: ASMFLAGS_PERF=$(ASMFLAGS_BASE) $(INCLUDE) $(INCLUDE_PERF) -depend=make -quiet
show_depend: ASMFLAGS_STRT=$(ASMFLAGS_STARTUP) $(INCLUDE) $(INCLUDE_SUPPORT) -depend=make -quiet
show_depend: $(GENOBJECTS) $(SINGOBJECTS) $(STARTUPOBJECT)
show_depend: $(MULTIOBJECTS) $(PAIROBJECTS) $(MINIMALOBJECTS) $(CALLBACKOBJECTS) $(PLUGINEXOBJECTS)
show_depend: $(PERFOBJECTS)
show_depend: $(MIXEROBJECTS)
show_depend: $(PLUGINSOBJECTS)

$(SINGLEMIXER): $(GENOBJECTS) $(SINGOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(SINGOBJECTS) -o $@
$(SINGLEMIXERHQ): $(GENOBJECTS) $(SHQOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(SHQOBJECTS) -o $@
$(MULTIMIXER): $(GENOBJECTS) $(MULTIOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(MULTIOBJECTS) -o $@
$(PAIRMIXER): $(PERFGENOBJECTS) $(PAIROBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(PAIROBJECTS) -o $@
$(MINIMALMIXER): $(MINGENOBJECTS) $(MINIMALOBJECTS)
	$(LNK) $(LNKFLAGS) $(MINIMALOBJECTS) $(MINGENOBJECTS) -o $@
$(CALLBACKEXAMPLE): $(GENOBJECTS) $(CALLBACKOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(CALLBACKOBJECTS) -o $@
$(PLUGINEXAMPLE): $(GENOBJECTS) $(PLUGINEXOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(GENOBJECTS) $(PLUGINEXOBJECTS) -o $@
$(PERFTEST): $(PERFGENOBJECTS) $(PERFOBJECTS) $(STARTUPOBJECT)
	$(LNK) $(LNKFLAGS) $(STARTUPOBJECT) $(PERFGENOBJECTS) $(PERFOBJECTS) -o $@

# add the C programs to the list of targets
ifeq ($(COMPILE_C),1)
$(CMIXER): $(CMIXEROBJECTS)
	$(CC) $(CCLNKFLAGS) $(CMIXEROBJECTS) -o $@
$(COSLEGAL): $(COSLEGALOBJECTS)
	$(CC) $(CCLNKFLAGS) $(COSLEGALOBJECTS) -o $@
$(CSAMCONV): $(CSAMCONVOBJECTS)
	$(CC) $(CCLNKFLAGS) $(CSAMCONVOBJECTS) -o $@
endif

# Assemble generic objects
$(CONVERTERDIR)$(SLASH)converter.o: $(CONVERTERDIR)$(SLASH)converter.asm $(CONVERTERDIR)$(SLASH)converter.i
	$(ASM) $(ASMFLAGS) -DBUILD_CONVERTER $< -o $@
$(MIXERDIR)$(SLASH)mixer.o: $(MIXERDIR)$(SLASH)mixer.asm $(MIXERDIR)$(SLASH)mixer.i $(MIXERDIR)$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS) -DBUILD_MIXER $< -o $@
$(PLUGINSDIR)$(SLASH)plugins.o: $(PLUGINSDIR)$(SLASH)plugins.asm $(PLUGINSDIR)$(SLASH)plugins.i $(PLUGINSDIR)$(SLASH)plugins_config.i $(MIXERDIR)$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS) -DBUILD_PLUGINS $< -o $@
$(GFXDIR)$(SLASH)font.o: $(GFXDIR)$(SLASH)font.asm $(GFXDIR)$(SLASH)font.i
	$(ASM) $(ASMFLAGS) -DBUILD_FONT $< -o $@
$(GFXDIR)$(SLASH)blitter.o: $(GFXDIR)$(SLASH)blitter.asm $(GFXDIR)$(SLASH)blitter.i $(DATADIR)$(SLASH)tiles.i $(GFXDIR)$(SLASH)displaybuffers.i
	$(ASM) $(ASMFLAGS) -DBUILD_BLITTER $< -o $@
$(GFXDIR)$(SLASH)copperlists.o: $(GFXDIR)$(SLASH)copperlists.asm $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)copperlists.i
	$(ASM) $(ASMFLAGS) -DBUILD_COPPERLIST $< -o $@
$(SUPPORTDIR)$(SLASH)support.o: $(SUPPORTDIR)$(SLASH)support.asm $(SUPPORTDIR)$(SLASH)support.i
	$(ASM) $(ASMFLAGS) -DBUILD_SUPPORT=1 $< -o $@
$(DATADIR)$(SLASH)tiles.o: $(DATADIR)$(SLASH)tiles.asm $(DATADIR)$(SLASH)tiles.i $(DATADIR)$(SLASH)sb_tiles_raw
	$(ASM) $(ASMFLAGS) -DBUILD_TILES $< -o $@
$(DATADIR)$(SLASH)samples.o: $(DATADIR)$(SLASH)samples.asm $(DATADIR)$(SLASH)samples.i $(MIXERDIR)$(SLASH)mixer.i $(DATADIR)$(SLASH)zap.raw $(DATADIR)$(SLASH)laser.raw $(DATADIR)$(SLASH)power_up.raw $(DATADIR)$(SLASH)alarm.raw $(DATADIR)$(SLASH)cat.raw $(DATADIR)$(SLASH)dog.raw $(DATADIR)$(SLASH)drums.raw $(DATADIR)$(SLASH)explosion.raw
	$(ASM) $(ASMFLAGS) -DBUILD_SAMPLES $< -o $@
$(DATADIR)$(SLASH)module.o: $(DATADIR)$(SLASH)module.asm $(DATADIR)$(SLASH)module.i $(DATADIR)$(SLASH)SneakyChick.mod
	$(ASM) $(ASMFLAGS) -DBUILD_MOD $< -o $@
$(PTPLAYERDIR)$(SLASH)ptplayer.o: $(PTPLAYERDIR)$(SLASH)ptplayer.asm
	$(ASM) $(ASMFLAGS) $< -o $@
$(LSPLAYERDIR)$(SLASH)LightSpeedPlayer.o: $(LSPLAYERDIR)$(SLASH)LightSpeedPlayer.asm
	$(ASM) $(ASMFLAGS) $< -o $@
$(LSPLAYERDIR)$(SLASH)LightSpeedPlayer_cia.o: $(LSPLAYERDIR)$(SLASH)LightSpeedPlayer_cia.asm
	$(ASM) $(ASMFLAGS) $< -o $@

# Startup object
$(STARTUPDIR)$(SLASH)PhotonsMiniWrapper.o: $(STARTUPDIR)$(SLASH)PhotonsMiniWrapper.asm
	$(ASM) $(ASMFLAGS_STRT) $< -o $@

# SingleMixer objects
$(SINGLEMIXERDIR)$(SLASH)SingleMixer.o: $(SINGLEMIXERDIR)$(SLASH)SingleMixer.asm $(SINGLEMIXERDIR)$(SLASH)SingleMixer.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_SING) -DBUILD_DBUFFERS $< -o $@
$(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(SINGLEMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_SING) -DBUILD_MIXER $< -o $@
$(SINGLEMIXERDIR)$(SLASH)Support$(SLASH)strings.o: $(SINGLEMIXERDIR)$(SLASH)Support$(SLASH)strings.asm $(SINGLEMIXERDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_SING) -DBUILD_STRINGS_SM $< -o $@

# SingleMixerHQ objects
$(SINGLEMIXERHQDIR)$(SLASH)SingleMixerHQ.o: $(SINGLEMIXERHQDIR)$(SLASH)SingleMixerHQ.asm $(SINGLEMIXERHQDIR)$(SLASH)SingleMixerHQ.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer.i $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_SHQ) -DBUILD_DBUFFERS $< -o $@
$(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer.i $(SINGLEMIXERHQDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_SHQ) -DBUILD_MIXER $< -o $@
$(SINGLEMIXERHQDIR)$(SLASH)Support$(SLASH)strings.o: $(SINGLEMIXERHQDIR)$(SLASH)Support$(SLASH)strings.asm $(SINGLEMIXERHQDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_SHQ) -DBUILD_STRINGS_SM $< -o $@

# MultiMixer objects
$(MULTIMIXERDIR)$(SLASH)MultiMixer.o: $(MULTIMIXERDIR)$(SLASH)MultiMixer.asm $(MULTIMIXERDIR)$(SLASH)MultiMixer.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_MULTI) -DBUILD_DBUFFERS $< -o $@
$(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(MULTIMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_MULTI) -DBUILD_MIXER $< -o $@
$(MULTIMIXERDIR)$(SLASH)Support$(SLASH)strings.o: $(MULTIMIXERDIR)$(SLASH)Support$(SLASH)strings.asm $(MULTIMIXERDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_MULTI) -DBUILD_STRINGS_MM $< -o $@
	
# MultiPairMixer objects
$(PAIRMIXERDIR)$(SLASH)MultiPairedMixer.o: $(PAIRMIXERDIR)$(SLASH)MultiPairedMixer.asm $(PAIRMIXERDIR)$(SLASH)MultiPairedMixer.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PAIR) -DBUILD_DBUFFERS $< -o $@
$(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(PAIRMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PAIR) -DBUILD_MIXER $< -o $@
$(PAIRMIXERDIR)$(SLASH)Support$(SLASH)strings.o: $(PAIRMIXERDIR)$(SLASH)Support$(SLASH)strings.asm $(PAIRMIXERDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_PAIR) -DBUILD_STRINGS_MP $< -o $@
	
# MinimalMixer objects
$(MINIMALMIXERDIR)$(SLASH)MinimalMixer.o: $(MINIMALMIXERDIR)$(SLASH)MinimalMixer.asm $(SUPPORTDIR)$(SLASH)debug.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_MINIMAL) $< -o $@
$(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(MINIMALMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_MINIMAL) -DBUILD_MIXER $< -o $@

# CallbackExample objects
$(CALLBACKEXAMPLEDIR)$(SLASH)CallbackExample.o: $(CALLBACKEXAMPLEDIR)$(SLASH)CallbackExample.asm $(CALLBACKEXAMPLEDIR)$(SLASH)CallbackExample.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.i $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_CALLBACK) -DBUILD_DBUFFERS $< -o $@
$(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.i $(CALLBACKEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_CALLBACK) -DBUILD_MIXER $< -o $@
$(CALLBACKEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.o: $(CALLBACKEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.asm $(CALLBACKEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_CALLBACK) -DBUILD_STRINGS_CB $< -o $@
	
# PluginExample objects
$(PLUGINEXAMPLEDIR)$(SLASH)PluginExample.o: $(PLUGINEXAMPLEDIR)$(SLASH)PluginExample.asm $(PLUGINEXAMPLEDIR)$(SLASH)PluginExample.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.i $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer_config.i $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins.i $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins_config.i
	$(ASM) $(ASMFLAGS_PLUGIN) -DBUILD_DBUFFERS $< -o $@
$(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer.i $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PLUGIN) -DBUILD_MIXER $< -o $@
$(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins.o: $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins.asm $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins.i $(PLUGINEXAMPLEDIR)$(SLASH)Plugins$(SLASH)plugins_config.i $(PLUGINEXAMPLEDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PLUGIN) -DBUILD_PLUGINS $< -o $@
$(PLUGINEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.o: $(PLUGINEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.asm $(PLUGINEXAMPLEDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_PLUGIN) -DBUILD_STRINGS_PL $< -o $@

# PerformanceTest objects
$(PERFTESTDIR)$(SLASH)PerformanceTest.o: $(PERFTESTDIR)$(SLASH)PerformanceTest.asm $(PERFTESTDIR)$(SLASH)PerformanceTest.i $(SUPPORTDIR)$(SLASH)debug.i $(GFXDIR)$(SLASH)displaybuffers.i $(GFXDIR)$(SLASH)blitter.i $(GFXDIR)$(SLASH)copperlists.i $(GFXDIR)$(SLASH)font.i $(CONVERTERDIR)$(SLASH)converter.i $(DATADIR)$(SLASH)samples.i $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer.i $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer_config.i $(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins.i
	$(ASM) $(ASMFLAGS_PERF) -DBUILD_DBUFFERS $< -o $@
$(PERFTESTDIR)$(SLASH)Mixer$(SLASH)performance_test_wrapper.o: $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)performance_test_wrapper.asm $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)performance_test_wrapper.i $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer_.i $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PERF) -DBUILD_MIXER_PMIX -DBUILD_MIXER_POSTFIX $< -o $@
$(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins.o: $(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins.asm $(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins.i $(PERFTESTDIR)$(SLASH)Plugins$(SLASH)plugins_config.i $(PERFTESTDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_PERF) -DBUILD_PLUGINS_PMIX $< -o $@
$(PERFTESTDIR)$(SLASH)Support$(SLASH)strings.o: $(PERFTESTDIR)$(SLASH)Support$(SLASH)strings.asm $(PERFTESTDIR)$(SLASH)Support$(SLASH)strings.i
	$(ASM) $(ASMFLAGS_PERF) -DBUILD_STRINGS_PMIX $< -o $@
	
# C example objects
ifeq ($(COMPILE_C),1)
$(CMIXERDIR)$(SLASH)CMixer.o: $(CMIXERDIR)$(SLASH)CMixer.c $(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.h
	$(CC) $(CCFLAGS) $< -c
$(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer.i $(CMIXERDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_CEX) -DBUILD_MIXER $< -o $@
$(CMIXERDIR)$(SLASH)Plugins$(SLASH)plugins.o: $(CMIXERDIR)$(SLASH)Plugins$(SLASH)plugins.asm $(CMIXERDIR)$(SLASH)Plugins$(SLASH)plugins.i $(CMIXERDIR)$(SLASH)Plugins$(SLASH)plugins_config.i
	$(ASM) $(ASMFLAGS_CEX) -DBUILD_PLUGINS $< -o $@
$(COSLEGALDIR)$(SLASH)OSLegalMixer.o: $(COSLEGALDIR)$(SLASH)OSLegalMixer.c $(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer.h
	$(CC) $(CCFLAGS) $< -c
$(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer.o: $(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer.asm $(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer.i $(COSLEGALDIR)$(SLASH)Mixer$(SLASH)mixer_config.i
	$(ASM) $(ASMFLAGS_CEX) -DBUILD_MIXER $< -o $@
$(COSLEGALDIR)$(SLASH)Plugins$(SLASH)plugins.o: $(COSLEGALDIR)$(SLASH)Plugins$(SLASH)plugins.asm $(COSLEGALDIR)$(SLASH)Plugins$(SLASH)plugins.i $(COSLEGALDIR)$(SLASH)Plugins$(SLASH)plugins_config.i
	$(ASM) $(ASMFLAGS_CEX) -DBUILD_PLUGINS $< -o $@
$(CSAMCONVDIR)$(SLASH)SampleConverter.o: $(CSAMCONVDIR)$(SLASH)SampleConverter.c
	$(CC) $(CCFLAGS) $< -c
endif