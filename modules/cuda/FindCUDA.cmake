#
# Try to find CUDA compiler, runtime libraries, and include path.
# Once done this will define
#
# CUDA_FOUND
# CUDA_INCLUDE_PATH
# CUDA_RUNTIME_LIBRARY
# CUDA_COMPILER
#
# It will also define the following macro:
#
# WRAP_CUDA
#

IF (WIN32)
	FIND_PROGRAM (CUDA_COMPILER nvcc.exe
		$ENV{CUDA_BIN_PATH}
		DOC "The CUDA Compiler")
ELSE(WIN32)
	FIND_PROGRAM (CUDA_COMPILER nvcc
		$ENV{CUDA_BIN_PATH}
		/usr/local/cuda/bin
		DOC "The CUDA Compiler")
ENDIF(WIN32)

IF (CUDA_COMPILER)
	GET_FILENAME_COMPONENT (CUDA_COMPILER_DIR ${CUDA_COMPILER} PATH)
	GET_FILENAME_COMPONENT (CUDA_COMPILER_SUPER_DIR ${CUDA_COMPILER_DIR} PATH)
ELSE (CUDA_COMPILER)
	SET (CUDA_COMPILER_DIR .)
	SET (CUDA_COMPILER_SUPER_DIR ..)
ENDIF (CUDA_COMPILER)

FIND_PATH (CUDA_INCLUDE_PATH cuda_runtime.h
	$ENV{CUDA_INC_PATH}
	${CUDA_COMPILER_SUPER_DIR}/include
	${CUDA_COMPILER_DIR}
	DOC "The directory where CUDA headers reside")

FIND_PATH (CUDA_UTIL_INCLUDE_PATH cutil.h
    $ENV{CUDA_UTIL_INC_PATH}
    ${CUDA_COMPILER_SUPER_DIR}/include
	${CUDA_COMPILER_DIR}
	${CUDA_COMPILER_SUPER_DIR}/NVIDIA_CUDA_SDK/common/inc
    DOC "Location of cutil.h")

FIND_LIBRARY (CUDA_UTIL_LIBRARY
	NAMES cutil cutil32
	PATHS
	$ENV{CUDA_UTIL_LIB_PATH}
	${CUDA_COMPILER_SUPER_DIR}/lib
	${CUDA_COMPILER_DIR}
	${CUDA_COMPILER_SUPER_DIR}/NVIDIA_CUDA_SDK/lib
	DOC "The CUDA util runtime library libcutil.a (full path including the filename")

FIND_LIBRARY (CUDA_RUNTIME_LIBRARY
	NAMES cudart
	PATHS
	$ENV{CUDA_LIB_PATH}
	${CUDA_COMPILER_SUPER_DIR}/lib
	${CUDA_COMPILER_DIR}
	DOC "The CUDA runtime library")

IF (CUDA_INCLUDE_PATH AND CUDA_RUNTIME_LIBRARY)
	SET (CUDA_FOUND TRUE)
ELSE (CUDA_INCLUDE_PATH AND CUDA_RUNTIME_LIBRARY)
	SET (CUDA_FOUND FALSE)
ENDIF (CUDA_INCLUDE_PATH AND CUDA_RUNTIME_LIBRARY)

SET (CUDA_LIBRARIES ${CUDA_RUNTIME_LIBRARY})
SET (CUDA_UTIL_LIBRARIES ${CUDA_UTIL_LIBRARY})


MARK_AS_ADVANCED (CUDA_FOUND CUDA_COMPILER CUDA_RUNTIME_LIBRARY)


#SET(CUDA_OPTIONS "-ncfe")

IF(UNIX AND K3D_UINT_T_64_BITS)
    SET(CUDA_LINUX_64_FLAGS "-Xcompiler -fPIC")
ELSE(UNIX AND K3D_UINT_T_64_BITS)
    SET(CUDA_LINUX_64_FLAGS "")
ENDIF(UNIX AND K3D_UINT_T_64_BITS)

SET(CUDA_OPTIONS "")
OPTION(CUDA_EMULATION "Enable Device Emulation" ON)

IF (CUDA_EMULATION)
	SET (CUDA_OPTIONS "${CUDA_OPTIONS}-deviceemu;-D_DEVICEEMU;-g")
ENDIF (CUDA_EMULATION)


# Get include directories.
MACRO(GET_CUDA_INC_DIRS _cuda_INC_DIRS)
	SET(${_cuda_INC_DIRS})
	GET_DIRECTORY_PROPERTY(_inc_DIRS INCLUDE_DIRECTORIES)

	FOREACH(_current ${_inc_DIRS})
		SET(${_cuda_INC_DIRS} ${${_cuda_INC_DIRS}} "-I" ${_current})
	ENDFOREACH(_current ${_inc_DIRS})
	
	SET(${_cuda_INC_DIRS} ${${_cuda_INC_DIRS}} "-I" ${CUDA_INCLUDE_PATH})
    SET(${_cuda_INC_DIRS} ${${_cuda_INC_DIRS}} "-I" ${CUDA_UTIL_INCLUDE_PATH})
    
    #MESSAGE("_cuda_INC_DIRS = ${${_cuda_INC_DIRS}}")

