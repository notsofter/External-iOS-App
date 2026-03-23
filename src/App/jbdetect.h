#include <sys/types.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <string.h>

int detect_statfs() {
    int jailbreak_detected = 0;
    int filesystem_count = getfsstat(NULL, 0, 0);
    if (filesystem_count == -1) {
        return 1;
    } else {
        struct statfs *filesystems = (struct statfs *)malloc(sizeof(struct statfs) * filesystem_count);
        if (filesystems) {
            int mounted_filesystems = getfsstat(filesystems, sizeof(struct statfs) * filesystem_count, MNT_NOWAIT);
            if (mounted_filesystems == -1) {
                free(filesystems);
                return 3;
            } else {
                bool catched_apple_os_update = false;
                for (int i = 0; i < mounted_filesystems; ++i) {
                    if ((filesystems[i].f_flags & MNT_UNION) != 0)
                        jailbreak_detected = 4;

                    if (!strncmp(filesystems[i].f_mntfromname, "com.apple.os.update", 19))
                        catched_apple_os_update = true;
                }
                free(filesystems);
                return jailbreak_detected & !catched_apple_os_update;
            }
        } else {
            return 2;
        }
    }
}

int detect_access() {
    return (access("/var/jb", 0) == 0) ? 4 : 0;
}

int detect_access2() {
    return (access("/usr/lib/systemhook.dylib", 0) == 0) ? 4 : 0;
}

int detect_jailbreak() {

    int ret = detect_access();
    if (ret)
        return ret;

    ret = detect_access2();
    if (ret)
        return ret;

    ret = detect_statfs();
    if (ret)
        return ret;

    return 0;
}