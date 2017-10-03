#include <stdio.h>
#include <stdlib.h>
char s[101];
void func() {
  static int test = 0;
  test++;
  puts("In func:");
  printf("test = %d\n", test);
}
int main() {
  fgets(s, 100, stdin);
  printf("%s", s);
  int n;
  scanf("%d", &n);
  while(n--) {
    func();
  }
  return 0;
}
