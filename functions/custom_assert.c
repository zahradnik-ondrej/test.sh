#include <stdio.h>

#define __RED "\033[1;35m"
#define __GREEN "\033[1;32m"
#define __GRAY "\033[0;90m"
#define __NONE "\033[0m"

#undef assert

void custom_assert_fail(const char* assertion, const char* file, unsigned int line, const char* function) {
    fprintf(stderr, __RED "\u25bc Assertion failed: \u25bc\n" __NONE "%s\n\n", assertion);
}

void custom_assert_pass(const char* assertion, const char* file, unsigned int line, const char* function) {
    fprintf(stderr, __GREEN "\u2714 OK: " __GRAY "%s\n\n" __NONE, assertion);
}

#define assert(expr) \
    ((expr) \
     ? custom_assert_pass(#expr, __FILE__, __LINE__, __func__) \
     : custom_assert_fail(#expr, __FILE__, __LINE__, __func__))