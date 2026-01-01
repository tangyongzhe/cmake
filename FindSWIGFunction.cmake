# FindSWIG.cmake - 完整的 SWIG 查找函数实现
# 模拟 find_package(SWIG REQUIRED) 的功能
# 修复了 CMP0086 策略警告问题

# 主查找函数
function(find_swig)
    # 解析参数
    set(options REQUIRED QUIET EXACT)
    set(oneValueArgs VERSION)
    set(multiValueArgs COMPONENTS)
    cmake_parse_arguments(SWIG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # 避免重复查找
    if(DEFINED SWIG_FOUND AND SWIG_FOUND)
        return()
    endif()
    
    message(STATUS "查找 SWIG...")
    
    # 1. 查找 SWIG 可执行文件
    find_swig_executable()
    
    if(SWIG_EXECUTABLE)
        # 2. 获取 SWIG 版本
        get_swig_version(${SWIG_EXECUTABLE})
        
        # 3. 检查版本要求
        check_swig_version("${SWIG_VERSION}" "${SWIG_VERSION}")
        
        # 4. 查找 UseSWIG.cmake
        find_swig_use_file(${SWIG_EXECUTABLE})
        
        # 5. 设置结果变量
        set(SWIG_FOUND TRUE PARENT_SCOPE)
        set(SWIG_EXECUTABLE ${SWIG_EXECUTABLE} PARENT_SCOPE)
        set(SWIG_VERSION ${SWIG_VERSION} PARENT_SCOPE)
        set(SWIG_DIR ${SWIG_DIR} PARENT_SCOPE)
        set(SWIG_USE_FILE ${SWIG_USE_FILE} PARENT_SCOPE)
        
        # 6. 输出找到的信息
        if(NOT SWIG_QUIET)
            message(STATUS "找到 SWIG: ${SWIG_EXECUTABLE} (版本 ${SWIG_VERSION})")
            if(SWIG_USE_FILE)
                message(STATUS "  UseSWIG.cmake: ${SWIG_USE_FILE}")
            endif()
        endif()
    else()
        set(SWIG_FOUND FALSE PARENT_SCOPE)
        
        # 处理 REQUIRED 参数
        if(SWIG_REQUIRED)
            message(FATAL_ERROR "未找到 SWIG (REQUIRED)")
        elseif(NOT SWIG_QUIET)
            message(STATUS "未找到 SWIG")
        endif()
    endif()
    
    # 7. 设置缓存变量
    set(SWIG_EXECUTABLE ${SWIG_EXECUTABLE} CACHE FILEPATH "SWIG 可执行文件路径")
    set(SWIG_VERSION ${SWIG_VERSION} CACHE STRING "SWIG 版本")
    set(SWIG_DIR ${SWIG_DIR} CACHE PATH "SWIG 安装目录")
    set(SWIG_USE_FILE ${SWIG_USE_FILE} CACHE FILEPATH "SWIG 使用文件路径")
    set(SWIG_FOUND ${SWIG_FOUND} CACHE BOOL "SWIG 是否找到" FORCE)
    
    # 8. 标记高级变量
    mark_as_advanced(
        SWIG_EXECUTABLE
        SWIG_DIR
        SWIG_VERSION
        SWIG_USE_FILE
    )
endfunction()

# 查找 SWIG 可执行文件
function(find_swig_executable)
    # 根据不同平台设置可执行文件名
    if(WIN32)
        set(executable_names
            swig.exe
            swig4.2.exe
            swig4.1.exe
            swig4.0.exe
            swig3.0.exe
        )
    else()
        set(executable_names
            swig
            swig4.2
            swig4.1
            swig4.0
            swig3.0
            swig3.1
        )
    endif()
    
    # 设置搜索路径
    set(search_paths)
    
    # 用户自定义路径
    if(DEFINED ENV{SWIG_ROOT})
        list(APPEND search_paths "$ENV{SWIG_ROOT}/bin")
    endif()
    
    if(DEFINED SWIG_ROOT)
        list(APPEND search_paths "${SWIG_ROOT}/bin")
    endif()
    
    # 平台特定路径
    if(WIN32)
        # 使用更安全的方法处理 Windows 路径
        if(DEFINED ENV{ProgramFiles})
            set(PROGRAMFILES "$ENV{ProgramFiles}")
            if(PROGRAMFILES)
                list(APPEND search_paths "${PROGRAMFILES}/swig*/bin")
            endif()
        endif()
        
        # 处理 ProgramFiles(x86) - 更安全的方法
        if(DEFINED ENV{ProgramFiles})
            # 尝试获取 x86 程序文件路径
            execute_process(
                COMMAND cmd /c "echo %ProgramFiles(x86)%"
                OUTPUT_VARIABLE PROGRAMFILES_X86
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            if(PROGRAMFILES_X86 AND NOT PROGRAMFILES_X86 MATCHES "^%ProgramFiles")
                list(APPEND search_paths "${PROGRAMFILES_X86}/swig*/bin")
            endif()
        endif()
        
        # 备选方案：直接使用硬编码路径
        list(APPEND search_paths
            "C:/Program Files/swig*/bin"
            "C:/Program Files (x86)/swig*/bin"
        )
    elseif(APPLE)
        list(APPEND search_paths
            /usr/local/bin
            /opt/local/bin
            /opt/homebrew/bin
            /sw/bin
        )
    else()
        list(APPEND search_paths
            /usr/local/bin
            /usr/bin
            /bin
            /usr/local/swig/bin
            /opt/swig/bin
        )
    endif()
    
    # 查找可执行文件
    find_program(SWIG_EXECUTABLE
        NAMES ${executable_names}
        PATHS ${search_paths}
        DOC "SWIG 可执行文件"
        NO_DEFAULT_PATH
    )
    
    # 如果没有找到，尝试系统默认路径
    if(NOT SWIG_EXECUTABLE)
        find_program(SWIG_EXECUTABLE
            NAMES ${executable_names}
            DOC "SWIG 可执行文件"
        )
    endif()
    
    # 设置结果
    set(SWIG_EXECUTABLE ${SWIG_EXECUTABLE} PARENT_SCOPE)
endfunction()

# 获取 SWIG 版本
function(get_swig_version swig_executable)
    if(NOT swig_executable)
        return()
    endif()
    
    # 执行 swig -version 获取版本信息
    execute_process(
        COMMAND ${swig_executable} -version
        OUTPUT_VARIABLE version_output
        ERROR_VARIABLE version_error
        RESULT_VARIABLE result
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(result EQUAL 0)
        # 解析版本号
        if(version_output MATCHES "SWIG Version ([0-9]+\\.[0-9]+\\.[0-9]+)")
            set(version "${CMAKE_MATCH_1}")
        elseif(version_output MATCHES "SWIG Version ([0-9]+\\.[0-9]+)")
            set(version "${CMAKE_MATCH_1}.0")
        else()
            set(version "0.0.0")
        endif()
    else()
        set(version "0.0.0")
    endif()
    
    # 获取安装目录
    get_filename_component(swig_dir "${swig_executable}" DIRECTORY)
    get_filename_component(swig_dir "${swig_dir}/.." ABSOLUTE)
    
    set(SWIG_VERSION ${version} PARENT_SCOPE)
    set(SWIG_DIR ${swig_dir} PARENT_SCOPE)
    set(SWIG_VERSION_OUTPUT "${version_output}" PARENT_SCOPE)
endfunction()

# 检查版本要求
function(check_swig_version found_version required_version)
    if(NOT required_version)
        return()
    endif()
    
    if(NOT found_version)
        message(WARNING "无法获取 SWIG 版本")
        return()
    endif()
    
    # 比较版本
    if(found_version VERSION_LESS required_version)
        message(FATAL_ERROR 
            "找到的 SWIG 版本 ${found_version} 低于要求的 ${required_version}")
    endif()
    
    # 精确版本检查
    if(DEFINED SWIG_FIND_VERSION_EXACT AND SWIG_FIND_VERSION_EXACT)
        if(NOT found_version VERSION_EQUAL required_version)
            message(FATAL_ERROR
                "找到的 SWIG 版本 ${found_version} 不等于精确要求的 ${required_version}")
        endif()
    endif()
endfunction()

# 查找 UseSWIG.cmake 文件
function(find_swig_use_file swig_executable)
    if(NOT swig_executable)
        return()
    endif()
    
    # 获取 SWIG 安装目录
    get_filename_component(swig_bin_dir "${swig_executable}" DIRECTORY)
    get_filename_component(swig_dir "${swig_bin_dir}/.." ABSOLUTE)
    
    # 设置搜索路径
    set(search_paths
        "${swig_dir}"
        "${swig_dir}/share"
        "${swig_dir}/share/swig"
        "${swig_dir}/swig"
        "${CMAKE_ROOT}/Modules"
    )
    
    # 查找 UseSWIG.cmake
    find_file(SWIG_USE_FILE
        NAMES UseSWIG.cmake
        PATHS ${search_paths}
        PATH_SUFFIXES
            cmake
            swig
            Lib/cmake
        DOC "SWIG 的 CMake 使用文件"
        NO_DEFAULT_PATH
    )
    
    # 如果没有找到，尝试默认搜索
    if(NOT SWIG_USE_FILE)
        find_file(SWIG_USE_FILE
            NAMES UseSWIG.cmake
            DOC "SWIG 的 CMake 使用文件"
        )
    endif()
    
    set(SWIG_USE_FILE ${SWIG_USE_FILE} PARENT_SCOPE)
endfunction()

# 修复 CMP0086 策略警告的函数
function(fix_cmp0086_policy)
    # 检查 CMake 版本是否支持 CMP0086
    if(POLICY CMP0086)
        # 设置策略 CMP0086 为 NEW
        # 这会让 UseSWIG 通过 -module 标志来使用 SWIG_MODULE_NAME
        cmake_policy(SET CMP0086 NEW)
        message(STATUS "已设置策略 CMP0086 为 NEW")
    else()
        message(STATUS "CMake 版本不支持 CMP0086 策略")
    endif()
endfunction()

# 包含 UseSWIG.cmake 并处理策略警告
function(include_swig_with_policy_fix)
    if(NOT SWIG_FOUND)
        message(FATAL_ERROR "SWIG 未找到，无法包含 UseSWIG.cmake")
    endif()
    
    if(NOT SWIG_USE_FILE)
        message(FATAL_ERROR "未找到 UseSWIG.cmake")
    endif()
    
    # 修复 CMP0086 策略警告
    fix_cmp0086_policy()
    
    # 现在包含 UseSWIG.cmake
    message(STATUS "包含 UseSWIG.cmake: ${SWIG_USE_FILE}")
    include(${SWIG_USE_FILE})
    
    # 检查是否成功包含
    if(COMMAND swig_add_library)
        message(STATUS "✓ 成功包含 UseSWIG.cmake")
        message(STATUS "  可用命令: swig_add_library, swig_link_libraries")
    else()
        message(WARNING "包含 UseSWIG.cmake 但未找到 swig_add_library 命令")
    endif()
endfunction()

# 使用示例函数
function(example_swig_usage)
    message(STATUS "=== SWIG 查找函数使用示例 ===")
    
    # 示例1: 基本查找
    message(STATUS "示例1: 基本查找")
    find_swig()
    
    if(SWIG_FOUND)
        message(STATUS "  SWIG 可执行文件: ${SWIG_EXECUTABLE}")
        message(STATUS "  SWIG 版本: ${SWIG_VERSION}")
    endif()
    
    # 示例2: 指定版本
    message(STATUS "示例2: 指定版本查找")
    find_swig(3.0 REQUIRED)
    
    if(SWIG_FOUND)
        message(STATUS "  找到 SWIG 3.0+")
    endif()
    
    # 示例3: 静默模式
    message(STATUS "示例3: 静默模式查找")
    find_swig(QUIET)
    
    if(SWIG_FOUND)
        message(STATUS "  找到 SWIG (静默模式)")
    endif()
    
    # 示例4: 使用修复后的包含函数
    if(SWIG_FOUND AND SWIG_USE_FILE)
        message(STATUS "示例4: 包含 UseSWIG.cmake (已修复策略警告)")
        include_swig_with_policy_fix()
    endif()
endfunction()

# 测试函数
function(test_find_swig)
    message(STATUS "=== 测试 SWIG 查找函数 ===")
    
    # 保存当前变量
    set(old_swig_found ${SWIG_FOUND})
    set(old_swig_executable ${SWIG_EXECUTABLE})
    
    # 清除变量
    unset(SWIG_FOUND CACHE)
    unset(SWIG_EXECUTABLE CACHE)
    unset(SWIG_VERSION CACHE)
    unset(SWIG_DIR CACHE)
    unset(SWIG_USE_FILE CACHE)
    
    # 测试1: 基本查找
    message(STATUS "测试1: 基本查找")
    find_swig()
    
    if(SWIG_FOUND)
        message(STATUS "  ✓ 找到 SWIG: ${SWIG_EXECUTABLE}")
    else()
        message(STATUS "  ✗ 未找到 SWIG")
    endif()
    
    # 测试2: 版本检查
    if(SWIG_FOUND)
        message(STATUS "测试2: 版本检查")
        message(STATUS "  当前版本: ${SWIG_VERSION}")
        
        # 检查是否支持版本 3.0
        if(SWIG_VERSION VERSION_GREATER_EQUAL 3.0)
            message(STATUS "  ✓ 支持 SWIG 3.0+")
        else()
            message(STATUS "  ✗ 不支持 SWIG 3.0+")
        endif()
    endif()
    
    # 测试3: UseSWIG 查找
    if(SWIG_FOUND)
        message(STATUS "测试3: UseSWIG 查找")
        if(SWIG_USE_FILE)
            message(STATUS "  ✓ 找到 UseSWIG.cmake: ${SWIG_USE_FILE}")
        else()
            message(STATUS "  ✗ 未找到 UseSWIG.cmake")
        endif()
    endif()
    
    # 测试4: 策略修复
    message(STATUS "测试4: 策略修复测试")
    fix_cmp0086_policy()
    
    # 恢复变量
    set(SWIG_FOUND ${old_swig_found} CACHE BOOL "" FORCE)
    set(SWIG_EXECUTABLE ${old_swig_executable} CACHE FILEPATH "" FORCE)
    
    message(STATUS "测试完成")
endfunction()

# 主函数：演示完整用法
function(demo_complete_swig_find)
    message(STATUS "开始演示完整的 SWIG 查找功能")
    message(STATUS "========================================")
    
    # 演示查找功能
    example_swig_usage()
    
    # 运行测试
    test_find_swig()
    
    # 实际使用示例
    if(SWIG_FOUND)
        message(STATUS "实际使用示例:")
        
        # 包含 UseSWIG
        if(SWIG_USE_FILE)
            include_swig_with_policy_fix()
            
            # 创建简单的 SWIG 项目示例
            message(STATUS "创建 SWIG 项目示例...")
            
            # 这里可以添加创建示例 SWIG 项目的代码
            # 但由于这是一个独立模块，我们只输出说明
            
            message(STATUS "  ✓ 包含 UseSWIG.cmake 成功")
            message(STATUS "  可用命令:")
            message(STATUS "    • swig_add_library()")
            message(STATUS "    • swig_link_libraries()")
        endif()
    endif()
    
    message(STATUS "演示完成")
    message(STATUS "========================================")
endfunction()

# 快速修复函数：在 CMakeLists.txt 中调用此函数可以修复策略警告
function(swig_setup)
    # 查找 SWIG
    find_swig(${ARGN})
    
    # 如果找到，设置策略并包含 UseSWIG
    if(SWIG_FOUND AND SWIG_USE_FILE)
        fix_cmp0086_policy()
        include(${SWIG_USE_FILE})
    endif()
endfunction()

