cmake_minimum_required(VERSION 3.27)
project(lab5 C)

set(CMAKE_C_STANDARD 11)
add_compile_options(-g -O1)
add_link_options(-lm)

add_executable(main main.c img_holder.c img_holder.h error_enum.h)
