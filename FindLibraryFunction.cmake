include_guard()

# # 查找符合特定模式的库
# file(GLOB gRPC_LIB_FILES "${CMAKE_HOME_DIRECTORY}/../../Dependencies/grpc/v1.51.3/lib/Windows/${build_type}/*.lib")
# set(REQUIRED_gRPC_LIBS gpr grpc grpc++ upb)
# set(FOUND_LIBS "")

# foreach(REQUIRED_gRPC_LIB ${REQUIRED_gRPC_LIBS})
#     set(FOUND FALSE)
    
#     # 查找特定库
#     foreach(gRPC_LIB_FILE ${gRPC_LIB_FILES})
#         get_filename_component(FILENAME ${gRPC_LIB_FILE} NAME_WE)
#         string(REGEX REPLACE "^lib" "" FILENAME ${FILENAME})
        
#         if(${FILENAME} STREQUAL ${REQUIRED_gRPC_LIB})
#             #message(STATUS "Found ${REQUIRED_gRPC_LIB}: ${gRPC_LIB_FILE}")
#             list(APPEND FOUND_LIBS ${gRPC_LIB_FILE})
#             set(FOUND TRUE)
#             break()
#         endif()
#     endforeach()
    
#     if(NOT FOUND)
#         message(WARNING "Required library ${REQUIRED_gRPC_LIBS} not found")
#     endif()
# endforeach()
# message(STATUS "FOUND_LIBS:${FOUND_LIBS}")

# 封装按照指定的库文件的find_library
function(find_library_path
    key_lib_name        # 关键库名称，用来确定搜索目录
    search_paths        # 搜索路径
    out_found           # 输出：是否找到
    out_path            # 输出：库路径
)
    set(FOUND FALSE)
    set(LIB_PATH "")

    foreach(SEARCH_PATH ${search_paths})
        # 查找库文件
        find_library(TEMP_LIB_PATH
            NAMES ${key_lib_name}
            PATHS ${SEARCH_PATH}
            NO_DEFAULT_PATH
            NO_CACHE
        )
        
        if(TEMP_LIB_PATH)

            get_filename_component(FILENAME ${TEMP_LIB_PATH} NAME_WE)
            string(REGEX REPLACE "^lib" "" FILENAME ${FILENAME})
        
            if(${FILENAME} STREQUAL ${key_lib_name})
                get_filename_component(LIB_PATH ${TEMP_LIB_PATH} DIRECTORY)
                message(STATUS "Found ${key_lib_name}: ${LIB_PATH}")
                set(FOUND TRUE)
                break()
            endif()
        endif()
    endforeach()

    # 返回多个值
    set(${out_found} ${FOUND} PARENT_SCOPE)
    set(${out_path} ${LIB_PATH} PARENT_SCOPE)
endfunction()

