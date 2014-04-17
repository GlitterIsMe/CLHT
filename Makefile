#################################
# Architecture dependent settings
#################################

ifndef ARCH
    ARCH_NAME = $(shell uname -m)
endif

ifeq ($(ARCH_NAME), i386)
    ARCH = x86
    CFLAGS += -m32
    LDFLAGS += -m32
    SSPFD = -lsspfd_x86
    LDFLAGS += -L$(LIBSSMEM)/lib -lssmem_x86
endif

ifeq ($(ARCH_NAME), i686)
    ARCH = x86
    CFLAGS += -m32
    LDFLAGS += -m32
    SSPFD = -lsspfd_x86
    LDFLAGS += -L$(LIBSSMEM)/lib -lssmem_x86
endif

ifeq ($(ARCH_NAME), x86_64)
    ARCH = x86_64
    CFLAGS += -m64
    LDFLAGS += -m64
    SSPFD = -lsspfd_x86_64
    LDFLAGS += -L$(LIBSSMEM)/lib -lssmem_x86_64
endif

ifeq ($(ARCH_NAME), sun4v)
    ARCH = sparc64
    CFLAGS += -DSPARC=1 -DINLINED=1 -m64
    LDFLAGS += -lrt -m64
    SSPFD = -lsspfd_sparc64
    LDFLAGS += -L$(LIBSSMEM)/lib -lssmem_sparc64
endif

ifeq ($(ARCH_NAME), tile)
    LDFLAGS += -L$(LIBSSMEM)/lib -lssmem_tile
    SSPFD = -lsspfd_tile
endif

ifeq ($(DEBUG),1)
  DEBUG_FLAGS=-Wall -ggdb -g -DDEBUG
  COMPILE_FLAGS=-O0 -DADD_PADDING -fno-inline
else ifeq ($(DEBUG),2)
  DEBUG_FLAGS=-Wall
  COMPILE_FLAGS=-O0 -DADD_PADDING -fno-inline
else
  DEBUG_FLAGS=-Wall
  COMPILE_FLAGS=-O3 -DADD_PADDING
endif

ifeq ($(SET_CPU),0)
	COMPILE_FLAGS += -DNO_SET_CPU
endif

ifeq ($(LATENCY),1)
	COMPILE_FLAGS += -DCOMPUTE_LATENCY -DDO_TIMINGS
endif

ifeq ($(LATENCY),2)
	COMPILE_FLAGS += -DCOMPUTE_LATENCY -DDO_TIMINGS -DUSE_SSPFD -DLATENCY_ALL_CORES=0
	LIBS += $(SSPFD) -lm
endif

ifeq ($(LATENCY),3)
	COMPILE_FLAGS += -DCOMPUTE_LATENCY -DDO_TIMINGS -DUSE_SSPFD -DLATENCY_ALL_CORES=1
	LIBS += $(SSPFD) -lm
endif

ifeq ($(LATENCY),4)
	COMPILE_FLAGS += -DCOMPUTE_LATENCY -DDO_TIMINGS -DUSE_SSPFD -DLATENCY_PARSING=1
	LIBS += $(SSPFD) -lm
endif

ifeq ($(LATENCY),5)
	COMPILE_FLAGS += -DCOMPUTE_LATENCY -DDO_TIMINGS -DUSE_SSPFD -DLATENCY_PARSING=1 -DLATENCY_ALL_CORES=1
	LIBS += $(SSPFD) -lm
endif

TOP := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

LIBS+=-L$(TOP)/external/lib
LIBS_MP+=-L$(TOP)/external/lib

SRCPATH := $(TOP)/src
MAININCLUDE := $(TOP)/include

ifeq ($(M),1)
LIBS += -lsspfd
COMPILE_FLAGS += -DUSE_SSPFD
endif

# ALL= hyht hyht_lat hyhtp hyht_lat hyhtp_lat hyht_res hyht_res_lat
ALL= hyht_res math_cache lfht math_cache_lf math_cache_nogc_lf math_cache_lf_dup lfht lfht_only_map_rem lfht_dup hyht_lock_ins lfht_res hyht_linked

LIBS_MP += -lssmp

# default setings
PLATFORM=-DDEFAULT
GCC=gcc
PLATFORM_NUMA=0
OPTIMIZE=
LIBS+= -lrt -lpthread -lm -lssmem
LIBS_MP+= -lrt -lm

UNAME := $(shell uname -n)

ifeq ($(UNAME), lpd48core)
PLATFORM=-DOPTERON
GCC=gcc-4.8
PLATFORM_NUMA=1
OPTIMIZE=-DOPTERON_OPTIMIZE
LIBS+= -lrt -lpthread -lm -lnuma
LIBS_MP+= -lrt -lm -lnuma
endif

ifeq ($(UNAME), lpdxeon2680)
PLATFORM=-DXEON2
GCC=gcc
PLATFORM_NUMA=1
OPTIMIZE=
LIBS+= -lrt -lpthread -lm -lnuma
LIBS_MP+= -lrt -lm -lnuma
endif


