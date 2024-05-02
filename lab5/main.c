#include <stdio.h>
#include <time.h>
#include "img_holder.h"

int main(int argc, char* argv[]) {
    const char *errmsgs[3] = {"Error during file accessing, make sure file exists or the path to it is correct",
                              "Error happened during memory allocation",
                              "Error happened during loading an image"};
    if (argc < 3) {
        printf("Usage: %s <input filename> <output filename>", argv[0]);
        return 0;
    }
    img_holder *image = (img_holder *) malloc(sizeof(img_holder));
    if (image == NULL) {
        printf("Error during memory allocation\n");
        return 0;
    }
    int flag = load_image_from_file(argv[1], image);
    if (flag != OK) {
        printf("%s", errmsgs[flag]);
        free(image);
        return 0;
    }
    printf("loaded image from file\n");
    img_holder *expanded_image = (img_holder *) malloc(sizeof(img_holder));
    flag = get_expanded_img(image, expanded_image);
    if (flag != OK) {
        printf("%s", errmsgs[flag]);
        free(image);
        free(expanded_image);
        return 0;
    }
    printf("expanded image\n");

    const double kernel[3][3] = {{0.0625, 0.125, 0.0625},
                                 {0.125, 0.25, 0.125},
                                 {0.0625, 0.125, 0.0625}};

    img_holder *blurred_image = (img_holder *) malloc(sizeof(img_holder));
    if (blurred_image == NULL) {
        printf("%s", errmsgs[1]);
        free(image);
        free(expanded_image);
        return 0;
    }
    blurred_image->width = image->width;
    blurred_image->height = image->height;
    blurred_image->channels = image->channels;
    blurred_image->pixels = (unsigned char*) malloc(image->channels * image->height * image->width);
    if(blurred_image->pixels == NULL){
        printf("%s", errmsgs[1]);
        return 0;
    }
    printf("allocated memory for blurred image\n");

    clock_t start = clock();
    blur_image(expanded_image, blurred_image, kernel);
    clock_t end = clock();
    double time = ((double)(end - start) * 1000 / CLOCKS_PER_SEC);
    printf("time: %lf\n", time);
    load_image_to_file(argv[2], blurred_image);
    return 0;
}
