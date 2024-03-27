#include <assert.h>

int returnSameInt(int n) {
    return n;
}

int main(void) {
    int n = 42;
    assert(returnSameInt(n) == n+1);
    assert(returnSameInt(n) == n);
    return 0;
}