ifeq ($(UNAME), lpdpc4)
PLATFORM=-DCOREi7
GCC=gcc
PLATFORM_NUMA=0
OPTIMIZE=
LIBS+= -lrt -lpthread -lm
LIBS_MP+= -lrt -lm
endif

ifeq ($(UNAME), lpdpc34)
PLATFORM=-DCOREi7 -DRTM
GCC=gcc-4.8
PLATFORM_NUMA=0
OPTIMIZE=
LIBS+= -lrt -lpthread -lm -mrtm
LIBS_MP+= -lrt -lm
endif

ifeq ($(UNAME), diascld9)
PLATFORM=-DOPTERON2
GCC=gcc
LIBS+= -lrt -lpthread -lm
LIBS_MP+= -lrt -lm
endif

ifeq ($(UNAME), diassrv8)
PLATFORM=-DXEON
GCC=gcc
PLATFORM_NUMA=1
LIBS+= -lrt -lpthread -lm -lnuma
LIBS_MP+= -lrt -lm -lnuma
endif

ifeq ($(UNAME), diascld19)
PLATFORM=-DXEON2
GCC=gcc
LIBS+= -lrt -lpthread -lm
LIBS_MP+= -lrt -lm
endif

ifeq ($(UNAME), maglite)
PLATFORM=-DSPARC
GCC:=/opt/csw/bin/gcc
LIBS+= -lrt -lpthread -lm
LIBS_MP+= -lrt -lm
COMPILE_FLAGS+= -m64 -mcpu=v9 -mtune=v9
endif

ifeq ($(UNAME), parsasrv1.epfl.ch)
PLATFORM=-DTILERA
GCC=tile-gcc
LIBS+= -lrt -lpthread -lm -ltmc
LIBS_MP+= -lrt -lm -ltmc
endif

ifeq ($(UNAME), smal1.sics.se)
PLATFORM=-DTILERA
GCC=tile-gcc
LIBS+= -lrt -lpthread -lm -ltmc
LIBS_MP+= -lrt -lm -ltmc
endif

COMPILE_FLAGS += $(PLATFORM)
COMPILE_FLAGS += $(OPTIMIZE)

PRIMITIVE=-DLOCKS

INCLUDES := -I$(MAININCLUDE) -I$(TOP)/external/include
OBJ_FILES := 
OBJ_FILES_MP :=

BMARKS := bmarks

default: normal

all: $(ALL)

normal: clean hyht_res lfht_res hyht_mem lfht_mem

dht.o: src/mcore_malloc.c include/mcore_malloc.h include/dht.h
	$(GCC) -D_GNU_SOURCE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) -c src/mcore_malloc.c $(LIBS)

hyht: $(BMARKS)/main_lock.c $(OBJ_FILES) src/dht.c include/dht.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/dht.c -o hyht $(LIBS)

hyht_res: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT $(INCLUDES) $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/dht_res.c src/hyht_gc.c -o hyht $(LIBS)

hyht_res_no_next: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/dht_res_no_next.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/dht_res_no_next.c src/hyht_gc.c -o hyht_nn $(LIBS)

hyht_ro: $(BMARKS)/test_ro.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h include/prand.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/test_ro.c src/dht_res.c src/hyht_gc.c -o hyht_ro $(LIBS)

hyht_simple: $(BMARKS)/test_simple.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h include/prand.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/test_simple.c src/dht_res.c src/hyht_gc.c -o hyht_simple $(LIBS)


hyht_linked: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/dht_linked.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DHYHT_LINKED  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/dht_linked.c src/hyht_gc.c -o hyht_linked $(LIBS)

hyht_linked_lat: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/dht_linked.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE -DHYHT_LINKED  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/dht_linked.c src/hyht_gc.c -o hyht_linked_lat $(LIBS)

lfht: $(BMARKS)/main_lock.c $(OBJ_FILES) src/lfht.c include/lfht.h include/prand.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/lfht.c -o lfht $(LIBS)

lfht_res: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/lfht_res.c include/lfht_res.h src/hyht_gc.c
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE_RES  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/lfht_res.c src/hyht_gc.c -o lfht_res $(LIBS)

lfht_res_lat: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/lfht_res.c include/lfht_res.h src/hyht_gc.c
	$(GCC) -D_GNU_SOURCE -DLOCKFREE_RES  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/lfht_res.c src/hyht_gc.c -o lfht_res_lat $(LIBS)

lfht_mem: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/lfht_res.c include/lfht_res.h src/hyht_gc.c
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE_RES  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_mem.c src/lfht_res.c src/hyht_gc.c -o lfhtm $(LIBS)


hyht_lock_ins: $(BMARKS)/main_lock.c $(OBJ_FILES) src/hyht_lock_ins.c include/hyht_lock_ins.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCK_INS $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/hyht_lock_ins.c -o hyht_lock_ins $(LIBS)

