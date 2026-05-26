/* Stub quantum runtime for weavec2 end-to-end tests (link with clang). */
#include <stdint.h>

void qrt_ry(int64_t q, int64_t theta_nr) {
  (void)q;
  (void)theta_nr;
}

void qrt_rz(int64_t q, int64_t phi_nr) {
  (void)q;
  (void)phi_nr;
}

int32_t qrt_measure(int64_t q) {
  (void)q;
  return 0;
}
