#ifndef AVIASPECTRA_LITE_BRIDGE_H
#define AVIASPECTRA_LITE_BRIDGE_H
void *bs_create_geo(const char *model_path, int *status);
void *bs_create(const char *model_path, int *status);
int bs_predict(void *engine, const float *input, float *output);
void bs_destroy(void *engine);
#endif
