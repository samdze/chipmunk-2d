#
# CMake include file for Playdate libraries
#

cmake_minimum_required(VERSION 3.19)

set(CMAKE_VERBOSE_MAKEFILE TRUE)
set(SDK $ENV{PLAYDATE_SDK_PATH})

add_compile_definitions(TARGET_EXTENSION TRUE)
add_compile_definitions(PLAYDATE TRUE)
add_compile_definitions(cpcalloc=pdcalloc)

target_compile_definitions(${PLAYDATE_LIB} PUBLIC CP_USE_DOUBLES=0)
target_compile_definitions(${PLAYDATE_LIB} PUBLIC CP_USE_CGTYPES=0)

include_directories(${chipmunk_SOURCE_DIR}/playdate/include)
target_sources(${PLAYDATE_LIB} PRIVATE ${chipmunk_SOURCE_DIR}/playdate/src/playdate.c)

include_directories("${SDK}/C_API")
message(STATUS "SDK Path: " ${SDK})

set(PDC "${SDK}/bin/pdc" -sdkpath "${SDK}")


if (TOOLCHAIN STREQUAL "armgcc")
	# Device-only

	# Glue code
	target_sources(${PLAYDATE_LIB} PRIVATE ${SDK}/C_API/buildsupport/setup.c)

	set(HEAP_SIZE 8388208)
	set(STACK_SIZE 61800)
	set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -x assembler-with-cpp -D__HEAP_SIZE=${HEAP_SIZE} -D__STACK_SIZE=${STACK_SIZE}")

	set(MCFLAGS -mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16 -D__FPU_USED=1)

	target_compile_definitions(${PLAYDATE_LIB} PUBLIC TARGET_PLAYDATE=1)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -Wall -Wno-unknown-pragmas -Wdouble-promotion)
	target_compile_options(${PLAYDATE_LIB} PUBLIC $<$<CONFIG:DEBUG>:-O2>)
	target_compile_options(${PLAYDATE_LIB} PUBLIC $<$<CONFIG:RELEASE>:-O2>)

	target_compile_options(${PLAYDATE_LIB} PUBLIC ${MCFLAGS})
	target_compile_options(${PLAYDATE_LIB} PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -gdwarf-2)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -fverbose-asm)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -mword-relocations -fno-common)
	target_compile_options(${PLAYDATE_LIB} PUBLIC -fsingle-precision-constant)

    target_compile_options(${PLAYDATE_LIB} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>)

	target_link_options(${PLAYDATE_LIB} PUBLIC -nostartfiles)
	target_link_options(${PLAYDATE_LIB} PUBLIC ${MCFLAGS})
	target_link_options(${PLAYDATE_LIB} PUBLIC -T${SDK}/C_API/buildsupport/link_map.ld)
	target_link_options(${PLAYDATE_LIB} PUBLIC "-Wl,-Map=game.map,--cref,--gc-sections,--no-warn-mismatch,--emit-relocs")
	target_link_options(${PLAYDATE_LIB} PUBLIC --entry eventHandlerShim)

else ()
	# Simulator-only
	target_compile_definitions(${PLAYDATE_LIB} PUBLIC TARGET_SIMULATOR=1)
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		target_compile_options(${PLAYDATE_LIB} PUBLIC -cl-single-precision-constant)
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		target_compile_options(${PLAYDATE_LIB} PUBLIC -fsingle-precision-constant)
	endif()
	
	if (MSVC)
		target_compile_definitions(${PLAYDATE_LIB} PUBLIC _WINDLL=1)
		target_compile_options(${PLAYDATE_LIB} PUBLIC /W3)
		target_compile_options(${PLAYDATE_LIB} PUBLIC $<$<CONFIG:DEBUG>:/Od>)
	else()
		target_compile_options(${PLAYDATE_LIB} PUBLIC -Wall -Wstrict-prototypes -Wno-unknown-pragmas -Wdouble-promotion -fPIC)
		target_compile_options(${PLAYDATE_LIB} PUBLIC $<$<CONFIG:DEBUG>:-ggdb -O0>)
	endif()

endif ()
