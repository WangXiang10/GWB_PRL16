# Install script for directory: E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files/densecrf")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf/build/src/cmake_install.cmake")
  include("E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf/build/examples/cmake_install.cmake")
  include("E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf/build/external/cmake_install.cmake")

endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

file(WRITE "E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf/build/${CMAKE_INSTALL_MANIFEST}" "")
foreach(file ${CMAKE_INSTALL_MANIFEST_FILES})
  file(APPEND "E:/wangxiang/Code_Material/Probabilistic Graphical Model/densecrf/meanfield-matlab-master/meanfield-matlab-master/include/densecrf/build/${CMAKE_INSTALL_MANIFEST}" "${file}\n")
endforeach()