# 封装按照指定的库文件列表的find_library
function(find_specific_library
    key_lib_name        # 关键库名称，用来确定搜索目录
    search_paths        # 搜索路径
    required_libs       # 需要匹配的库列表
    out_found           # 输出：是否找到
    out_path            # 输出：库路径
    out_required_libs   # 返回匹配到的包含目录的库文件列表
)
    set(FOUND FALSE)
    set(LIB_PATH "")
    set(FOUND_LIBS "")

    foreach(SEARCH_PATH ${search_paths})
        # 查找库文件
        find_library(TEMP_LIB_PATH
            NAMES ${key_lib_name}
            PATHS ${SEARCH_PATH}
            NO_DEFAULT_PATH
            NO_CACHE
        )

        if(TEMP_LIB_PATH)

            get_filename_component(FILENAME ${TEMP_LIB_PATH} NAME_WE)
            string(REGEX REPLACE "^lib" "" FILENAME ${FILENAME})
        
            if(${FILENAME} STREQUAL ${key_lib_name})
                get_filename_component(LIB_PATH ${TEMP_LIB_PATH} DIRECTORY)
                message(STATUS "Found ${key_lib_name}: ${LIB_PATH}")
                set(FOUND TRUE)
                break()
            endif()
        endif()
    endforeach()
    
    message(STATUS "search_paths value ${search_paths}")
    message(STATUS "required_libs value ${required_libs}")

    message(STATUS "FOUND value ${FOUND}")
    message(STATUS "LIB_PATH value ${LIB_PATH}")

    # 找到主库目录
    if(FOUND)
        # 查找符合特定模式的库
        file(GLOB LIB_FILES "${LIB_PATH}/*.lib")

        #string(LENGTH "${required_libs}" length)
        #if(length EQUAL 0)
        if(required_libs)
            foreach(REQUIRED_LIB ${required_libs})
                set(FOUND FALSE)
                #message(STATUS "REQUIRED_LIB value ${REQUIRED_LIB}")
                # 查找特定库
                foreach(LIB_FILE ${LIB_FILES})
                    get_filename_component(FILENAME ${LIB_FILE} NAME_WE)
                    string(REGEX REPLACE "^lib" "" FILENAME ${FILENAME})
                    
                    if(${FILENAME} STREQUAL ${REQUIRED_LIB})
                        #message(STATUS "Found Required Lib:${$REQUIRED_LIB}<->${LIB_PATH}:${FILENAME}")
                        list(APPEND FOUND_LIBS ${LIB_FILE})
                        set(FOUND TRUE)
                        break()
                    endif()
                endforeach()
                
                if(NOT FOUND)
                    message(WARNING "Required library ${REQUIRED_LIB} not found")
                endif()
            endforeach()
        else()
            foreach(LIB_FILE ${LIB_FILES})
                #get_filename_component(FILENAME ${LIB_FILE} NAME_WE)
                #string(REGEX REPLACE "^lib" "" FILENAME ${FILENAME})
                #message(STATUS "Found ${FILENAME}: ${LIB_PATH}")
                list(APPEND FOUND_LIBS ${LIB_FILE})
                set(FOUND TRUE)
            endforeach()
        endif()
     endif()

    # 返回多个值
    set(${out_found} ${FOUND} PARENT_SCOPE)
    set(${out_path} ${LIB_PATH} PARENT_SCOPE)
    set(${out_required_libs} ${FOUND_LIBS} PARENT_SCOPE)
endfunction()

# 根据传入的库列表导入到指定的别名空间
function(add_alias_space
    header_path             # 头文件目录
    libs_path
    version_number
    libs_list               # 库文件列表
    key_name                # 关键字，例如 absl_
    replace_key_name        # 替换的关键字，例如 absl
)
    if(libs_list)

        foreach(LIB_FILE ${libs_list})
           # message(STATUS "LIB_FILE value ${LIB_FILE}")

            get_filename_component(FILENAME ${LIB_FILE} NAME)
            get_filename_component(FILENAME1 ${LIB_FILE} NAME_WE)
            string(REGEX REPLACE "^lib" "" FILENAME1 ${FILENAME1})
            
           message(STATUS "Found FILENAME:${FILENAME} FILENAME1:${FILENAME1}")
            string(REPLACE "${key_name}" "" NEW_STRING "${FILENAME1}")
           message(STATUS "NEW_STRING:${NEW_STRING}")
           # message(STATUS "alias:${replace_key_name}::${NEW_STRING}")
            
            import_static_library(${FILENAME}
                ALIAS_NAME ${NEW_STRING}
                LIBRARY_PATH "${libs_path}"
                INCLUDE_PATH "${header_path}"
                NAMESPACE ${replace_key_name}
                VERSION "${version_number}"
            )

        endforeach()
    endif()

endfunction()

