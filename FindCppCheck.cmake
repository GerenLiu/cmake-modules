find_program(CPPCHECK_EXECUTABLE cppcheck DOC "Path to cppcheck executable")
mark_as_advanced(CPPCHECK_EXECUTABLE)

if(CPPCHECK_EXECUTABLE)
    # get version string
    execute_process(COMMAND ${CPPCHECK_EXECUTABLE} --version
        OUTPUT_VARIABLE _cc_version_output
        ERROR_VARIABLE  _cc_version_error
        RESULT_VARIABLE _cc_version_result
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(NOT ${_cc_version_result} EQUAL 0)
        message(SEND_ERROR "command \"${CPPCHECK_EXECUTABLE} --version\" failed - ${_cc_version_error}")
    else()
        string(REGEX MATCH "[.0-9]+"
            CPPCHECK_VERSION "${_cc_version_output}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CPPCHECK
    REQUIRED_VARS CPPCHECK_EXECUTABLE
    VERSION_VAR CPPCHECK_VERSION)
mark_as_advanced(CPPCHECK_VERSION)

if(CPPCHECK_FOUND)

    message(STATUS "Enabled static analysis with Cppcheck...")

    add_custom_target(ALL_CPPCHECK)

    function(add_cppcheck _target_name)
        get_target_property(_cc_includes ${_target_name} INCLUDE_DIRECTORIES)
        get_target_property(_cc_defines ${_target_name} COMPILE_DEFINITIONS)
        get_target_property(_cc_sources ${_target_name} SOURCES)


        message(STATUS "_cc_includes = ${_cc_includes}")
        message(STATUS "_cc_defines = ${_cc_defines}")
        message(STATUS "_cc_sources = ${_cc_sources}")

        set(_cc_inc_transformed)
        foreach(_inc_dir ${_cc_includes})
            list(APPEND _cc_inc_transformed "-I\"${_inc_dir}\"")
        endforeach()

        set(_cc_def_transformed)
        foreach(_one_def ${_cc_defines})
            list(APPEND _cc_def_transformed -D${_one_def})
        endforeach()

        set(_all_rpts)
        foreach(sourcefile ${_cc_sources})
            if(sourcefile MATCHES \\.c$|\\.cxx$|\\.cpp$|\\.cc$)
                get_filename_component(_src_abs ${sourcefile} ABSOLUTE)
                get_filename_component(_src_name ${sourcefile} NAME)

                message(STATUS "_src_abs = ${_src_abs}")
                message(STATUS "_src_name = ${_src_name}")

                set(_rpt_file_name "${_src_name}.rpt")
                set(_rpt_path "${CMAKE_CURRENT_SOURCE_DIR}/cppcheck/reports/${_target_name}")
                set(_rpt_dst "${_rpt_path}/${_rpt_file_name}")

                file(MAKE_DIRECTORY ${_rpt_path})

                add_custom_command(OUTPUT ${_rpt_dst}
                    COMMAND
                    ${CPPCHECK_EXECUTABLE} --enable=all ${_cc_inc_transformed} ${_cc_def_transformed} ${_src_abs} > ${_rpt_dst}
                    VERBATIM
                    )
                list(APPEND _all_rpts ${_rpt_dst})
            else()
            endif()
        endforeach()
        add_custom_target(${_target_name}_CPPCHECK DEPENDS ${_all_rpts})
        add_dependencies(ALL_CPPCHECK ${_target_name}_CPPCHECK)

    endfunction()

else()

    message(STATUS "Cppcheck not found... Static analysis is disabled")
    function(add_cppcheck _target_name)
        #empty macro
    endfunction()
endif()