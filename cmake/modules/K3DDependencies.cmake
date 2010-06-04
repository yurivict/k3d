MACRO(K3D_CONDITIONAL_BUILD BUILD_OPTION BUILD_DIRECTORY)
	IF(${BUILD_OPTION})
		ADD_SUBDIRECTORY(${BUILD_DIRECTORY})
	ENDIF(${BUILD_OPTION})
ENDMACRO()

INCLUDE(K3DParseArguments)

FUNCTION(K3D_CHECK CONFIG)
	K3D_PARSE_ARGUMENTS(BUILD "REQUIRES;RESOURCE;URL;MESSAGE" "" ${ARGN})

	IF(CONFIG STREQUAL "K-3D" OR ${CONFIG})
		FOREACH(REQUIREMENT ${BUILD_REQUIRES})
			IF(NOT ${REQUIREMENT})
				IF(BUILD_RESOURCE AND BUILD_URL)
					MESSAGE(SEND_ERROR "${CONFIG} requires ${BUILD_RESOURCE}, which can be obtained from ${BUILD_URL}. ${BUILD_MESSAGE}")
				ELSEIF(BUILD_RESOURCE)
					MESSAGE(SEND_ERROR "${CONFIG} requires ${BUILD_RESOURCE}. ${BUILD_MESSAGE}")
				ELSE()
					MESSAGE(SEND_ERROR "${CONFIG} requires ${REQUIREMENT}. ${BUILD_MESSAGE}")
				ENDIF()
			ENDIF()
		ENDFOREACH()
	ENDIF()
ENDFUNCTION()

FUNCTION(K3D_ADD_CUSTOM_TARGET TARGET_NAME)
	K3D_PARSE_ARGUMENTS(TARGET "REQUIRES;COMMAND" "" ${ARGN})

	FOREACH(REQUIREMENT ${TARGET_REQUIRES})
		IF(NOT ${REQUIREMENT})
			RETURN()
		ENDIF()
	ENDFOREACH()

	ADD_CUSTOM_TARGET(${TARGET_NAME} COMMAND ${TARGET_COMMAND})
ENDFUNCTION()

