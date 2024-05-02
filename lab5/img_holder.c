#include "img_holder.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image/stb_image_write.h"
#define STBI_NO_HDR
#define STBI_NO_LINEAR

int load_image_from_file(const char* filename, img_holder* image){
    if(access(filename, R_OK) != 0){
        image = NULL;
        return BAD_FILE_ACCESS;
    }
    free(image);

    image = (img_holder*)malloc(sizeof(img_holder));
    if(image == NULL){
        return BAD_MEMORY_ALLOCATION;
    }

    image->pixels = stbi_load(filename, &(image->width), &(image->height), &(image->channels), 0);
    if(image->pixels == NULL){
        free(image);
        return BAD_IMAGE_LOAD;
    }

    return OK;
}

int load_image_to_file(const char* filename, const img_holder* image){
    FILE* file = fopen(filename, "w");
    if(file == NULL){
        return BAD_FILE_ACCESS;
    }
    fclose(file);
    stbi_write_bmp(filename, image->width, image->height, image->channels, image->pixels);
    return OK;
}

int get_expanded_img(const img_holder* image, img_holder* expanded_image) {
    expanded_image->width = image->width + 2;
    expanded_image->height = image->height + 2;
    expanded_image->channels = image->channels;
    expanded_image->pixels = (unsigned char *) malloc(expanded_image->width * expanded_image->height * expanded_image->channels * sizeof(unsigned char));
    if (expanded_image->pixels == NULL) {
        free(expanded_image);
        return BAD_MEMORY_ALLOCATION;
    }
    copy_corners(image, expanded_image);
    copy_base(image, expanded_image);
    copy_edges(image, expanded_image);
    return OK;
}

void copy_corners(const img_holder* image, img_holder* expanded_image){
    //copy top-left-corner
    const unsigned char* src = image->pixels;
    unsigned char* dest = expanded_image->pixels;
    memcpy(dest, src, image->channels);

    //copy top-right-corner
    src = image->pixels + (image->width - 1) * image->channels;
    dest = expanded_image->pixels + (expanded_image->width - 1) * image->channels;
    memcpy(dest, src, image->channels);

    //copy bottom-left-corner
    src = image->pixels + (image->height - 1) * image->width * image->channels;
    dest = expanded_image->pixels + (expanded_image->height - 1) * expanded_image->width * expanded_image->channels;
    memcpy(dest, src, image->channels);

    //copy bottom-right-corner
    src = image->pixels + image->height * image->width * image->channels - image->channels;
    dest = expanded_image->pixels + expanded_image->height * expanded_image->width * expanded_image->channels - expanded_image->channels;
    memcpy(dest, src, image->channels);
}

void copy_base(const img_holder* image, img_holder* expanded_image){
    printf("copying base\n");
    for(int i = 0; i < image->height; ++i){
        unsigned char* src = image->pixels + i * image->width * image->channels;
        unsigned char* dest = expanded_image->pixels + (i + 1) * expanded_image->width * image->channels + image->channels;
        memcpy(dest, src, image->width * image->channels);
    }
}

void copy_edges(const img_holder* image, img_holder* expanded_image) {
    //copy top edge
    unsigned char *src = image->pixels;
    unsigned char *dest = expanded_image->pixels + image->channels;
    memcpy(dest, src, image->width * image->channels);

    //copy bottom edge
    src = image->pixels + (image->height - 1) * image->width * image->channels;
    dest = expanded_image->pixels + (expanded_image->height - 1) * expanded_image->width * image->channels +
           image->channels;
    memcpy(dest, src, image->width * image->channels);

    //copy right and left edge
    for (int i = 0; i < image->height; ++i) {
        src = image->pixels + i * image->width * image->channels;
        dest = expanded_image->pixels + i * expanded_image->width * image->channels;
        memcpy(dest, src, image->channels);
        src = image->pixels + i * image->width * image->channels + (image->width - 1) * image->channels;
        dest = expanded_image->pixels + i * expanded_image->width * image->channels +
               (expanded_image->width - 1) * image->channels;
        memcpy(dest, src, image->channels);
    }
}

void blur_image(const img_holder* src, img_holder* dest, const double kernel[3][3]) {
    for (int i = 1; i < src->height - 1; ++i) {
        for (int j = 1; j < src->width - 1; ++j) {
            for (int c = 0; c < src->channels; ++c) {
                if (c > 3)
                    continue;
                unsigned char px = 0;
                px += src->pixels[((i - 1) * src->width + (j - 1)) * src->channels + c] * kernel[0][0];
                px += src->pixels[((i - 1) * src->width + (j)) * src->channels + c] * kernel[0][1];
                px += src->pixels[((i - 1) * src->width + (j + 1)) * src->channels + c] * kernel[0][2];

                // middle row
                px += src->pixels[((i) * src->width + (j - 1)) * src->channels + c] * kernel[1][0];
                px += src->pixels[((i) * src->width + (j)) * src->channels + c] * kernel[1][1];
                px += src->pixels[((i) * src->width + (j + 1)) * src->channels + c] * kernel[1][2];

                // bottom row
                px += src->pixels[((i + 1) * src->width + (j - 1)) * src->channels + c] * kernel[2][0];
                px += src->pixels[((i + 1) * src->width + (j)) * src->channels + c] * kernel[2][1];
                px += src->pixels[((i + 1) * src->width + (j + 1)) * src->channels + c] * kernel[2][2];

                // set px
                dest->pixels[((i - 1) * dest->width + (j - 1)) * dest->channels + c] = px;
            }
        }
    }
}

unsigned char compute_pixel(const unsigned char* src_ptr, int width, int channels ,const double kernel[3][3]) {
    unsigned char pixel = 0;
    pixel += *(src_ptr - width * channels - channels) * kernel[0][0];
    pixel += *(src_ptr - width * channels) * kernel[0][1];
    pixel += *(src_ptr - width * channels + channels) * kernel[0][2];
    pixel += *(src_ptr - channels) * kernel[1][0];
    pixel += *(src_ptr) * kernel[1][1];
    pixel += *(src_ptr + channels) * kernel[1][2];
    pixel += *(src_ptr + width * channels - channels) * kernel[2][0];
    pixel += *(src_ptr + width * channels) * kernel[2][1];
    pixel += *(src_ptr + width * channels + channels) * kernel[2][2];
    return pixel;
}