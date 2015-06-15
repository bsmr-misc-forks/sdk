// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:math';

import 'package:expect/expect.dart';
import 'package:http/http.dart';

main() {
  checkIntSequence();
  checkBoolSequence();
}

void checkIntSequence() {
  // Check the sequence of numbers generated by the random generator for a seed
  // doesn't change unintendedly, and it agrees between implementations.

  // This follows the same implementation pattern as the test from dart:math
  // in the Dart SDK, except that the sequence is different and it doesn't
  // test for ArgumentErrors.

  var rnd = new Random(20130307);
  var i = 1;
  Expect.equals(         0, rnd.nextInt(i *= 2));
  Expect.equals(         1, rnd.nextInt(i *= 2));
  Expect.equals(         6, rnd.nextInt(i *= 2));
  Expect.equals(        15, rnd.nextInt(i *= 2));
  Expect.equals(        12, rnd.nextInt(i *= 2));
  Expect.equals(        53, rnd.nextInt(i *= 2));
  Expect.equals(        10, rnd.nextInt(i *= 2));
  Expect.equals(       123, rnd.nextInt(i *= 2));
  Expect.equals(       152, rnd.nextInt(i *= 2));
  Expect.equals(       241, rnd.nextInt(i *= 2));
  Expect.equals(       214, rnd.nextInt(i *= 2));
  Expect.equals(      3927, rnd.nextInt(i *= 2));
  Expect.equals(      2628, rnd.nextInt(i *= 2));
  Expect.equals(      1837, rnd.nextInt(i *= 2));
  Expect.equals(     29794, rnd.nextInt(i *= 2));
  Expect.equals(     39411, rnd.nextInt(i *= 2));
  Expect.equals(    116400, rnd.nextInt(i *= 2));
  Expect.equals(    223529, rnd.nextInt(i *= 2));
  Expect.equals(     29870, rnd.nextInt(i *= 2));
  Expect.equals(    189007, rnd.nextInt(i *= 2));
  Expect.equals(    564700, rnd.nextInt(i *= 2));
  Expect.equals(    814821, rnd.nextInt(i *= 2));
  Expect.equals(   3354042, rnd.nextInt(i *= 2));
  Expect.equals(   1397867, rnd.nextInt(i *= 2));
  Expect.equals(   9419720, rnd.nextInt(i *= 2));
  Expect.equals(  18486369, rnd.nextInt(i *= 2));
  Expect.equals(  39218054, rnd.nextInt(i *= 2));
  Expect.equals(  53660743, rnd.nextInt(i *= 2));
  Expect.equals( 482921588, rnd.nextInt(i *= 2));
  Expect.equals( 629314973, rnd.nextInt(i *= 2));
  Expect.equals( 379435538, rnd.nextInt(i *= 2));
  Expect.equals( 734389731, rnd.nextInt(i *= 2));

  rnd = new Random(6790);
  Expect.approxEquals(0.1388033959, rnd.nextDouble());
  Expect.approxEquals(0.4426140135, rnd.nextDouble());
  Expect.approxEquals(0.3593540924, rnd.nextDouble());
  Expect.approxEquals(0.1773482645, rnd.nextDouble());
}

void checkBoolSequence() {
  // Check the sequence of numbers generated by the random generator for a seed
  // doesn't change unintendedly, and it agrees between implementations.

  var rnd = new Random(2132);
  Expect.equals(false, rnd.nextBool());
  Expect.equals(true,  rnd.nextBool());
  Expect.equals(false, rnd.nextBool());
  Expect.equals(false, rnd.nextBool());
  Expect.equals(false, rnd.nextBool());
  Expect.equals(true,  rnd.nextBool());
  Expect.equals(false, rnd.nextBool());
  Expect.equals(false, rnd.nextBool());
  Expect.equals(true, rnd.nextBool());
  Expect.equals(true, rnd.nextBool());
}
