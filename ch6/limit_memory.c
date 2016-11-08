// limit_memory.c
//

#include "interpreter.h"

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>

long bytes_alloced = 0;
long max_bytes = 30000;

void *alloc(void *ud,
            void *ptr,
            size_t osize,
            size_t nsize) {

  // Compute the byte change requested. May be negative.
  long num_bytes_to_add = nsize - (ptr ? osize : 0);

  // Reject the change if it would exceed our limit.
  if (bytes_alloced + num_bytes_to_add > max_bytes) {
    errno = ENOMEM;
    return NULL;
  }

  // Otherwise, free or allocate memory as requested.
  bytes_alloced += num_bytes_to_add;
  if (nsize) return realloc(ptr, nsize);
  free(ptr);
  return NULL;
}

void print_status() {
  printf("%ld bytes allocated\n", bytes_alloced);
}

int main() {
  lua_State *L = lua_newstate(alloc, NULL);
  luaL_openlibs(L);

  int keep_going = 1;
  while (keep_going) {
    print_status();
    keep_going = accept_and_run_a_line(L);
  }

  lua_close(L);
  print_status();
  return 0;
}
