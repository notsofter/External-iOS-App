#ifndef PHYSRW_PTE_H
#define PHYSRW_PTE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>

int physrw_pte_handoff(pid_t pid);
int libjailbreak_physrw_pte_init(bool receivedHandoff);

#ifdef __cplusplus
}
#endif

#endif
