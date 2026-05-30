/// Native Assets build hook — compiles stable-diffusion.cpp into a shared
/// library (.dylib/.so/.dll) bundled with the Flutter app.
///
/// Prerequisites: cmake must be on PATH.
/// Metal GPU acceleration is enabled automatically on macOS/iOS.
library;

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, _build);
}

Future<void> _build(BuildInput input, BuildOutputBuilder output) async {
  if (!input.config.buildCodeAssets) return;

  final targetOS = input.config.code.targetOS;
  final targetArch = input.config.code.targetArchitecture;
  final libFile = input.outputDirectory.resolve(_libName(targetOS));

  final sdRoot =
      input.packageRoot.resolve('src/stable-diffusion.cpp/').toFilePath();
  // Include architecture in the build dir to avoid conflicts when Flutter
  // builds multiple architectures (e.g. arm64 + x86_64 for universal binary).
  final buildDir = input.packageRoot
      .resolve('.sd_cmake_build/${targetOS.name}-${targetArch.name}/')
      .toFilePath();

  Directory(buildDir).createSync(recursive: true);

  // ── cmake configure ────────────────────────────────────────────────────────
  final configureArgs = [
    '-S', sdRoot,
    '-B', buildDir,
    '-DSD_BUILD_SHARED_LIBS=ON',
    '-DCMAKE_BUILD_TYPE=Release',
    '-DSD_BUILD_EXAMPLES=OFF',
  ];
  if (targetOS == OS.macOS || targetOS == OS.iOS) {
    configureArgs.add('-DGGML_METAL=ON');
    final cmakeArch = _cmakeArch(targetArch);
    configureArgs.add('-DCMAKE_OSX_ARCHITECTURES=$cmakeArch');
    // CMAKE_SYSTEM_PROCESSOR must match the target arch so ggml selects the
    // correct CPU feature flags (e.g. prevents ARM flags when targeting x86_64).
    configureArgs.add('-DCMAKE_SYSTEM_PROCESSOR=$cmakeArch');
    // When cross-compiling for x86_64 on an arm64 host, -mcpu=native resolves
    // to an ARM CPU name which clang rejects for x86_64 targets.
    if (targetArch != Architecture.arm64) {
      configureArgs.add('-DGGML_NATIVE=OFF');
    }
  }
  await _run('cmake', configureArgs);

  // ── cmake build ───────────────────────────────────────────────────────────
  await _run('cmake', [
    '--build', buildDir,
    '--config', 'Release',
    '--parallel',
  ]);

  // Locate built library — cmake may place it in bin/ or directly in buildDir
  final builtLibInBin = File('${buildDir}bin/${_libName(targetOS)}');
  final builtLib = builtLibInBin.existsSync()
      ? builtLibInBin
      : File('$buildDir${_libName(targetOS)}');
  await builtLib.copy(libFile.toFilePath());

  output.addDependencies([
    input.packageRoot.resolve('src/stable-diffusion.cpp/CMakeLists.txt'),
    input.packageRoot.resolve('src/stable-diffusion.cpp/stable-diffusion.h'),
  ]);

  output.assets.code.add(
    CodeAsset(
      package: 'stable_diffusion_ffi',
      name: 'libstable_diffusion',
      linkMode: DynamicLoadingBundled(),
      file: libFile,
    ),
  );
}

String _cmakeArch(Architecture arch) => switch (arch) {
      Architecture.arm64 => 'arm64',
      Architecture.x64 => 'x86_64',
      _ => throw UnsupportedError('Unsupported architecture: $arch'),
    };

String _libName(OS os) => switch (os) {
      OS.macOS => 'libstable-diffusion.dylib',
      OS.linux => 'libstable-diffusion.so',
      OS.windows => 'stable-diffusion.dll',
      OS.iOS => 'libstable-diffusion.dylib',
      OS.android => 'libstable-diffusion.so',
      _ => throw UnsupportedError('Unsupported OS: $os'),
    };

Future<void> _run(String exe, List<String> args) async {
  stdout.writeln('[stable_diffusion_ffi] $exe ${args.join(' ')}');
  final result = await Process.run(exe, args, runInShell: true);
  if (result.stdout.toString().isNotEmpty) stdout.write(result.stdout);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw ProcessException(
        exe, args, result.stderr.toString(), result.exitCode);
  }
}
