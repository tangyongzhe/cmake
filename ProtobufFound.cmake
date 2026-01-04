
# set(Protobuf_INCLUDE_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)
# set(Protobuf_LIBRARIES ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/lib/windows)
# set(Protobuf_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)

# ���� Protobuf - ���ַ�ʽ����
# set(Protobuf_FOUND FALSE)

# # ��ʽ 1: ���� CONFIG ģʽ
# find_package(Protobuf CONFIG QUIET)
# if(TARGET protobuf::libprotobuf)
#     set(Protobuf_FOUND TRUE)
#     message(STATUS "Found Protobuf via CONFIG mode")
# else()
#     # ��ʽ 2: ����ģ��ģʽ
#     find_package(Protobuf REQUIRED)
#     if(Protobuf_FOUND)
#         set(Protobuf_FOUND TRUE)
#         message(STATUS "Found Protobuf via module mode")
#     endif()
# endif()

# # �������û�ҵ����ֶ�����·��
# if(NOT Protobuf_FOUND)
#     message(WARNING "Protobuf not found via standard methods, trying manual setup")
    
#     # �ֶ����ÿ��ܵ�·��
#     set(Protobuf_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/lib/windows")
#     foreach(test_dir IN LISTS Protobuf_DIR)
#         if(EXISTS "${test_dir}/lib/cmake/Protobuf")
#             set(Protobuf_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src")
#             break()
#         endif()
#     endforeach()
    
#     find_package(Protobuf CONFIG REQUIRED HINTS "${Protobuf_DIR}")
#     if(TARGET protobuf::libprotobuf)
#         set(Protobuf_FOUND TRUE)
#         message(STATUS "Found Protobuf manually at: ${Protobuf_DIR}")
#     endif()
# endif()

# if(NOT Protobuf_FOUND)
#     message(FATAL_ERROR "Protobuf not found. Please install Protobuf or set Protobuf_DIR properly")
# endif()

# ============================================================================
# 2. 跨平台的 protobuf_generate_cpp 实现
# ============================================================================
function(my_protobuf_generate_cpp SRCS HDRS)
    # 解析参数
    cmake_parse_arguments(proto "" "PROTOC_EXECUTABLE;EXPORT_MACRO;OUTPUT_DIR" "" ${ARGN})
    
    set(proto_files ${proto_UNPARSED_ARGUMENTS})
    if(NOT proto_files)
        message(SEND_ERROR "未提供 .proto 文件")
        return()
    endif()
    
    if(NOT proto_PROTOC_EXECUTABLE)
        message(SEND_ERROR "未提供 protoc 执行文件")
        return()
    else()
         message(STATUS "执行文件:${proto_PROTOC_EXECUTABLE}")
    endif()

    # 设置输出目录
    if(proto_OUTPUT_DIR)
        set(output_dir ${proto_OUTPUT_DIR})
    else()
        set(output_dir ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    
    # 确保输出目录存在
    file(MAKE_DIRECTORY ${output_dir})
    
    # 清空输出变量
    set(${SRCS})
    set(${HDRS})
    
    foreach(proto_file ${proto_files})
        # 获取 proto 文件的绝对路径
        get_filename_component(proto_abs ${proto_file} ABSOLUTE)
        
        # 获取 proto 文件的基本名（不带路径和扩展名）
        get_filename_component(proto_basename ${proto_abs} NAME_WE)
        
        # 获取 proto 文件的目录
        get_filename_component(proto_dir ${proto_abs} DIRECTORY)
        
        # 设置生成的 C++ 文件路径
        if(WIN32)
            # Windows 上使用 \ 作为路径分隔符
            set(cc_file ${output_dir}${proto_basename}.pb.cc)
            set(h_file ${output_dir}${proto_basename}.pb.h)
        else()
            # Unix 上使用 / 作为路径分隔符
            set(cc_file ${output_dir}/${proto_basename}.pb.cc)
            set(h_file ${output_dir}/${proto_basename}.pb.h)
        endif()
        
        # 添加到输出列表
        list(APPEND ${SRCS} ${cc_file})
        list(APPEND ${HDRS} ${h_file})
        
        # 构建 protoc 命令
        set(protoc_cmd 
            ${proto_PROTOC_EXECUTABLE}
            ARGS
            --cpp_out=${output_dir}
            -I${proto_dir}
            ${proto_abs}
        )
        
        # 添加自定义命令来生成文件
        add_custom_command(
            OUTPUT ${cc_file} ${h_file}
            COMMAND ${protoc_cmd}
            DEPENDS ${proto_abs}
            COMMENT "生成 ${proto_basename}.pb.cc 和 ${proto_basename}.pb.h"
            VERBATIM
        )
        
        message(STATUS "为 ${proto_basename}.proto 添加生成规则")
        message(STATUS "  输出目录: ${output_dir}")
        message(STATUS "  生成文件: ${proto_basename}.pb.cc, ${proto_basename}.pb.h")
    endforeach()
    
    # 设置父作用域变量
    set(${SRCS} ${${SRCS}} PARENT_SCOPE)
    set(${HDRS} ${${HDRS}} PARENT_SCOPE)
    
    # 设置源文件属性
    source_group("Generated" FILES ${${SRCS}} ${${HDRS}})
endfunction()
