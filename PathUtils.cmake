# PathUtils.cmake - CMake 路径转换工具
include_guard()

# 1. 基本路径转换函数
function(absolute_to_relative absolute_path base_dir result_var)
    # 参数验证
    if(NOT IS_ABSOLUTE "${absolute_path}")
        message(WARNING "路径 '${absolute_path}' 不是绝对路径")
        set(${result_var} "${absolute_path}" PARENT_SCOPE)
        return()
    endif()
    
    if(NOT IS_ABSOLUTE "${base_dir}")
        message(WARNING "基准目录 '${base_dir}' 不是绝对路径")
        set(${result_var} "${absolute_path}" PARENT_SCOPE)
        return()
    endif()
    
    # 规范化路径
    get_filename_component(abs_norm "${absolute_path}" ABSOLUTE)
    get_filename_component(base_norm "${base_dir}" ABSOLUTE)
    
    # 确保基准目录以斜杠结尾
    if(NOT base_norm MATCHES "/$")
        set(base_norm "${base_norm}/")
    endif()
    
    # 计算相对路径
    file(RELATIVE_PATH relative_path "${base_norm}" "${abs_norm}")
    
    # 处理特殊情况
    if("${relative_path}" STREQUAL "")
        set(${result_var} "." PARENT_SCOPE)
    else()
        set(${result_var} "${relative_path}" PARENT_SCOPE)
    endif()
endfunction()

