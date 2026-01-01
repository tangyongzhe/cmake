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
    # 1. 获取当前目录的目标
    get_property(TARGETS_IN_DIR DIRECTORY ${root_dir} PROPERTY BUILDSYSTEM_TARGETS)
    
    # 将获取到的目标追加到传递进来的列表变量中
    list(APPEND ${output_list_var} ${TARGETS_IN_DIR})

    # 2. 获取当前目录的所有子目录
    get_property(SUBDIRS DIRECTORY ${root_dir} PROPERTY SUBDIRECTORIES)
    
    # 3. 遍历子目录并递归调用
    foreach(SUBDIR IN LISTS SUBDIRS)
        # 完整的子目录路径
        set(FULL_SUBDIR_PATH "${root_dir}/${SUBDIR}")
        
        # 递归调用。注意：必须在 parent scope 中设置 output_list_var
        get_all_targets_recursive(${FULL_SUBDIR_PATH} ${output_list_var})
    endforeach()
    
    # 将最终的列表设置回父作用域，否则函数退出后列表会丢失
    set(${output_list_var} ${${output_list_var}} PARENT_SCOPE)

endfunction()