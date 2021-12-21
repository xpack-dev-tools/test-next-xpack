/*
 * This file is part of the xPack project (http://xpack.github.io).
 * Copyright (c) 2021 Liviu Ionescu. All rights reserved.
 *
 * This Software is provided under the terms of the MIT License.
 * If a copy of the license was not distributed with this file, it can
 * be obtained from https://opensource.org/licenses/MIT/.
 */

// ----------------------------------------------------------------------------

#include "test-next.h"
#include <iostream>
#include <exception>

void
func(void);

struct MyException : public std::exception {
   const char* what() const throw () {
      return "MyException";
   }
};

int
main (int argc, char* argv[])
{
  std::cout << HELLO_WORLD_MESSAGE << std::endl;

#if defined(DEBUG)
  std::cout << "(in debug mode)" << std::endl;
#else
  std::cout << "(in release mode)" << std::endl;
#endif

#if defined(NDEBUG)
  std::cout << "(no asserts)" << std::endl;
#endif

try {
  func();
} catch(MyException& e) {
  std::cout << e.what() << std::endl;
} catch(std::exception& e) {
  std::cout << "Other" << std::endl;
}

  return 0;
}

void
func(void)
{
  // Do not use new, so the exception will be a local object, not a pointer.
  throw MyException();
}

// ----------------------------------------------------------------------------
