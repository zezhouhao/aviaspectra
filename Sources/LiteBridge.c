#include "LiteBridge.h"
#include <stdlib.h>
#include <string.h>
#include "litert/c/litert_environment.h"
#include "litert/c/litert_model.h"
#include "litert/c/litert_compiled_model.h"
#include "litert/c/litert_tensor_buffer.h"
#include "litert/c/litert_options.h"

typedef struct {
 int inputCount;
 LiteRtEnvironment env;
 LiteRtModel model;
 LiteRtOptions options;
 LiteRtCompiledModel compiled;
 LiteRtTensorBuffer input, output;
} BirdEngine;
void bs_destroy(void *ptr) {
 BirdEngine *e=ptr;if(!e)return;
 if(e->input)LiteRtDestroyTensorBuffer(e->input);
 if(e->output)LiteRtDestroyTensorBuffer(e->output);
 if(e->compiled)LiteRtDestroyCompiledModel(e->compiled);
 if(e->options)LiteRtDestroyOptions(e->options);
 if(e->model)LiteRtDestroyModel(e->model);
 if(e->env)LiteRtDestroyEnvironment(e->env);
 free(e);
}
#define CHECK(expr) do {int s=(expr);if(s){*status=s;bs_destroy(e);return NULL;}}while(0)
static void *bs_create_sized(const char *path,int inputCount,int *status) {
 BirdEngine *e=calloc(1,sizeof(BirdEngine));if(!e){*status=-1;return NULL;}
 e->inputCount=inputCount;
 CHECK(LiteRtCreateEnvironment(0,NULL,&e->env));
 CHECK(LiteRtCreateModelFromFile(e->env,path,&e->model));
 CHECK(LiteRtCreateOptions(&e->options));
 CHECK(LiteRtSetOptionsHardwareAccelerators(e->options,kLiteRtHwAcceleratorCpu));
 CHECK(LiteRtCreateCompiledModel(e->env,e->model,e->options,&e->compiled));
 LiteRtSignature sig;LiteRtTensor tensor;LiteRtRankedTensorType type;
 LiteRtTensorBufferRequirements req;
 CHECK(LiteRtGetModelSignature(e->model,0,&sig));
 CHECK(LiteRtGetSignatureInputTensorByIndex(sig,0,&tensor));
 CHECK(LiteRtGetRankedTensorType(tensor,&type));
 if(type.layout.rank==2 && type.layout.dimensions[0]==-1)type.layout.dimensions[0]=1;
 if(type.element_type!=kLiteRtElementTypeFloat32 || type.layout.rank!=2 || type.layout.dimensions[0]!=1 || type.layout.dimensions[1]!=inputCount){*status=-2;bs_destroy(e);return NULL;}
 CHECK(LiteRtGetCompiledModelInputBufferRequirements(e->compiled,0,0,&req));
 CHECK(LiteRtCreateManagedTensorBufferFromRequirements(e->env,&type,req,&e->input));
 CHECK(LiteRtGetSignatureOutputTensorByIndex(sig,0,&tensor));
 CHECK(LiteRtGetRankedTensorType(tensor,&type));
 if(type.layout.rank==2 && type.layout.dimensions[0]==-1)type.layout.dimensions[0]=1;
 if(type.element_type!=kLiteRtElementTypeFloat32 || type.layout.rank!=2 || type.layout.dimensions[0]!=1 || type.layout.dimensions[1]!=6522){*status=-3;bs_destroy(e);return NULL;}
 CHECK(LiteRtGetCompiledModelOutputBufferRequirements(e->compiled,0,0,&req));
 CHECK(LiteRtCreateManagedTensorBufferFromRequirements(e->env,&type,req,&e->output));
 *status=0;return e;
}
void *bs_create(const char *path,int *status){return bs_create_sized(path,144000,status);}
void *bs_create_geo(const char *path,int *status){return bs_create_sized(path,3,status);}
int bs_predict(void *ptr,const float *input,float *output) {
 BirdEngine *e=ptr;void *data;int s;
 s=LiteRtLockTensorBuffer(e->input,&data,kLiteRtTensorBufferLockModeWrite);if(s)return s;
 memcpy(data,input,e->inputCount*sizeof(float));
 s=LiteRtUnlockTensorBuffer(e->input);if(s)return s;
 s=LiteRtRunCompiledModel(e->compiled,0,1,&e->input,1,&e->output);if(s)return s;
 s=LiteRtLockTensorBuffer(e->output,&data,kLiteRtTensorBufferLockModeRead);if(s)return s;
 memcpy(output,data,6522*sizeof(float));
 return LiteRtUnlockTensorBuffer(e->output);
}