#	IF (CMAKE_SYTEM_INCLUDE_PATH)
#		SET(${_cuda_INC_DIRS} ${${_cuda_INC_DIRS}} "-I" ${CMAKE_SYSTEM_INCLUDE_PATH})
#	ENDIF (CMAKE_SYTEM_INCLUDE_PATH)
#	IF (CMAKE_INCLUDE_PATH)
#		SET(${_cuda_INC_DIRS} ${${_cuda_INC_DIRS}} "-I" ${CMAKE_INCLUDE_PATH})
#	ENDIF (CMAKE_INCLUDE_PATH)

ENDMACRO(GET_CUDA_INC_DIRS)


# Get file dependencies.
MACRO (GET_CUFILE_DEPENDENCIES dependencies file)
	GET_FILENAME_COMPONENT(filepath ${file} PATH)
	
	#  parse file for dependencies
	FILE(READ "${file}" CONTENTS)
	#STRING(REGEX MATCHALL "#[ \t]*include[ \t]+[<\"][^>\"]*" DEPS "${CONTENTS}")
	STRING(REGEX MATCHALL "#[ \t]*include[ \t]+\"[^\"]*" DEPS "${CONTENTS}")
	
	SET(${dependencies})
	
	FOREACH(DEP ${DEPS})
		STRING(REGEX REPLACE "#[ \t]*include[ \t]+\"" "" DEP "${DEP}")
		
		# clear the dependency path so that the correct version of the file can be found
		SET (PATH_OF_${DEP} "${PATH_OF_${DEP}}-NOTFOUND")

		FIND_PATH(PATH_OF_${DEP} ${DEP} ${filepath})

		IF(NOT ${PATH_OF_${DEP}} STREQUAL PATH_OF_${DEP}-NOTFOUND)
			#MESSAGE("${file} : ${PATH_OF_${DEP}}/${DEP}")
			SET(${dependencies} ${${dependencies}} ${PATH_OF_${DEP}}/${DEP})
		ENDIF(NOT ${PATH_OF_${DEP}} STREQUAL PATH_OF_${DEP}-NOTFOUND)
		
	ENDFOREACH(DEP)

ENDMACRO (GET_CUFILE_DEPENDENCIES)


# WRAP_CUDA(outfile ...)

IF(WIN32)
    SET(CUTIL_LIB "cutil32")
    SET(OFILE ${k3d_BINARY_DIR}/bin/libk3d-cuda-shared.dll)
    SET(CUDA_LIB_OUTPUT_PATH "bin")
ELSE(WIN32)
    SET(CUTIL_LIB "cutil")
    SET(OFILE ${k3d_BINARY_DIR}/lib/libk3d-cuda-shared.so)
    SET(CUDA_LIB_OUTPUT_PATH "lib")
ENDIF(WIN32)
    
MACRO (WRAP_CUDA outfiles)
	GET_CUDA_INC_DIRS(cuda_includes)
	#MESSAGE(${cuda_includes})

	FOREACH (INFILE ${ARGN})
		GET_FILENAME_COMPONENT (ABSFILE ${INFILE} ABSOLUTE)
		SET(INFILES ${INFILES} ${ABSFILE})
	ENDFOREACH (INFILE)
	
	GET_FILENAME_COMPONENT(CUTIL_PATH ${CUDA_UTIL_LIBRARY} PATH)

	#GET_CUFILE_DEPENDENCIES(CUDEPS ${CUFILE})
	#MESSAGE("${CUDEPS}")

	ADD_CUSTOM_COMMAND (
			OUTPUT ${OFILE}
			COMMAND ${CUDA_COMPILER}
			ARGS -shared ${CUDA_LINUX_64_FLAGS}
                ${CUDA_OPTIONS}
				${cuda_includes} -o ${OFILE} ${INFILES}
				-lcudart -L${CUTIL_PATH} -l${CUTIL_LIB}
			DEPENDS ${INFILES})

        #MACRO_ADD_FILE_DEPENDENCIES(${CUFILE} ${OFILE})

		SET (${outfiles} ${${outfiles}} ${OFILE})
	
	SET_SOURCE_FILES_PROPERTIES(${outfiles} PROPERTIES GENERATED 1)
	INSTALL(FILES ${OFILE} DESTINATION ${CUDA_LIB_OUTPUT_PATH})
	
ENDMACRO (WRAP_CUDA)

# define a makro to build a CUDA module
MACRO(K3D_BUILD_CUDA_MODULE PLUGIN_NAME)
	PROJECT(${PLUGIN_NAME})
    
	FILE(GLOB SOURCES *.cpp)

	IF(CMAKE_HAS_SORT)
		LIST(SORT SOURCES)
	ENDIF(CMAKE_HAS_SORT)

    ADD_LIBRARY(${PROJECT_NAME} SHARED ${CUDA_SOURCES} ${SOURCES} )
	
    SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".module" LINK_FLAG -L.)

	INSTALL(TARGETS ${PROJECT_NAME}
		RUNTIME DESTINATION lib/k3d/plugins
		LIBRARY DESTINATION lib/k3d/plugins)
    
ENDMACRO(K3D_BUILD_CUDA_MODULE)
