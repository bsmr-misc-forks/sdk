// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show
    Future;

import 'dart:io' show
    Directory,
    File,
    FileSystemEntity;

import 'dart:math' show
    min;

import 'package:expect/expect.dart';
import 'package:servicec/compiler.dart' as servicec;
import 'package:servicec/errors.dart' show
    CompilerError,
    compilerErrorTypes;

import 'package:servicec/targets.dart' show
    Target;

import 'scanner_tests.dart' show
    SCANNER_TESTS;

import 'test.dart' show
    Test;

/// Absolute path to the build directory used by test.py.
const String buildDirectory =
    const String.fromEnvironment('test.dart.build-dir');

/// Relative path to the directory containing input files.
const String filesDirectory = "tests/servicec/input_files";

// TODO(zerny): Provide the below constant via configuration from test.py
final String generatedDirectory = '$buildDirectory/generated_servicec_tests';

class FileTest extends Test {
  final Target target;
  final String outputDirectory;

  FileTest(String name, {this.target: Target.ALL})
    : outputDirectory = "$generatedDirectory/$name",
      super(name);

  Future perform() async {
    String input = new File("$filesDirectory/$name.idl").readAsStringSync();
    List<CompilerError> expectedErrors = extractExpectedErrors(input);
    List<CompilerError> compilerErrors =
      (await servicec.compileInput(input, name, outputDirectory)).toList();

    int length = min(expectedErrors.length, compilerErrors.length);
    for (int i = 0; i < length; ++i) {
      Expect.equals(expectedErrors[i], compilerErrors[i]);
    }
    Expect.equals(expectedErrors.length, compilerErrors.length,
                  "Expected a different amount of errors");
    if (compilerErrors.length == 0) {
      try {
        await checkOutputDirectoryStructure(outputDirectory, target);
      } finally {
        nukeDirectory(outputDirectory);
      }
    }
  }

  List<CompilerError> extractExpectedErrors(String input) {
    List<CompilerError> result = <CompilerError>[];

    List<String> lines = input.split("\n");
    for (String line in lines) {
      List<String> split = line.split("//");
      if (split.length > 1) {
        List<String> words = split[1].trim().split(" ");
        if (words.length == 1) {
          addWordIfError(words[0], result);
        }
      }
    }

    return result;
  }

  void addWordIfError(String word, List<CompilerError> errors) {
    CompilerError error = compilerErrorTypes["CompilerError.$word"];
    if (null != error) errors.add(error);
  }
}

// Helpers for Success.

Future checkOutputDirectoryStructure(String outputDirectory, Target target)
    async {
  // If the root out dir does not exist there is no point in checking the
  // children dirs.
  await checkDirectoryExists(outputDirectory);

  if (target.includes(Target.JAVA)) {
    await checkDirectoryExists(outputDirectory + '/java');
  }
  if (target.includes(Target.CC)) {
    await checkDirectoryExists(outputDirectory + '/cc');
  }
}

Future checkDirectoryExists(String dirName) async {
  var dir = new Directory(dirName);
  Expect.isTrue(await dir.exists(), "Directory $dirName does not exist");
}

// TODO(stanm): Move cleanup logic to fletch_tests setup
Future nukeDirectory(String dirName) async {
  var dir = new Directory(dirName);
  await dir.delete(recursive: true);
}

// Test entry point.

typedef Future NoArgFuture();

Future<Map<String, NoArgFuture>> listTests() async {
  var tests = <String, NoArgFuture>{};
  List<FileSystemEntity> files = new Directory(filesDirectory).listSync();
  for (File file in files) {
    String filename = file.path.split("/").last;
    String testname = filename.substring(0, filename.indexOf('.idl'));
    tests['servicec/$testname'] = new FileTest(testname).perform;
  }

  for (Test test in SCANNER_TESTS) {
    tests['servicec/scanner/${test.name}'] = test.perform;
  }
  return tests;
}
