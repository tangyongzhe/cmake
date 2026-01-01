# ThirdPartyStaticManager.cmake - 第三方静态库别名管理器（修复版）
include_guard()

# 全局注册表
set_property(GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS "")
set_property(GLOBAL PROPERTY THIRDPARTY_STATIC_GROUPS "")

# 1. 导入静态库函数
function(import_static_library lib_name)
    set(options)
    set(one_value_args
        ALIAS_NAME
        LIBRARY_PATH
        INCLUDE_PATH
        NAMESPACE
        VERSION
    )
    set(multi_value_args
        DEFINES
        COMPILE_OPTIONS
        LINK_OPTIONS
        DEPENDENCIES
    )
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    # 设置命名空间
    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE "MyProject_ThirdParty")
    endif()
    
    if(NOT ARG_ALIAS_NAME)
        set(ARG_ALIAS_NAME "${lib_name}")
    endif()
    # 验证库文件
    if(NOT ARG_LIBRARY_PATH)
        message(WARNING "No library path specified for ${lib_name}")
        return()
    endif()
    
    if(NOT EXISTS "${ARG_LIBRARY_PATH}")
        message(WARNING "Static library not found: ${ARG_LIBRARY_PATH}")
        return()
    endif()
    
    # 创建目标名（避免使用::）
    set(target_name "${ARG_NAMESPACE}::${ARG_ALIAS_NAME}")
    message(STATUS "target_name: ${target_name}")

    # 检查目标是否已存在
    if(TARGET ${target_name})
        message(STATUS "  ⓘ Target already exists: ${target_name}")
        return()
    endif()
    
    # 创建导入目标
    add_library(${target_name} STATIC IMPORTED GLOBAL)
    
    # 设置位置
    set_target_properties(${target_name} PROPERTIES
        IMPORTED_LOCATION "${ARG_LIBRARY_PATH}/${lib_name}"
    )
    
    set_target_properties(${target_name} PROPERTIES
        INTERFACE_LINK_OPTIONS "${ARG_LIBRARY_PATH}/${lib_name}"
    )

    # 设置包含目录
    if(ARG_INCLUDE_PATH)
        set_target_properties(${target_name} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ARG_INCLUDE_PATH}"
        )
    endif()
    
    # 设置编译定义
    if(ARG_DEFINES)
        target_compile_definitions(${target_name} INTERFACE ${ARG_DEFINES})
    endif()
    
    # 设置编译选项
    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${target_name} INTERFACE ${ARG_COMPILE_OPTIONS})
    endif()
    
    # 设置链接选项
    if(ARG_LINK_OPTIONS)
        target_link_options(${target_name} INTERFACE ${ARG_LINK_OPTIONS})
    endif()
    
    # 设置依赖
    if(ARG_DEPENDENCIES)
        target_link_libraries(${target_name} INTERFACE ${ARG_DEPENDENCIES})
    endif()
    
    # 设置版本
    if(ARG_VERSION)
        set_target_properties(${target_name} PROPERTIES
            VERSION "${ARG_VERSION}"
        )
    endif()
    
    # 创建可读性更好的别名（使用下划线分隔）
    add_library(${ARG_NAMESPACE}::${lib_name} ALIAS ${target_name})
    
    # 注册到全局
    set_property(GLOBAL APPEND PROPERTY THIRDPARTY_STATIC_LIBS
        "${target_name}"
    )
    
    message(STATUS "  ✓ Imported static library: ${target_name}")
    message(STATUS "    ├─ Library: ${ARG_LIBRARY_PATH}/${lib_name}")
    if(ARG_INCLUDE_PATH)
        message(STATUS "    ├─ Includes: ${ARG_INCLUDE_PATH}")
    endif()
    if(ARG_VERSION)
        message(STATUS "    └─ Version: ${ARG_VERSION}")
    endif()
endfunction()

# 2. 批量导入函数
function(import_static_libraries)
    foreach(lib_config ${ARGN})
        # 解析配置: "lib_name;LIBRARY_PATH=/path;INCLUDE_PATH=/path"
        string(REPLACE ";" " " lib_config_spaced "${lib_config}")
        string(REPLACE "=" ":" lib_config_final "${lib_config_spaced}")
        
        # 提取库名
        list(GET lib_config_final 0 lib_name)
        
        # 构建参数列表
        set(lib_args)
        foreach(arg ${lib_config_final})
            if(arg MATCHES ":")
                list(APPEND lib_args ${arg})
            endif()
        endforeach()
        
        # 调用导入函数
        import_static_library(${lib_name} ${lib_args})
    endforeach()
endfunction()

