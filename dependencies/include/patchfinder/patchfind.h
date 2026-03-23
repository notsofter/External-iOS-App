#ifndef patchfind_h
#define patchfind_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <xpf/xpf.h>

bool initialise_kernel_info(const char *kernelPath, bool iOS14);

#ifdef __cplusplus
}
#endif


#endif /* patchfind_h */