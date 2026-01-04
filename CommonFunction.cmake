include_guard()

function(setup_target_compile_options)
    # 1. 定义参数类型
    set(options IWYU_FLAG)
    set(oneValueArgs TARGET_NAME ASAN EXCEPTIONS RTTI)
    #set(multiValueArgs OTHER_OPTIONS)

     # 2. 解析参数
    cmake_parse_arguments(
        USE          
        "${options}"      
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    if(USE_IWYU_FLAG)
        message("IWYU_FLAG is set")
    endif()

    if(USE_TARGET_NAME)
        message(STATUS "TARGET_NAME: ${USE_TARGET_NAME}")
    else()
        message(FATAL_ERROR "The TARGET_NAME parameter must be provided")
    endif()

    if (MSVC)
        if (USE_EXCEPTIONS)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "/EHsc")
        endif ()
        if (USE_RTTI)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "/GR-")
        endif ()

        if (USE_ASAN)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "/fsanitize=address" "/Zi")
            target_compile_definitions(${USE_TARGET_NAME} PRIVATE "_DISABLE_VECTOR_ANNOTATION")
        endif ()
    elseif (CMAKE_CXX_COMPILER_ID MATCHES "(GNU|Clang)")
        if (USE_EXCEPTIONS)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "-fno-exceptions")
        endif ()
        if (USE_RTTI)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "-fno-rtti")
        endif ()
        if (USE_ASAN)
            target_compile_options(${USE_TARGET_NAME} PRIVATE "-fsanitize=address")
            target_link_options(${USE_TARGET_NAME} PRIVATE "-fsanitize=address")
        endif ()
    endif ()

    find_program(iwyu_path NAMES include-what-you-use iwyu)
    if (iwyu_path)
        message("Found include-what-you-use: ${iwyu_path}")
    endif ()

    if (USE_IWYU_FLAG AND iwyu_path)
        set_property(TARGET ${USE_TARGET_NAME} PROPERTY CXX_INCLUDE_WHAT_YOU_USE ${iwyu_path})
    endif ()
endfunction()

function(organize_targets_in_rec FOLDER_NAME DIR)
    get_property(TARGETS DIRECTORY ${DIR} PROPERTY BUILDSYSTEM_TARGETS)
    foreach(CUR_TARGET IN LISTS TARGETS)
        message(STATUS "Found target: ${TARGET}")

        get_target_property(CUR_FOLDER ${CUR_TARGET} FOLDER)
        if (${CUR_FOLDER} STREQUAL "CUR_FOLDER-NOTFOUND")
        set(NEW_FOLDER ${FOLDER_NAME})
        else ()
        set(NEW_FOLDER "${FOLDER_NAME}/${CUR_FOLDER}")
        endif ()
        set_target_properties(${CUR_TARGET} PROPERTIES FOLDER ${NEW_FOLDER})
    endforeach()
    get_property(SUBDIRS DIRECTORY ${DIR} PROPERTY SUBDIRECTORIES)
    foreach(SUBDIR IN LISTS SUBDIRS)
        organize_targets_in_rec(${FOLDER_NAME} ${SUBDIR})
    endforeach()
endfunction()

function(organize_targets_in FOLDER_NAME)
    message("FOLDER_NAME:${FOLDER_NAME} CMAKE_CURRENT_SOURCE_DIR:${CMAKE_CURRENT_SOURCE_DIR}")
    organize_targets_in_rec(${FOLDER_NAME} ${CMAKE_CURRENT_SOURCE_DIR})
endfunction()


function(retrieve_files out_files)
    set(source_list)
    foreach(dirname ${ARGN})
        file(GLOB_RECURSE files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
			"${dirname}/*.cmake"
            "${dirname}/*.h"
            "${dirname}/*.hpp"
            "${dirname}/*.c"
            "${dirname}/*.cpp"
            "${dirname}/*.cc"            
        )
        foreach(filename ${files})
            list(APPEND source_list "${CMAKE_CURRENT_SOURCE_DIR}/${filename}")
			set(file_abs_path "${CMAKE_CURRENT_SOURCE_DIR}/${filename}")
			get_filename_component(source_path "${filename}" PATH)
            string(REPLACE "/" "\\" filter_dir "${source_path}")
            source_group("${filter_dir}" FILES "${filename}")
        endforeach()
    endforeach()
    set(${out_files} ${source_list} PARENT_SCOPE)
endfunction()

function(assign_source_group)
    if(MSVC)
		foreach(_source IN ITEMS ${ARGN})
			if (IS_ABSOLUTE "${_source}")
				file(RELATIVE_PATH _source_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${_source}")
			else()
				set(_source_rel "${_source}")
			endif()
			get_filename_component(_source_path "${_source_rel}" PATH)
			string(REPLACE "/" "\\" _source_path_msvc "${_source_path}")
			source_group("${_source_path_msvc}" FILES "${_source}")
		endforeach()
	endif(MSVC)
endfunction(assign_source_group)