# 3. 创建静态库组
function(create_static_library_group group_name)
    set(options)
    set(one_value_args NAMESPACE)
    set(multi_value_args LIBRARIES DEFINES COMPILE_OPTIONS)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE "MyProject_ThirdParty")
    endif()
    
    # 创建目标名（避免使用::）
    set(target_name "${ARG_NAMESPACE}_Group_${group_name}")
    
    # 检查目标是否已存在
    if(TARGET ${target_name})
        message(WARNING "Target ${target_name} already exists")
        return()
    endif()
    
    # 创建接口库
    add_library(${target_name} INTERFACE)
    
    # 链接库成员
    if(ARG_LIBRARIES)
        message(STATUS "Creating group ${target_name} with libraries:")
        foreach(lib ${ARG_LIBRARIES})
            if(TARGET ${lib})
                message(STATUS "  ✓ Adding library: ${lib}")
                target_link_libraries(${target_name} INTERFACE ${lib})
            else()
                message(STATUS "  ✗ Library not found: ${lib}")
                message(WARNING "Target ${lib} not found for group ${group_name}")
            endif()
        endforeach()
    endif()
    
    # 设置编译定义
    if(ARG_DEFINES)
        target_compile_definitions(${target_name} INTERFACE ${ARG_DEFINES})
    endif()
    
    # 设置编译选项
    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${target_name} INTERFACE ${ARG_COMPILE_OPTIONS})
    endif()
    
    # 注册到全局
    set_property(GLOBAL APPEND PROPERTY THIRDPARTY_STATIC_GROUPS
        "${target_name}"
    )
    
    message(STATUS "  ✓ Created static library group: ${target_name}")
endfunction()

# 3. 查找系统静态库
function(find_system_static_library lib_name)
    set(options REQUIRED)
    set(one_value_args NAMESPACE ALIAS)
    set(multi_value_args LIB_NAMES SEARCH_PATHS)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE "MyProject_ThirdParty_System")
    endif()
    
    if(NOT ARG_ALIAS)
        set(ARG_ALIAS ${lib_name})
    endif()
    
    # 默认库名
    if(NOT ARG_LIB_NAMES)
        if(WIN32)
            set(ARG_LIB_NAMES "${lib_name}.lib" "lib${lib_name}.lib")
        else()
            set(ARG_LIB_NAMES "lib${lib_name}.a" "${lib_name}.a")
        endif()
    endif()
    
    # 查找库
    find_library(${lib_name}_LIBRARY
        NAMES ${ARG_LIB_NAMES}
        PATHS ${ARG_SEARCH_PATHS}
        PATH_SUFFIXES lib lib64
    )
    
    if(${lib_name}_LIBRARY)
        # 创建目标名
        set(target_name "${ARG_NAMESPACE}_${ARG_ALIAS}")
        
        # 创建导入目标
        add_library(${target_name} INTERFACE IMPORTED)
        
        # 链接库
        target_link_libraries(${target_name} INTERFACE ${${lib_name}_LIBRARY})
        
        message(STATUS "  ✓ Found system static library: ${target_name}")
    elseif(ARG_REQUIRED)
        message(FATAL_ERROR "Required system library ${lib_name} not found")
    endif()
endfunction()

