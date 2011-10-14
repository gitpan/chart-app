#include <stdio.h>
#include <locale.h>
int
main (void)
{
  char *l;
  struct lconv* lconv;
  
  l = setlocale (LC_ALL, "");
  printf ("%s\n", l);

  l = setlocale (LC_MONETARY, "");
  printf ("%s\n", l);

  l = setlocale (LC_NUMERIC, "C");
  printf ("%s\n", l);

  lconv = localeconv();
  printf ("dec  '%s'\n", lconv->decimal_point);
  printf ("thou '%s'\n", lconv->thousands_sep);
  return 0;
}
