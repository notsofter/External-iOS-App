#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>

bool krw_init(const char *flavor);
bool krw_deinit(void);

bool krw_init_physpuppet(void);
bool krw_init_smith(void);
bool krw_init_landa(void);

#ifdef __cplusplus
}
#endif