# 5. 打印摘要
function(print_static_library_summary)
    message(STATUS "")
    message(STATUS "=" * 50)
    message(STATUS "第三方静态库配置摘要")
    message(STATUS "=" * 50)
    
    get_property(static_libs GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    get_property(static_groups GLOBAL PROPERTY THIRDPARTY_STATIC_GROUPS)
    
    # 统计库
    list(LENGTH static_libs lib_count)
    list(LENGTH static_groups group_count)
    
    message(STATUS "静态库数量: ${lib_count}")
    message(STATUS "库组数量: ${group_count}")
    
    if(static_libs)
        message(STATUS "")
        message(STATUS "导入的静态库:")
        foreach(lib ${static_libs})
            if(TARGET ${lib})
                get_target_property(lib_path ${lib} IMPORTED_LOCATION)
                get_target_property(lib_version ${lib} VERSION)
                
                if(lib_path)
                    get_filename_component(lib_name ${lib_path} NAME)
                    message(STATUS "  • ${lib}")
                    message(STATUS "    文件: ${lib_name}")
                    
                    if(lib_version)
                        message(STATUS "    版本: ${lib_version}")
                    endif()
                    
                    # 获取依赖
                    get_target_property(deps ${lib} INTERFACE_LINK_LIBRARIES)
                    if(deps)
                        message(STATUS "    依赖: ${deps}")
                    endif()
                endif()
            endif()
        endforeach()
    endif()
    
    if(static_groups)
        message(STATUS "")
        message(STATUS "静态库组:")
        foreach(group ${static_groups})
            if(TARGET ${group})
                message(STATUS "  • ${group}")
                
                get_target_property(libs ${group} INTERFACE_LINK_LIBRARIES)
                if(libs)
                    message(STATUS "    成员: ${libs}")
                else()
                    message(STATUS "    成员: 无")
                endif()
            endif()
        endforeach()
    endif()
    
    # 平台信息
    message(STATUS "")
    message(STATUS "平台信息:")
    message(STATUS "  系统: ${CMAKE_SYSTEM_NAME}")
    message(STATUS "  处理器: ${CMAKE_SYSTEM_PROCESSOR}")
    message(STATUS "  C++编译器: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    
    # 静态链接检查
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(STATUS "")
        message(STATUS "静态链接检查:")
        
        # 检查libstdc++静态库
        execute_process(
            COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=libstdc++.a
            OUTPUT_VARIABLE stdcxx_static
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        
        if(EXISTS "${stdcxx_static}")
            message(STATUS "  ✓ libstdc++.a: 可用 (${stdcxx_static})")
        else()
            message(STATUS "  ✗ libstdc++.a: 不可用")
        endif()
        
        # 检查libgcc静态库
        execute_process(
            COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=libgcc.a
            OUTPUT_VARIABLE gcc_static
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        
        if(EXISTS "${gcc_static}")
            message(STATUS "  ✓ libgcc.a: 可用 (${gcc_static})")
        else()
            message(STATUS "  ✗ libgcc.a: 不可用")
        endif()
    endif()
    
    message(STATUS "=" * 50)
endfunction()

# 6. 配置管理函数
function(configure_static_linking target)
    if(NOT TARGET ${target})
        return()
    endif()
    
    get_target_property(target_type ${target} TYPE)
    if(NOT target_type STREQUAL "EXECUTABLE")
        return()
    endif()
    
    message(STATUS "配置静态链接: ${target}")
    
    # 设置静态链接属性
    set_target_properties(${target} PROPERTIES
        LINK_SEARCH_START_STATIC 1
        LINK_SEARCH_END_STATIC 1
    )
    
    # 平台特定设置
    if(WIN32)
        # Windows静态链接选项
        target_link_options(${target} PRIVATE
            /NODEFAULTLIB:libcmt
            /NODEFAULTLIB:libcmtd
        )
        
    elseif(APPLE)
        # macOS静态链接选项
        target_link_options(${target} PRIVATE
            -static-libgcc
        )
        
    elseif(UNIX)
        # Linux静态链接选项
        target_link_options(${target} PRIVATE
            -static-libgcc
            -static-libstdc++
        )
        
        # 使用--whole-archive确保所有符号被链接
        get_target_property(link_libs ${target} LINK_LIBRARIES)
        if(link_libs)
            set(whole_archive_libs)
            foreach(lib ${link_libs})
                if(TARGET ${lib})
                    get_target_property(lib_type ${lib} TYPE)
                    if(lib_type STREQUAL "STATIC_LIBRARY")
                        get_target_property(lib_path ${lib} IMPORTED_LOCATION)
                        if(lib_path)
                            list(APPEND whole_archive_libs ${lib_path})
                        endif()
                    endif()
                endif()
            endforeach()
            
            if(whole_archive_libs)
                target_link_options(${target} PRIVATE
                    "-Wl,--whole-archive"
                    ${whole_archive_libs}
                    "-Wl,--no-whole-archive"
                )
            endif()
        endif()
    endif()
endfunction()

# 7. 获取单个第三方库的信息
function(get_thirdparty_library_info target_name)
    if(NOT TARGET ${target_name})
        message(WARNING "Target ${target_name} not found")
        return()
    endif()
    
    # 获取目标类型
    get_target_property(target_type ${target_name} TYPE)
    
    # 获取导入位置（库文件路径）
    get_target_property(imported_location ${target_name} IMPORTED_LOCATION)
    
    # 获取接口包含目录
    get_target_property(interface_includes ${target_name} INTERFACE_INCLUDE_DIRECTORIES)
    
    # 获取编译定义
    get_target_property(compile_definitions ${target_name} INTERFACE_COMPILE_DEFINITIONS)
    
    # 获取编译选项
    get_target_property(compile_options ${target_name} INTERFACE_COMPILE_OPTIONS)
    
    # 获取链接选项
    get_target_property(link_options ${target_name} INTERFACE_LINK_OPTIONS)
    
    # 获取版本
    get_target_property(version ${target_name} VERSION)
    
    # 获取链接库
    get_target_property(link_libraries ${target_name} INTERFACE_LINK_LIBRARIES)
    
    # 返回变量
    set(${ARGV1}_IMPORTED_LOCATION "${imported_location}" PARENT_SCOPE)
    set(${ARGV1}_INTERFACE_INCLUDES "${interface_includes}" PARENT_SCOPE)
    set(${ARGV1}_COMPILE_DEFINITIONS "${compile_definitions}" PARENT_SCOPE)
    set(${ARGV1}_COMPILE_OPTIONS "${compile_options}" PARENT_SCOPE)
    set(${ARGV1}_LINK_OPTIONS "${link_options}" PARENT_SCOPE)
    set(${ARGV1}_VERSION "${version}" PARENT_SCOPE)
    set(${ARGV1}_LINK_LIBRARIES "${link_libraries}" PARENT_SCOPE)
    set(${ARGV1}_TYPE "${target_type}" PARENT_SCOPE)
    
    # 打印信息
    message(STATUS "=== 库信息: ${target_name} ===")
    if(imported_location)
        message(STATUS "  库文件: ${imported_location}")
    endif()
    if(interface_includes)
        message(STATUS "  头文件目录: ${interface_includes}")
    endif()
    if(version)
        message(STATUS "  版本: ${version}")
    endif()
    message(STATUS "")
endfunction()

# 8. 批量获取所有第三方库信息
function(get_all_thirdparty_libraries_info)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        message(STATUS "没有找到第三方静态库")
        return()
    endif()
    
    message(STATUS "=== 所有第三方库信息 ===")
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_thirdparty_library_info(${target} ${target}_INFO)
        endif()
    endforeach()
endfunction()

# 9. 生成库配置文件
function(generate_library_config_file output_file)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        message(WARNING "没有第三方库可生成配置")
        return()
    endif()
    
    # 创建配置内容
    set(config_content "# Third-party library configuration\n")
    set(config_content "${config_content}# Generated by CMake on ${CMAKE_SYSTEM_NAME}\n")
    set(config_content "${config_content}# Timestamp: ${CMAKE_DATE} ${CMAKE_TIME}\n\n")
    
    set(config_content "${config_content}# Library paths\n")
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(lib_path ${target} IMPORTED_LOCATION)
            get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
            
            if(lib_path)
                # 获取库文件名和目录
                get_filename_component(lib_dir ${lib_path} DIRECTORY)
                get_filename_component(lib_name ${lib_path} NAME)
                
                set(config_content "${config_content}# ${target}\n")
                set(config_content "${config_content}set(${target}_LIBRARY \"${lib_path}\")\n")
                set(config_content "${config_content}set(${target}_LIBRARY_DIR \"${lib_dir}\")\n")
                set(config_content "${config_content}set(${target}_LIBRARY_NAME \"${lib_name}\")\n")
                
                if(inc_dirs)
                    set(config_content "${config_content}set(${target}_INCLUDE_DIRS \"${inc_dirs}\")\n")
                endif()
                
                get_target_property(version ${target} VERSION)
                if(version)
                    set(config_content "${config_content}set(${target}_VERSION \"${version}\")\n")
                endif()
                
                set(config_content "${config_content}\n")
            endif()
        endif()
    endforeach()
    
    # 写入文件
    file(WRITE ${output_file} "${config_content}")
    message(STATUS "生成库配置文件: ${output_file}")
endfunction()

# 10. 导出库路径到环境变量
function(export_library_paths_to_env)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        message(WARNING "没有第三方库可导出")
        return()
    endif()
    
    # 收集所有库目录
    set(lib_dirs)
    set(inc_dirs)
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(lib_path ${target} IMPORTED_LOCATION)
            get_target_property(inc_dirs_target ${target} INTERFACE_INCLUDE_DIRECTORIES)
            
            if(lib_path)
                get_filename_component(lib_dir ${lib_path} DIRECTORY)
                list(APPEND lib_dirs ${lib_dir})
            endif()
            
            if(inc_dirs_target)
                list(APPEND inc_dirs ${inc_dirs_target})
            endif()
        endif()
    endforeach()
    
    # 去重
    if(lib_dirs)
        list(REMOVE_DUPLICATES lib_dirs)
    endif()
    
    if(inc_dirs)
        list(REMOVE_DUPLICATES inc_dirs)
    endif()
    
    # 设置环境变量
    if(lib_dirs)
        set(ENV{THIRDPARTY_LIBRARY_DIRS} "${lib_dirs}")
        message(STATUS "设置环境变量 THIRDPARTY_LIBRARY_DIRS: ${lib_dirs}")
    endif()
    
    if(inc_dirs)
        set(ENV{THIRDPARTY_INCLUDE_DIRS} "${inc_dirs}")
        message(STATUS "设置环境变量 THIRDPARTY_INCLUDE_DIRS: ${inc_dirs}")
    endif()
endfunction()

# 11. 创建pkg-config文件
function(create_pkgconfig_file target_name output_dir)
    if(NOT TARGET ${target_name})
        message(WARNING "目标 ${target_name} 不存在")
        return()
    endif()
    
    get_target_property(lib_path ${target_name} IMPORTED_LOCATION)
    get_target_property(inc_dirs ${target_name} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(version ${target_name} VERSION)
    get_target_property(link_libs ${target_name} INTERFACE_LINK_LIBRARIES)
    
    if(NOT lib_path)
        message(WARNING "目标 ${target_name} 没有库路径")
        return()
    endif()
    
    # 提取库名
    get_filename_component(lib_name ${lib_path} NAME_WE)
    string(REGEX REPLACE "^lib" "" lib_name ${lib_name})
    
    if(NOT version)
        set(version "1.0.0")
    endif()
    
    # 创建pkg-config内容
    set(pc_content "# ${target_name} pkg-config file\n")
    set(pc_content "${pc_content}prefix=${CMAKE_INSTALL_PREFIX}\n")
    set(pc_content "${pc_content}exec_prefix=\${prefix}\n")
    set(pc_content "${pc_content}libdir=\${exec_prefix}/lib\n")
    set(pc_content "${pc_content}includedir=\${prefix}/include\n\n")
    
    set(pc_content "${pc_content}Name: ${lib_name}\n")
    set(pc_content "${pc_content}Description: ${target_name} static library\n")
    set(pc_content "${pc_content}Version: ${version}\n")
    
    # 库
    get_filename_component(lib_dir ${lib_path} DIRECTORY)
    get_filename_component(lib_file ${lib_path} NAME)
    set(pc_content "${pc_content}Libs: -L${lib_dir} -l${lib_name}\n")
    
    # 包含目录
    if(inc_dirs)
        set(pc_content "${pc_content}Cflags: -I${inc_dirs}\n")
    endif()
    
    # 依赖
    if(link_libs)
        set(pc_content "${pc_content}Requires: ${link_libs}\n")
    endif()
    
    # 写入文件
    set(pc_file "${output_dir}/${lib_name}.pc")
    file(WRITE ${pc_file} "${pc_content}")
    message(STATUS "生成pkg-config文件: ${pc_file}")
endfunction()

# 12. 生成库查找脚本
function(generate_find_script output_file)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        return()
    endif()
    
    set(script_content "#!/bin/bash\n")
    set(script_content "${script_content}# Third-party library finder script\n")
    set(script_content "${script_content}# Generated by CMake\n\n")
    
    set(script_content "${script_content}set -e\n\n")
    
    set(script_content "${script_content}echo \"=== Third-party Library Finder ===\"\n")
    set(script_content "${script_content}echo\n")
    
    # 定义查找函数
    set(script_content "${script_content}find_library() {\n")
    set(script_content "${script_content}    local lib_name=\$1\n")
    set(script_content "${script_content}    local search_dirs=\"\$2\"\n")
    set(script_content "${script_content}    \n")
    set(script_content "${script_content}    for dir in \$search_dirs; do\n")
    set(script_content "${script_content}        if [ -f \"\$dir/lib\${lib_name}.a\" ]; then\n")
    set(script_content "${script_content}            echo \"\$dir/lib\${lib_name}.a\"\n")
    set(script_content "${script_content}            return 0\n")
    set(script_content "${script_content}        elif [ -f \"\$dir/\${lib_name}.a\" ]; then\n")
    set(script_content "${script_content}            echo \"\$dir/\${lib_name}.a\"\n")
    set(script_content "${script_content}            return 0\n")
    set(script_content "${script_content}        fi\n")
    set(script_content "${script_content}    done\n")
    set(script_content "${script_content}    \n")
    set(script_content "${script_content}    return 1\n")
    set(script_content "${script_content}}\n\n")
    
    set(script_content "${script_content}find_include() {\n")
    set(script_content "${script_content}    local header_name=\$1\n")
    set(script_content "${script_content}    local search_dirs=\"\$2\"\n")
    set(script_content "${script_content}    \n")
    set(script_content "${script_content}    for dir in \$search_dirs; do\n")
    set(script_content "${script_content}        if [ -f \"\$dir/\${header_name}\" ]; then\n")
    set(script_content "${script_content}            echo \"\$dir\"\n")
    set(script_content "${script_content}            return 0\n")
    set(script_content "${script_content}        fi\n")
    set(script_content "${script_content}    done\n")
    set(script_content "${script_content}    \n")
    set(script_content "${script_content}    return 1\n")
    set(script_content "${script_content}}\n\n")
    
    # 收集所有库和包含目录
    set(all_lib_dirs)
    set(all_inc_dirs)
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(lib_path ${target} IMPORTED_LOCATION)
            get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
            
            if(lib_path)
                get_filename_component(lib_dir ${lib_path} DIRECTORY)
                list(APPEND all_lib_dirs ${lib_dir})
            endif()
            
            if(inc_dirs)
                list(APPEND all_inc_dirs ${inc_dirs})
            endif()
        endif()
    endforeach()
    
    # 去重
    if(all_lib_dirs)
        list(REMOVE_DUPLICATES all_lib_dirs)
    endif()
    
    if(all_inc_dirs)
        list(REMOVE_DUPLICATES all_inc_dirs)
    endif()
    
    # 生成搜索路径
    set(script_content "${script_content}# Library search directories\n")
    set(script_content "${script_content}LIB_DIRS=\"")
    foreach(dir ${all_lib_dirs})
        set(script_content "${script_content}${dir}:")
    endforeach()
    set(script_content "${script_content}\"\n\n")
    
    set(script_content "${script_content}# Include search directories\n")
    set(script_content "${script_content}INC_DIRS=\"")
    foreach(dir ${all_inc_dirs})
        set(script_content "${script_content}${dir}:")
    endforeach()
    set(script_content "${script_content}\"\n\n")
    
    # 生成查找命令
    set(script_content "${script_content}echo \"Library directories:\"\n")
    foreach(dir ${all_lib_dirs})
        set(script_content "${script_content}echo \"  \$LIB_DIRS\" | tr ':' '\\n'\n")
    endforeach()
    
    set(script_content "${script_content}echo\n")
    set(script_content "${script_content}echo \"Include directories:\"\n")
    foreach(dir ${all_inc_dirs})
        set(script_content "${script_content}echo \"  \$INC_DIRS\" | tr ':' '\\n'\n")
    endforeach()
    
    set(script_content "${script_content}echo\n")
    
    # 为每个库生成查找命令
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(lib_path ${target} IMPORTED_LOCATION)
            
            if(lib_path)
                get_filename_component(lib_name ${lib_path} NAME_WE)
                string(REGEX REPLACE "^lib" "" base_name ${lib_name})
                
                set(script_content "${script_content}echo \"Looking for ${base_name}...\"\n")
                set(script_content "${script_content}lib_path=\$(find_library \"${base_name}\" \"\$LIB_DIRS\")\n")
                set(script_content "${script_content}if [ -n \"\$lib_path\" ]; then\n")
                set(script_content "${script_content}    echo \"  Found: \$lib_path\"\n")
                set(script_content "${script_content}else\n")
                set(script_content "${script_content}    echo \"  Not found\"\n")
                set(script_content "${script_content}fi\n")
                set(script_content "${script_content}echo\n")
            endif()
        endif()
    endforeach()
    
    # 写入文件
    file(WRITE ${output_file} "${script_content}")
    execute_process(COMMAND chmod +x ${output_file})
    message(STATUS "生成库查找脚本: ${output_file}")
endfunction()

# 13. 生成CMake查找模块
function(generate_cmake_find_module output_dir)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        return()
    endif()
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(lib_path ${target} IMPORTED_LOCATION)
            get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
            get_target_property(version ${target} VERSION)
            
            if(lib_path)
                get_filename_component(lib_name ${lib_path} NAME_WE)
                string(REGEX REPLACE "^lib" "" module_name ${lib_name})
                string(TOUPPER ${module_name} module_upper)
                
                set(module_content "# Find${module_name}.cmake\n")
                set(module_content "${module_content}# Generated by CMake\n\n")
                
                set(module_content "${module_content}# Try to find ${module_name}\n")
                set(module_content "${module_content}# Once done, this will define\n")
                set(module_content "${module_content}#\n")
                set(module_content "${module_content}#  ${module_upper}_FOUND - system has ${module_name}\n")
                set(module_content "${module_content}#  ${module_upper}_INCLUDE_DIRS - the ${module_name} include directories\n")
                set(module_content "${module_content}#  ${module_upper}_LIBRARIES - link these to use ${module_name}\n")
                set(module_content "${module_content}#  ${module_upper}_VERSION - version of ${module_name}\n\n")
                
                set(module_content "${module_content}# Library path\n")
                set(module_content "${module_content}set(${module_upper}_LIBRARY \"${lib_path}\")\n")
                get_filename_component(lib_dir ${lib_path} DIRECTORY)
                set(module_content "${module_content}set(${module_upper}_LIBRARY_DIR \"${lib_dir}\")\n\n")
                
                set(module_content "${module_content}# Include directories\n")
                if(inc_dirs)
                    set(module_content "${module_content}set(${module_upper}_INCLUDE_DIRS \"${inc_dirs}\")\n")
                else()
                    set(module_content "${module_content}set(${module_upper}_INCLUDE_DIRS \"\")\n")
                endif()
                
                set(module_content "${module_content}# Version\n")
                if(version)
                    set(module_content "${module_content}set(${module_upper}_VERSION \"${version}\")\n")
                else()
                    set(module_content "${module_content}set(${module_upper}_VERSION \"\")\n")
                endif()
                
                set(module_content "${module_content}# Set found\n")
                set(module_content "${module_content}set(${module_upper}_FOUND TRUE)\n\n")
                
                set(module_content "${module_content}# Create imported target\n")
                set(module_content "${module_content}if(NOT TARGET ${module_name}::${module_name})\n")
                set(module_content "${module_content}    add_library(${module_name}::${module_name} STATIC IMPORTED)\n")
                set(module_content "${module_content}    set_target_properties(${module_name}::${module_name} PROPERTIES\n")
                set(module_content "${module_content}        IMPORTED_LOCATION \"\${${module_upper}_LIBRARY}\"\n")
                
                if(inc_dirs)
                    set(module_content "${module_content}        INTERFACE_INCLUDE_DIRECTORIES \"\${${module_upper}_INCLUDE_DIRS}\"\n")
                endif()
                
                set(module_content "${module_content}    )\n")
                set(module_content "${module_content}endif()\n\n")
                
                set(module_content "${module_content}# Handle standard arguments\n")
                set(module_content "${module_content}include(FindPackageHandleStandardArgs)\n")
                set(module_content "${module_content}find_package_handle_standard_args(${module_name}\n")
                set(module_content "${module_content}    FOUND_VAR ${module_upper}_FOUND\n")
                set(module_content "${module_content}    REQUIRED_VARS ${module_upper}_LIBRARY ${module_upper}_INCLUDE_DIRS\n")
                set(module_content "${module_content}    VERSION_VAR ${module_upper}_VERSION\n")
                set(module_content "${module_content})\n\n")
                
                set(module_content "${module_content}# Mark advanced variables\n")
                set(module_content "${module_content}mark_as_advanced(\n")
                set(module_content "${module_content}    ${module_upper}_LIBRARY\n")
                set(module_content "${module_content}    ${module_upper}_INCLUDE_DIRS\n")
                set(module_content "${module_content})\n")
                
                # 写入文件
                set(module_file "${output_dir}/Find${module_name}.cmake")
                file(WRITE ${module_file} "${module_content}")
                message(STATUS "生成CMake查找模块: ${module_file}")
            endif()
        endif()
    endforeach()
endfunction()

# 14. 主函数：提取所有库信息
function(extract_all_thirdparty_info)
    message(STATUS "\n" ${CMAKE_BOLD} "=== 提取第三方库信息 ===" ${CMAKE_RESET})
    
    # 获取所有目标
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        message(STATUS "没有找到第三方库")
        return()
    endif()
    
    # 创建输出目录
    set(output_dir ${CMAKE_CURRENT_BINARY_DIR}/thirdparty_info)
    file(MAKE_DIRECTORY ${output_dir})
    
    # 1. 获取每个库的详细信息
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_thirdparty_library_info(${target} ${target}_INFO)
        endif()
    endforeach()
    
    # 2. 生成配置文件
    generate_library_config_file("${output_dir}/library_config.cmake")
    
    # 3. 生成pkg-config文件
    foreach(target ${all_targets})
        if(TARGET ${target})
            create_pkgconfig_file(${target} ${output_dir})
        endif()
    endforeach()
    
    # 4. 生成使用示例
    generate_library_usage_example(${output_dir})
    
    # 5. 生成查找脚本
    generate_find_script("${output_dir}/find_libraries.sh")
    
    # 6. 生成CMake查找模块
    generate_cmake_find_module(${output_dir})
    
    # 7. 导出到环境变量
    export_library_paths_to_env()
    
    message(STATUS "")
    message(STATUS ${CMAKE_BOLD} "输出文件位于: ${output_dir}" ${CMAKE_RESET})
    message(STATUS "  1. library_config.cmake - CMake配置文件")
    message(STATUS "  2. Find*.cmake - CMake查找模块")
    message(STATUS "  3. *.pc - pkg-config文件")
    message(STATUS "  4. library_examples.cpp - 使用示例")
    message(STATUS "  5. find_libraries.sh - 库查找脚本")
    message(STATUS "")
    message(STATUS ${CMAKE_BOLD} "环境变量已设置:" ${CMAKE_RESET})
    message(STATUS "  THIRDPARTY_LIBRARY_DIRS - 库目录")
    message(STATUS "  THIRDPARTY_INCLUDE_DIRS - 头文件目录")
endfunction()

# 15. 创建自定义目标
function(create_extraction_targets)
    # 添加自定义目标来提取库信息
    add_custom_target(extract_thirdparty_info
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_LIST_FILE}
        COMMENT "Extracting third-party library information"
    )
    
    # 添加安装目标
    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/thirdparty_info/
        DESTINATION share/thirdparty
        COMPONENT development
    )
endfunction()

# 16. 查询库信息的命令行工具函数
function(query_library_info)
    set(options JSON CSV SIMPLE)
    set(one_value_args OUTPUT FORMAT TARGET)
    set(multi_value_args)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        message(STATUS "No third-party libraries found")
        return()
    endif()
    
    # 确定输出格式
    if(ARG_JSON)
        set(output_format "json")
    elseif(ARG_CSV)
        set(output_format "csv")
    else()
        set(output_format "simple")
    endif()
    
    # 确定目标
    if(ARG_TARGET)
        set(targets_to_query ${ARG_TARGET})
    else()
        set(targets_to_query ${all_targets})
    endif()
    
    # 生成输出
    if(output_format STREQUAL "json")
        set(output "[\n")
        set(first true)
        
        foreach(target ${targets_to_query})
            if(TARGET ${target})
                if(NOT first)
                    set(output "${output},\n")
                endif()
                set(first false)
                
                get_target_property(lib_path ${target} IMPORTED_LOCATION)
                get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
                get_target_property(version ${target} VERSION)
                get_target_property(definitions ${target} INTERFACE_COMPILE_DEFINITIONS)
                
                set(output "${output}  {\n")
                set(output "${output}    \"target\": \"${target}\",\n")
                
                if(lib_path)
                    set(output "${output}    \"library\": \"${lib_path}\",\n")
                else()
                    set(output "${output}    \"library\": null,\n")
                endif()
                
                if(inc_dirs)
                    set(output "${output}    \"includes\": \"${inc_dirs}\",\n")
                else()
                    set(output "${output}    \"includes\": null,\n")
                endif()
                
                if(version)
                    set(output "${output}    \"version\": \"${version}\",\n")
                else()
                    set(output "${output}    \"version\": null,\n")
                endif()
                
                if(definitions)
                    set(output "${output}    \"definitions\": \"${definitions}\"\n")
                else()
                    set(output "${output}    \"definitions\": null\n")
                endif()
                
                set(output "${output}  }")
            endif()
        endforeach()
        
        set(output "${output}\n]\n")
        
    elseif(output_format STREQUAL "csv")
        set(output "\"target\",\"library\",\"includes\",\"version\",\"definitions\"\n")
        
        foreach(target ${targets_to_query})
            if(TARGET ${target})
                get_target_property(lib_path ${target} IMPORTED_LOCATION)
                get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
                get_target_property(version ${target} VERSION)
                get_target_property(definitions ${target} INTERFACE_COMPILE_DEFINITIONS)
                
                # 转义CSV特殊字符
                if(lib_path)
                    string(REPLACE "\"" "\"\"" lib_path_escaped ${lib_path})
                else()
                    set(lib_path_escaped "")
                endif()
                
                if(inc_dirs)
                    string(REPLACE "\"" "\"\"" inc_dirs_escaped ${inc_dirs})
                else()
                    set(inc_dirs_escaped "")
                endif()
                
                if(definitions)
                    string(REPLACE "\"" "\"\"" definitions_escaped ${definitions})
                else()
                    set(definitions_escaped "")
                endif()
                
                set(output "${output}\"${target}\",\"${lib_path_escaped}\",\"${inc_dirs_escaped}\",\"${version}\",\"${definitions_escaped}\"\n")
            endif()
        endforeach()
        
    else()  # simple format
        set(output "Third-party Libraries:\n")
        set(output "${output}===================\n\n")
        
        foreach(target ${targets_to_query})
            if(TARGET ${target})
                get_target_property(lib_path ${target} IMPORTED_LOCATION)
                get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
                get_target_property(version ${target} VERSION)
                
                set(output "${output}${target}:\n")
                
                if(lib_path)
                    set(output "${output}  Library: ${lib_path}\n")
                endif()
                
                if(inc_dirs)
                    set(output "${output}  Includes: ${inc_dirs}\n")
                endif()
                
                if(version)
                    set(output "${output}  Version: ${version}\n")
                endif()
                
                set(output "${output}\n")
            endif()
        endforeach()
    endif()
    
    # 输出
    if(ARG_OUTPUT)
        file(WRITE ${ARG_OUTPUT} "${output}")
        message(STATUS "Library information written to ${ARG_OUTPUT}")
    else()
        message(STATUS "${output}")
    endif()
endfunction()

# 17. 集成到主CMakeLists.txt的示例
# 在您的CMakeLists.txt中添加以下内容：

# 包含提取工具
# list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
# include(ExtractThirdPartyPaths)

# 在配置第三方库后调用
# extract_all_thirdparty_info()

# 或者创建自定义目标
# create_extraction_targets()

# 示例：在命令行中查询库信息
# 可以在CMake配置阶段运行：
#   cmake -DQUERY_LIBRARIES=ON -DTARGET=MyProject_ThirdParty_JsonCpp ..
# 或者在CMake脚本中调用：
#   query_library_info(SIMPLE)
#   query_library_info(JSON OUTPUT ${CMAKE_BINARY_DIR}/libraries.json)
#   query_library_info(CSV OUTPUT ${CMAKE_BINARY_DIR}/libraries.csv)

# # 18. 生成使用文档
# function(generate_library_documentation output_dir)
#     get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
#     if(NOT all_targets)
#         return()
#     endif()
    
#     set(doc_content "# Third-party Libraries Documentation\n\n")
#     set(doc_content "${doc_content}## Overview\n\n")
#     set(doc_content "${doc_content}This document describes the third-party libraries used in this project.\n\n")
#     set(doc_content "${doc_content}## Libraries\n\n")
    
#     foreach(target ${all_targets})
#         if(TARGET ${target})
#             get_target_property(lib_path ${target} IMPORTED_LOCATION)
#             get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
#             get_target_property(version ${target} VERSION)
#             get_target_property(definitions ${target} INTERFACE_COMPILE_DEFINITIONS)
#             get_target_property(compile_options ${target} INTERFACE_COMPILE_OPTIONS)
#             get_target_property(link_options ${target} INTERFACE_LINK_OPTIONS)
            
#             # 提取库名
#             if(lib_path)
#                 get_filename_component(lib_name ${lib_path} NAME_WE)
#                 string(REGEX REPLACE "^lib" "" simple_name ${lib_name})
#             else()
#                 set(simple_name ${target})
#             endif()
            
#             set(doc_content "${doc_content}### ${simple_name}\n\n")
#             set(doc_content "${doc_content}**Target:** `${target}`\n\n")
            
#             if(version)
#                 set(doc_content "${doc_content}**Version:** ${version}\n\n")
#             endif()
            
#             if(lib_path)
#                 set(doc_content "${doc_content}**Library File:** `${lib_path}`\n\n")
#             endif()
            
#             if(inc_dirs)
#                 set(doc_content "${doc_content}**Include Directories:**\n")
#                 set(doc_content "${doc_content}

# 19. 11的生成库使用示例 
function(generate_library_usage_example output_dir)
    get_property(all_targets GLOBAL PROPERTY THIRDPARTY_STATIC_LIBS)
    
    if(NOT all_targets)
        return()
    endif()
    
    set(example_content "// Third-party library usage examples\n")
    set(example_content "${example_content}// Generated automatically\n")
    set(example_content "${example_content}#include <iostream>\n\n")
    
    foreach(target ${all_targets})
        if(TARGET ${target})
            get_target_property(inc_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
            get_target_property(definitions ${target} INTERFACE_COMPILE_DEFINITIONS)
            
            # 提取库名
            string(REPLACE "_" "::" namespace_name ${target})
            
            set(example_content "${example_content}// ========== ${target} ==========\n")
            set(example_content "${example_content}#ifdef HAVE_${target}\n")
            
            if(inc_dirs)
                set(example_content "${example_content}// Include directories: ${inc_dirs}\n")
            endif()
            
            if(definitions)
                set(example_content "${example_content}// Compile definitions: ${definitions}\n")
            endif()
            
            set(example_content "${example_content}void example_${target}() {\n")
            set(example_content "${example_content}    std::cout << \"Using ${target}\" << std::endl;\n")
            set(example_content "${example_content}}\n\n")
            set(example_content "${example_content}#endif // HAVE_${target}\n\n")
        endif()
    endforeach()
    
    # 写入文件
    set(example_file "${output_dir}/library_examples.cpp")
    file(WRITE ${example_file} "${example_content}")
    message(STATUS "生成库使用示例: ${example_file}")
endfunction()
