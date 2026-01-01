
set(Protobuf_INCLUDE_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)
set(Protobuf_LIBRARIES ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/lib/windows)
set(Protobuf_DIR ${CMAKE_HOME_DIRECTORY}/../../Dependencies/protobuf/protobuf-3.20.3/src)

# ���� Protobuf - ���ַ�ʽ����
set(Protobuf_FOUND FALSE)

# ��ʽ 1: ���� CONFIG ģʽ
find_package(Protobuf CONFIG QUIET)
if(TARGET protobuf::libprotobuf)
    set(Protobuf_FOUND TRUE)
    message(STATUS "Found Protobuf via CONFIG mode")
else()
    # ��ʽ 2: ����ģ��ģʽ
    find_package(Protobuf REQUIRED)
    if(Protobuf_FOUND)
        set(Protobuf_FOUND TRUE)
        message(STATUS "Found Protobuf via module mode")
    endif()
endif()

# �������û�ҵ����ֶ�����·��
if(NOT Protobuf_FOUND)
    message(WARNING "Protobuf not found via standard methods, trying manual setup")
    
    # �ֶ����ÿ��ܵ�·��
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

