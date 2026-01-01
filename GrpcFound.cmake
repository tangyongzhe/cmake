
# 启用导入目标
if(POLICY CMP0097)
    cmake_policy(SET CMP0097 NEW)
endif()

# 修复4: 简化查找逻辑，优先使用CONFIG模式
find_package(gRPC CONFIG 
    PATHS "${gRPC_DIR}"
    NO_DEFAULT_PATH
    QUIET
)

# 查找 gRPC - 多种方式尝试
#set(GRPC_FOUND FALSE)

# 方式 1: 尝试 CONFIG 模式
#find_package(gRPC CONFIG QUIET)
#if(TARGET gRPC::grpc++)
#    set(GRPC_FOUND TRUE)
#    message(STATUS "Found gRPC via CONFIG mode")
#else()
#    # 方式 2: 尝试模块模式
#    find_package(gRPC REQUIRED)
#    if(GRPC_FOUND)
#        set(GRPC_FOUND TRUE)
#        message(STATUS "Found gRPC via module mode")
#        message("gRPC_DIR:${gRPC_DIR}")
#    endif()
#endif()

# 如果还是没找到，手动设置路径
#if(NOT GRPC_FOUND)
#    message(WARNING "gRPC not found via standard methods, trying manual setup")
#    
#    # 手动设置可能的路径
#    set(gRPC_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/grpc" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/grpc/include" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/grpc/lib/Windows")
#    foreach(test_dir IN LISTS gRPC_DIR)
#        if(EXISTS "${test_dir}/cmake")
#            set(gRPC_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/grpc/include")
#            break()
#        endif()
#    endforeach()
#    
#    find_package(gRPC CONFIG REQUIRED HINTS "${gRPC_DIR}")
#    if(TARGET gRPC::grpc++)
#        set(GRPC_FOUND TRUE)
#        message(STATUS "Found gRPC manually at: ${gRPC_DIR}")
#    endif()
#endif()
#
#if(NOT GRPC_FOUND)
#    message(FATAL_ERROR "gRPC not found. Please install gRPC or set gRPC_DIR properly")
#endif()


# 修复1: 定义手动查找函数
function(MANUALLY_FIND_GRPC)
    # 设置可能的包含目录
    set(GRPC_INCLUDE_DIR "${GRPC_ROOT}/include")
    
    # 设置库文件搜索路径（根据构建类型）
    if(WIN32)
	    set(GRPC_LIBRARY_DIRS 
	        "${GRPC_ROOT}/lib/Windows/Debug"
	        "${GRPC_ROOT}/lib"
	    	)
    else(WIN32)
        set(GRPC_LIBRARY_DIRS 
        "${GRPC_ROOT}/lib/linux/${CMAKE_BUILD_TYPE}"
        "${GRPC_ROOT}/lib"
    		)
    endif(WIN32)
    
    # 定义需要查找的库列表
    set(GRPC_LIBRARIES_TO_FIND
        grpc++
        grpc
        gpr
        address_sorting
        upb
        re2
        absl_strings
        absl_throw_delegate
    )
    
    # 查找所有库文件
    foreach(lib ${GRPC_LIBRARIES_TO_FIND})
        find_library(GRPC_${lib}_LIBRARY
            NAMES ${lib}
            PATHS ${GRPC_LIBRARY_DIRS}
            NO_DEFAULT_PATH
        )
        if(GRPC_${lib}_LIBRARY)
            list(APPEND GRPC_LIBRARIES ${GRPC_${lib}_LIBRARY})
        endif()
    endforeach()
    
    # 查找插件
    set(GRPC_CPP_PLUGIN_EXECUTABLE "${GRPC_ROOT}/bin/Windows/grpc_cpp_plugin")
    if(NOT EXISTS "${GRPC_CPP_PLUGIN_EXECUTABLE}")
        set(GRPC_CPP_PLUGIN_EXECUTABLE "${GRPC_CPP_PLUGIN_EXECUTABLE}.exe")
    endif()
    
    message(STATUS "222 Found gRPC libraries: ${GRPC_LIBRARIES}")
    message(STATUS "222 Found gRPC includes: ${GRPC_INCLUDE_DIR}")
    message(STATUS "222 Found gRPC plugin: ${GRPC_CPP_PLUGIN_EXECUTABLE}")
    
    # 创建导入目标
    if(GRPC_LIBRARIES AND GRPC_INCLUDE_DIR)
        add_library(gRPC::grpc++ UNKNOWN IMPORTED)
        set_target_properties(gRPC::grpc++ PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${GRPC_INCLUDE_DIR}"
            IMPORTED_LOCATION "${GRPC_grpc++_LIBRARY}"
            INTERFACE_LINK_LIBRARIES "${GRPC_LIBRARIES}"
        )
        
        set(GRPC_FOUND TRUE PARENT_SCOPE)
        set(gRPC_DIR "${GRPC_ROOT}" PARENT_SCOPE)
    endif()
endfunction()