lfht_dup: $(BMARKS)/main_lock.c $(OBJ_FILES) src/lfht_dup.c include/lfht_dup.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/lfht_dup.c -o lfht_dup $(LIBS)


lfht_assembly: src/lfht.c include/lfht.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE  -S $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) src/lfht.c $(LIBS)

lfht_only_map_rem: $(BMARKS)/main_lock.c $(OBJ_FILES) src/lfht_only_map_rem.c include/lfht_only_map_rem.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/lfht_only_map_rem.c -o lfht_only_map_rem $(LIBS)

hyht_res_lat: $(BMARKS)/main_lock_res.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_res.c src/dht_res.c src/hyht_gc.c -o hyht_lat $(LIBS)

hyht_mem: $(BMARKS)/main_lock_mem.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_mem.c src/dht_res.c src/hyht_gc.c -o hyhtm $(LIBS)

hyht_mem_lat: $(BMARKS)/main_lock_mem.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock_mem.c src/dht_res.c src/hyht_gc.c -o hyht_latm $(LIBS)

math_cache: $(BMARKS)/math_cache.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT $(INCLUDES) $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(OBJ_FILES) $(BMARKS)/math_cache.c src/dht_res.c src/hyht_gc.c -o math_cache $(LIBS)

math_cache_lf: $(BMARKS)/math_cache.c $(OBJ_FILES) src/lfht.c include/lfht.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache.c src/lfht.c src/hyht_gc.c -o $(BMARKS)/math_cache_lf $(LIBS)

snap_stress: $(BMARKS)/snap_stress.c $(OBJ_FILES) src/lfht.c include/lfht.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES)  $(BMARKS)/snap_stress.c src/lfht.c src/hyht_gc.c -o  $(BMARKS)/snap_stress $(LIBS)

full_stress_lf: full_stress.c $(OBJ_FILES) src/lfht.c include/lfht.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) full_stress.c src/lfht.c src/hyht_gc.c -o full_stress_lf $(LIBS)

math_cache_lf_s: $(BMARKS)/math_cache.c $(OBJ_FILES) src/lfht.c include/lfht.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache.c src/lfht.c src/hyht_gc.c $(LIBS) -S

lfht_s_annot: src/lfht.c include/lfht.h
	$(GCC) -c -g -Wa,-a,-ad -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) src/lfht.c $(LIBS) > lfht.lst

math_cache_lf_dup: $(BMARKS)/math_cache.c $(OBJ_FILES) src/lfht_dup.c include/lfht_dup.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache.c src/lfht_dup.c src/hyht_gc.c -o $(BMARKS)/math_cache_lf_dup $(LIBS)

math_cache_lock_ins: $(BMARKS)/math_cache.c $(OBJ_FILES) src/hyht_lock_ins.c include/hyht_lock_ins.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCK_INS $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache.c src/hyht_lock_ins.c src/hyht_gc.c -o $(BMARKS)/math_cache_lock_ins $(LIBS)

math_cache_nogc_lf: $(BMARKS)/math_cache_no_gc.c $(OBJ_FILES) src/lfht.c include/lfht.h 
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT -DLOCKFREE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache_no_gc.c src/lfht.c src/hyht_gc.c -o $(BMARKS)/math_cache_nogc_lf $(LIBS)

math_cache_lat: $(BMARKS)/math_cache.c $(OBJ_FILES) src/dht_res.c src/hyht_gc.c include/dht_res.h
	$(GCC) -D_GNU_SOURCE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/math_cache.c src/dht_res.c src/hyht_gc.c -o $(BMARKS)/math_cache_lat $(LIBS)


hyhtp: $(BMARKS)/main_lock.c $(OBJ_FILES) src/dht_packed.c include/dht_packed.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/dht_packed.c -o hyhtp $(LIBS)

hyhtp_lat: $(BMARKS)/main_lock.c $(OBJ_FILES) src/dht_packed.c include/dht_packed.h
	$(GCC) -D_GNU_SOURCE  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/dht_packed.c -o hyhtp_lat $(LIBS)


hyht_lat: $(BMARKS)/main_lock.c $(OBJ_FILES) src/dht.c include/dht.h
	$(GCC) -D_GNU_SOURCE $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/dht.c -o hyht_lat $(LIBS)


hylzht: $(BMARKS)/main_lock.c $(OBJ_FILES) src/hylzht.c include/hylzht.h
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) $(BMARKS)/main_lock.c src/hylzht.c  -o hylzht $(LIBS)


noise: noise.c
	$(GCC) -D_GNU_SOURCE -DCOMPUTE_THROUGHPUT  $(COMPILE_FLAGS) $(PRIMITIVE)  $(DEBUG_FLAGS) $(INCLUDES) $(OBJ_FILES) noise.c -o noise $(LIBS)

clean:				
	rm -f *.o hyht* math_cache math_cache_lf* math_cache_nogc_lf lfht* full_stress_lf snap_stress
