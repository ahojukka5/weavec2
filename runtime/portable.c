// SPDX-License-Identifier: Apache-2.0
//
// Tiny portability shim for POSIX flag constants that differ across
// platforms. weavec2's WIR source previously baked open() flag values
// in as integer literals — but those values are platform-specific
// (e.g. O_WRONLY|O_CREAT|O_TRUNC = 1537 on macOS, 577 on Linux). The
// WIR layer doesn't know about <fcntl.h>, so we wrap the call here in
// C using the OS-native constants.

#include <fcntl.h>
#include <sys/stat.h>

// Open a file for writing, truncating if it exists, creating if it
// doesn't. Returns the file descriptor, or -1 on failure. The mode
// parameter is a POSIX mode_t value (e.g. 0644).
int weave_rt_open_write_trunc(const char *path, int mode) {
    return open(path, O_WRONLY | O_CREAT | O_TRUNC, mode);
}