# 2. 多种基准目录的转换
function(path_to_relative target_path)
    set(options)
    set(one_value_args
        RELATIVE_TO
        OUTPUT_VAR
    )
    set(multi_value_args)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    if(NOT ARG_RELATIVE_TO)
        set(ARG_RELATIVE_TO ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    
    if(NOT ARG_OUTPUT_VAR)
        set(ARG_OUTPUT_VAR RELATIVE_PATH_RESULT)
    endif()
    
    absolute_to_relative("${target_path}" "${ARG_RELATIVE_TO}" relative_result)
    set(${ARG_OUTPUT_VAR} "${relative_result}" PARENT_SCOPE)
endfunction()

# 3. 批量转换路径列表
function(paths_to_relative)
    set(options)
    set(one_value_args
        RELATIVE_TO
        OUTPUT_VAR
    )
    set(multi_value_args
        PATHS
    )
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    if(NOT ARG_RELATIVE_TO)
        set(ARG_RELATIVE_TO ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    
    if(NOT ARG_OUTPUT_VAR)
        set(ARG_OUTPUT_VAR RELATIVE_PATHS_RESULT)
    endif()
    
    set(relative_paths)
    foreach(path ${ARG_PATHS})
        absolute_to_relative("${path}" "${ARG_RELATIVE_TO}" rel_path)
        list(APPEND relative_paths "${rel_path}")
    endforeach()
    
    set(${ARG_OUTPUT_VAR} "${relative_paths}" PARENT_SCOPE)
endfunction()

# 4. 生成器表达式安全的路径转换
function(genex_absolute_to_relative absolute_path_expr base_dir_expr result_var)
    # 这个方法使用生成器表达式，适用于需要在生成时计算的场景
    if(NOT absolute_path_expr MATCHES "^\\$<.*>$" AND NOT base_dir_expr MATCHES "^\\$<.*>$")
        # 非生成器表达式路径，使用常规方法
        absolute_to_relative("${absolute_path_expr}" "${base_dir_expr}" result)
        set(${result_var} "${result}" PARENT_SCOPE)
    else()
        # 使用生成器表达式计算相对路径
        set(${result_var} 
            "$<IF:$<AND:$<BOOL:${absolute_path_expr}>,$<BOOL:${base_dir_expr}>>,\
                $<RELATIVE_PATH:${absolute_path_expr},${base_dir_expr}>,\
                ${absolute_path_expr}>"
            PARENT_SCOPE
        )
    endif()
endfunction()

# 5. 平台相关的路径转换
function(platform_aware_path_conversion absolute_path result_var)
    # 根据不同平台进行路径转换
    if(WIN32)
        # Windows 路径处理
        string(REPLACE "/" "\\" windows_path "${absolute_path}")
        string(REPLACE "\\\\" "\\" windows_path "${windows_path}")
        
        # 处理盘符
        if(windows_path MATCHES "^[A-Za-z]:")
            # 已经是 Windows 绝对路径
            set(converted_path "${windows_path}")
        else()
            # 转换为 Windows 路径
            get_filename_component(full_path "${windows_path}" ABSOLUTE)
            set(converted_path "${full_path}")
        endif()
        
    elseif(UNIX)
        # Unix 路径处理
        get_filename_component(full_path "${absolute_path}" ABSOLUTE)
        set(converted_path "${full_path}")
        
    else()
        # 其他平台
        set(converted_path "${absolute_path}")
    endif()
    
    set(${result_var} "${converted_path}" PARENT_SCOPE)
endfunction()

# 6. 路径规范化
function(normalize_path path result_var)
    get_filename_component(norm_path "${path}" ABSOLUTE)
    
    # 移除多余的斜杠
    while(norm_path MATCHES "//")
        string(REGEX REPLACE "//" "/" norm_path "${norm_path}")
    endwhile()
    
    # 移除末尾的斜杠（目录除外）
    if(norm_path MATCHES ".+/$" AND NOT norm_path STREQUAL "/")
        string(REGEX REPLACE "/+$" "" norm_path "${norm_path}")
    endif()
    
    # 处理 . 和 ..
    get_filename_component(final_path "${norm_path}" REALPATH)
    
    set(${result_var} "${final_path}" PARENT_SCOPE)
endfunction()

# 7. 相对路径转换工具（主函数）
function(convert_to_relative)
    set(options VERBOSE)
    set(one_value_args
        INPUT_PATH
        RELATIVE_TO
        OUTPUT_VAR
    )
    set(multi_value_args
        ADDITIONAL_BASE_DIRS
    )
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})
    
    if(NOT ARG_INPUT_PATH)
        message(FATAL_ERROR "必须提供 INPUT_PATH 参数")
    endif()
    
    if(NOT ARG_RELATIVE_TO)
        set(ARG_RELATIVE_TO ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    
    if(NOT ARG_OUTPUT_VAR)
        set(ARG_OUTPUT_VAR CONVERTED_PATH)
    endif()
    
    # 规范化输入路径
    normalize_path("${ARG_INPUT_PATH}" normalized_input)
    normalize_path("${ARG_RELATIVE_TO}" normalized_base)
    
    if(ARG_VERBOSE)
        message(STATUS "转换路径: ${normalized_input}")
        message(STATUS "相对基准: ${normalized_base}")
    endif()
    
    # 检查输入路径是否在基准目录下
    string(FIND "${normalized_input}" "${normalized_base}" pos)
    
    if(pos EQUAL 0)
        # 输入路径在基准目录下
        absolute_to_relative("${normalized_input}" "${normalized_base}" relative_result)
        
    else()
        # 输入路径不在基准目录下，尝试其他基准目录
        set(found FALSE)
        foreach(base_dir ${ARG_ADDITIONAL_BASE_DIRS} ${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
            normalize_path("${base_dir}" norm_base)
            string(FIND "${normalized_input}" "${norm_base}" pos2)
            
            if(pos2 EQUAL 0)
                absolute_to_relative("${normalized_input}" "${norm_base}" relative_result)
                set(found TRUE)
                break()
            endif()
        endforeach()
        
        if(NOT found)
            # 无法转换为相对路径，返回绝对路径
            if(ARG_VERBOSE)
                message(WARNING "无法将路径转换为相对路径: ${normalized_input}")
            endif()
            set(relative_result "${normalized_input}")
        endif()
    endif()
    
    # 平台特定的调整
    platform_aware_path_conversion("${relative_result}" platform_result)
    
    set(${ARG_OUTPUT_VAR} "${platform_result}" PARENT_SCOPE)
    
    if(ARG_VERBOSE)
        message(STATUS "转换结果: ${platform_result}")
    endif()
endfunction()

# 8. 测试函数
function(test_path_conversions)
    message(STATUS "=== 路径转换测试 ===")
    
    # 测试数据
    set(TEST_BASE_DIR "/home/user/project")
    set(TEST_PATHS
        "/home/user/project/src/main.cpp"
        "/home/user/project/include/utils.h"
        "/home/user/project/build/lib/libmylib.a"
        "/usr/local/include"
        "/home/user/other_project/src/file.cpp"
    )
    
    message(STATUS "基准目录: ${TEST_BASE_DIR}")
    message(STATUS "")
    
    foreach(test_path ${TEST_PATHS})
        convert_to_relative(
            INPUT_PATH "${test_path}"
            RELATIVE_TO "${TEST_BASE_DIR}"
            OUTPUT_VAR result
            VERBOSE
        )
        message(STATUS "输入: ${test_path}")
        message(STATUS "输出: ${result}")
        message(STATUS "")
    endforeach()
    
    # 测试批量转换
    paths_to_relative(
        PATHS ${TEST_PATHS}
        RELATIVE_TO "${TEST_BASE_DIR}"
        OUTPUT_VAR batch_result
    )
    message(STATUS "批量转换结果:")
    foreach(item ${batch_result})
        message(STATUS "  ${item}")
    endforeach()
endfunction()