# 定义一个递归函数，用于收集一个目录及其所有子目录中的 BUILDSYSTEM_TARGETS
function(get_all_targets_recursive root_dir output_list_var)

    if(NOT IS_DIRECTORY "${root_dir}")
        return()
    endif()

    message("--- root_dir:${root_dir}")
    #1. 获取当前目录的目标
    # #检查目录是否已被 CMake 处理 检查目录是否在 CMake 已知的目录列表中
     get_property(known_directories  GLOBAL PROPERTY DIRECTORY_STACK)
     message("--- known_directories:${known_directories}")

    # set(dir_found FALSE)

    # foreach(known_dir IN LISTS known_directories)
    #     get_filename_component(abs_known "${known_dir}" ABSOLUTE)
    #     if("${abs_known}" STREQUAL "${root_dir}")
    #         set(dir_found TRUE)
    #         break()
    #     endif()
    # endforeach()

    # if(NOT dir_found)
    #     message(STATUS "safe_get_directory_property: Directory '${root_dir}' not processed by CMake yet")
    #    # set(${result_var} "" PARENT_SCOPE)
    #     return()
    # endif()

    get_property(TARGETS_IN_DIR DIRECTORY ${root_dir} PROPERTY BUILDSYSTEM_TARGETS)

    message("--- BUILDSYSTEM_TARGETS:${BUILDSYSTEM_TARGETS}")
    message("--- TARGETS_IN_DIR:${TARGETS_IN_DIR}")
    # 将获取到的目标追加到传递进来的列表变量中
    list(APPEND ${output_list_var} ${TARGETS_IN_DIR})

    # 2. 获取当前目录的所有子目录
    set(filtered_cmake_subdirs)

    ## add_subdirectory 的目录不考虑
    #get_property(SUBDIRS DIRECTORY ${root_dir} PROPERTY SUBDIRECTORIES)
    # if(SUBDIRS)
    #     foreach(subdir IN LISTS SUBDIRS)
    #         get_filename_component(abs_subdir "${subdir}" ABSOLUTE BASE_DIR "${root_dir}")
            
    #         # 检查是否在项目源目录下
    #         file(RELATIVE_PATH rel_path "${CMAKE_SOURCE_DIR}" "${abs_subdir}")
    #         if(NOT rel_path MATCHES "^\\.\\.")
    #             list(APPEND filtered_cmake_subdirs "${subdir}")
    #         endif()
    #     endforeach()
    # endif()

    file(GLOB SUBDIRS RELATIVE "${root_dir}" "${root_dir}/*")
    foreach(dir IN LISTS SUBDIRS)
        if(IS_DIRECTORY "${root_dir}/${dir}")
        #if(EXISTS  "${root_dir}/${specified_sub_dir}")
            # 检查是否已经在CMake子目录列表中
            set(found FALSE)
            foreach(cmakedir IN LISTS filtered_cmake_subdirs)
                get_filename_component(abs_cmakedir "${cmakedir}" ABSOLUTE BASE_DIR "${root_dir}")
                if("${abs_cmakedir}" STREQUAL "${root_dir}/${dir}")
                    set(found TRUE)
                    break()
                endif()
            endforeach()
            
            if(NOT found)
                list(APPEND filtered_cmake_subdirs "${dir}")
            endif()
        endif()
    endforeach()

    message("--- filtered_cmake_subdirs:${filtered_cmake_subdirs}")

    # 3. 遍历子目录并递归调用
    foreach(SUBDIR IN LISTS SUBDIRS)
        # 完整的子目录路径
        set(FULL_SUBDIR_PATH "${root_dir}/${SUBDIR}")
        message("--- FULL_SUBDIR_PATH:${FULL_SUBDIR_PATH}")

        # 递归调用。注意：必须在 parent scope 中设置 output_list_var
        get_all_targets_recursive(${FULL_SUBDIR_PATH} ${output_list_var})
    endforeach()
    
    # 将最终的列表设置回父作用域，否则函数退出后列表会丢失
    set(${output_list_var} ${${output_list_var}} PARENT_SCOPE)

endfunction()

