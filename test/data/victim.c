#include <stdio.h>

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  printf("%p\n", __builtin_return_address(0));
  scanf("%c");
  return 0;
}
