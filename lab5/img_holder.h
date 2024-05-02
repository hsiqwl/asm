#ifndef LAB5_BMP_IMG_H
#define LAB5_BMP_IMG_H
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "error_enum.h"
typedef struct img_holder{
    unsigned char* pixels;
    int width;
    int height;
    int channels;
}img_holder;

int get_expanded_img(const img_holder* image, img_holder* expanded_image);

void copy_corners(const img_holder* image, img_holder* expanded_image);

void copy_base(const img_holder* image, img_holder* expanded_image);

void copy_edges(const img_holder* image, img_holder* expanded_image);

int load_image_from_file(const char* filename, img_holder* image);

int load_image_to_file(const char* filename, const img_holder* image);

void blur_image(const img_holder* src, img_holder* dest, const double kernel[3][3]);

unsigned char compute_pixel(const unsigned char* src_ptr, int width, int channels ,const double kernel[3][3]);

//void blur_image_asm(const img_holder* src, img_holder* dest, const double kernel[3][3]);

#endif //LAB5_BMP_IMG_H