function(discover_targets package_name result_var)
    if(NOT DEFINED package_name)
        set(${result_var} "" PARENT_SCOPE)
        return()
    endif()

    FetchContent_GetProperties(${package_name})

    if(NOT ${package_name}_POPULATED)
        set(${result_var} "" PARENT_SCOPE)
        return()
    endif()

    set(discovered_targets)

    # 策略1：检查常见的命名模式
    set(name_patterns
        "${package_name}"                    # gtest
        "${package_name}::${package_name}"   # gtest::gtest
        "${package_name}::${package_name}-static"
        "${package_name}::${package_name}-shared"
        "${package_name}_static"
        "${package_name}_shared"
        "${package_name}::all"
        "${package_name}::${package_name}_static"
        "${package_name}::${package_name}_shared"
    )

    # 添加大小写变体
    string(TOUPPER "${package_name}" package_upper)
    string(TOLOWER "${package_name}" package_lower)

    list(APPEND name_patterns
        "${package_upper}"
        "${package_lower}"
        "${package_upper}::${package_upper}"
        "${package_lower}::${package_lower}"
    )

    foreach(pattern IN LISTS name_patterns)
        if(TARGET ${pattern})
            list(APPEND discovered_targets ${pattern})
        endif()
    endforeach()

    # 策略2：扫描包目录中的所有目标
    get_property(package_targets DIRECTORY ${${package_name}_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)
    if(package_targets)
        foreach(target IN LISTS package_targets)
            # 过滤掉内部目标
            if(NOT target MATCHES "^_" AND  # 不以_开头
            NOT target MATCHES "test|example|demo|benchmark" AND
            NOT target MATCHES ".*_test$|.*_example$|.*_demo$")
                list(APPEND discovered_targets ${target})
            endif()
        endforeach()
    endif()

    # 策略3：检查导入的目标
    get_property(imported_targets GLOBAL PROPERTY IMPORTED_TARGETS)
    if(imported_targets)
        foreach(target IN LISTS imported_targets)
            if(target MATCHES "${package_name}")
                list(APPEND discovered_targets ${target})
            endif()
        endforeach()
    endif()

    # 去重和排序
    if(discovered_targets)
        list(REMOVE_DUPLICATES discovered_targets)
        list(SORT discovered_targets)
    endif()

    set(${result_var} "${discovered_targets}" PARENT_SCOPE)

endfunction()

function(_get_dependencies_recursive target deps_var visited_var)
    if(target IN_LIST ${visited_var})
        return()
    endif()

    list(APPEND ${visited_var} ${target})

    # 获取目标的链接库
    get_target_property(link_libs ${target} LINK_LIBRARIES)
    get_target_property(interface_libs ${target} INTERFACE_LINK_LIBRARIES)

    set(all_libs)
    if(link_libs)
        list(APPEND all_libs ${link_libs})
    endif()
    if(interface_libs)
        list(APPEND all_libs ${interface_libs})
    endif()

    foreach(lib IN LISTS all_libs)
        if(TARGET ${lib})
            # 添加到依赖列表
            if(NOT lib IN_LIST ${deps_var})
                list(APPEND ${deps_var} ${lib})
            endif()
            
            # 递归处理
            _get_dependencies_recursive("${lib}" ${deps_var} ${visited_var})
        endif()
    endforeach()

    set(${deps_var} "${${deps_var}}" PARENT_SCOPE)
    set(${visited_var} "${${visited_var}}" PARENT_SCOPE)
endfunction()

function(is_thirdparty_library target_name result_var)
    if(NOT TARGET ${target_name})
        set(${result_var} FALSE PARENT_SCOPE)
        return()
    endif()

    set(is_thirdparty FALSE)

    # 方法1：检查目标属性
    get_target_property(imported ${target_name} IMPORTED)
    if(imported)
        set(is_thirdparty TRUE)
    endif()

    # # 方法2：检查目标位置
    # get_target_property(location ${target_name} LOCATION)
    # if(location)
    #     # 检查是否在第三方库目录中
    #     if(location MATCHES ".*(googletest|fmt|spdlog|gtest|gmock|catch2|benchmark).*" OR
    #     location MATCHES ".*(thirdparty|third_party|external|deps).*")
    #         set(is_thirdparty TRUE)
    #     endif()
    # endif()

    # # 方法3：检查目标名称模式
    # if(target_name MATCHES ".*::.*" OR  # 命名空间目标
    # target_name MATCHES ".*thirdparty.*" OR
    # target_name MATCHES ".*external.*" OR
    # target_name MATCHES ".*deps.*")
    #     set(is_thirdparty TRUE)
    # endif()

    # # 方法4：检查是否是已知的第三方库
    # set(known_thirdparty_libs
    #     "gtest" "gtest_main" "gmock" "gmock_main"
    #     "fmt" "fmt::fmt" "spdlog" "spdlog::spdlog"
    #     "benchmark" "benchmark::benchmark"
    #     "catch2" "catch2::catch2"
    # )

    # if(target_name IN_LIST known_thirdparty_libs)
    #     set(is_thirdparty TRUE)
    # endif()

    message(STATUS "${target_name} is_thirdparty ${is_thirdparty}")
    set(${result_var} ${is_thirdparty} PARENT_SCOPE)
endfunction()

function(is_alias_target target_name result_var)
    # if(NOT TARGET ${target_name})
    #     set(${result_var} FALSE PARENT_SCOPE)
    #     return()
    # endif()

    get_target_property(aliased_target  ${target_name} ALIASED_TARGET)
    get_target_property(target_type ${target_name} TYPE)
    get_target_property(imported ${target_name} IMPORTED)

    #message(STATUS "is_alias_target ${target_name} aliased_target  ${aliased_target}")

    if(NOT "${aliased_target}" STREQUAL "aliased_target-NOTFOUND")
        set(${result_var} TRUE PARENT_SCOPE)
    else()
        set(${result_var} FALSE PARENT_SCOPE)
    endif()
endfunction()


function(get_alias_original_target alias_target result_var)
    if(NOT TARGET ${alias_target})
        set(${result_var} "" PARENT_SCOPE)
        return()
    endif()

    # 检查是否是 ALIAS
    is_alias_target(${alias_target} is_alias)
    #message(STATUS "alias_target ${alias_target} is_alias ${is_alias}")

    if(NOT is_alias)
        set(${result_var} ${alias_target} PARENT_SCOPE)  # 不是别名，返回自身
        return()
    endif()

    # 方法1：使用 ALIASED_TARGET 属性（CMake 3.11+）
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.11)
        get_target_property(original_target ${alias_target} ALIASED_TARGET)
        if(original_target)
            set(${result_var} ${original_target} PARENT_SCOPE)
            return()
        endif()
    endif()

    # # 方法2：尝试从已知的别名映射中查找
    # # 注意：这需要您在创建别名时记录映射关系
    # if(DEFINED ALIAS_TARGET_MAP_${alias_target})
    #     set(${result_var} ${ALIAS_TARGET_MAP_${alias_target}} PARENT_SCOPE)
    #     return()
    # endif()

    # # 方法3：在全局属性中查找
    # get_property(all_aliases GLOBAL PROPERTY ALIAS_TARGETS)
    # if(all_aliases)
    #     foreach(alias_entry IN LISTS all_aliases)
    #         if(alias_entry MATCHES "(.+)::(.+)")
    #             set(alias_name "${CMAKE_MATCH_1}")
    #             set(original_name "${CMAKE_MATCH_2}")
    #             if(alias_name STREQUAL alias_target)
    #                 set(${result_var} ${original_name} PARENT_SCOPE)
    #                 return()
    #             endif()
    #         endif()
    #     endforeach()
    # endif()

    set(${result_var} "" PARENT_SCOPE)
