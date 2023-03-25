cmake_minimum_required(VERSION 3.15)

project(Erhu)

add_executable(${PROJECT_NAME} main.cpp)

# 设置编译产物的输出目录
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/target"
)