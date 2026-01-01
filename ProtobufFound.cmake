
set(Protobuf_INCLUDE_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)
set(Protobuf_LIBRARIES ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/lib/windows)
set(Protobuf_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)

# 查找 Protobuf - 多种方式尝试
set(Protobuf_FOUND FALSE)

# 方式 1: 尝试 CONFIG 模式
find_package(Protobuf CONFIG QUIET)
if(TARGET protobuf::libprotobuf)
    set(Protobuf_FOUND TRUE)
    message(STATUS "Found Protobuf via CONFIG mode")
else()
    # 方式 2: 尝试模块模式
    find_package(Protobuf REQUIRED)
    if(Protobuf_FOUND)
        set(Protobuf_FOUND TRUE)
        message(STATUS "Found Protobuf via module mode")
    endif()
endif()

# 如果还是没找到，手动设置路径
if(NOT Protobuf_FOUND)
    message(WARNING "Protobuf not found via standard methods, trying manual setup")
    
    # 手动设置可能的路径
    set(Protobuf_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src" "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/lib/windows")
    foreach(test_dir IN LISTS Protobuf_DIR)
        if(EXISTS "${test_dir}/lib/cmake/Protobuf")
            set(Protobuf_DIR "${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src")
            break()
        endif()
    endforeach()
    
    find_package(Protobuf CONFIG REQUIRED HINTS "${Protobuf_DIR}")
    if(TARGET protobuf::libprotobuf)
        set(Protobuf_FOUND TRUE)
        message(STATUS "Found Protobuf manually at: ${Protobuf_DIR}")
    endif()
endif()

if(NOT Protobuf_FOUND)
    message(FATAL_ERROR "Protobuf not found. Please install Protobuf or set Protobuf_DIR properly")
endif()