endfunction()

function(get_thirdparty_dependencies target_name result_var)
    if(NOT TARGET ${target_name})
        set(${result_var} "" PARENT_SCOPE)
        return()
    endif()
    set(dependencies)
    set(visited)

    _get_dependencies_recursive("${target_name}" dependencies visited)

    # # 过滤掉系统库和非第三方库
    # set(filtered_deps)
    # foreach(dep IN LISTS dependencies)
    #     # 检查是否是第三方库（通过命名模式或路径）
    #     is_thirdparty_library(${dep} is_thirdparty)
    #     if(is_thirdparty)
    #         list(APPEND filtered_deps ${dep})
    #     endif()
    # endforeach()

    set(filtered_deps ${dependencies})
    if(filtered_deps)
        list(REMOVE_DUPLICATES filtered_deps)
    endif()

    # 检查是否是 ALIAS
    foreach(dep IN LISTS filtered_deps)
    
        is_alias_target(${dep} is_alias)
         message(STATUS "dep ${dep} is_alias ${is_alias}")

        if(is_alias)
            # 获取原始目标
            get_alias_original_target(${dep} original_target)
            message(STATUS "Alias ${dep}: ${original_target}")

            list(TRANSFORM filtered_deps REPLACE ${dep} ${original_target})
        endif()
    endforeach()

    set(${result_var} "${filtered_deps}" PARENT_SCOPE)
endfunction()

function(wait_for_fetchcontent content_name max_attempts)
    set(attempt 1)

    while(attempt LESS max_attempts)
        FetchContent_GetProperties(${content_name})
        
        if(${content_name}_POPULATED)
            message(STATUS "${content_name} populated successfully (attempt ${attempt})")
            return(TRUE)
        endif()
        
        message(STATUS "Waiting for ${content_name}... (attempt ${attempt}/${max_attempts})")
        
        # 短暂延迟
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1)
        
        math(EXPR attempt "${attempt} + 1")
    endwhile()

    #message(FATAL_ERROR "Failed to populate ${content_name} after ${max_attempts} attempts")
endfunction()