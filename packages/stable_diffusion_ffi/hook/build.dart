/// Native Assets build hook — compiles stable-diffusion.cpp into a shared
/// library (.dylib/.so/.dll) bundled with the Flutter app.
///
/// Prerequisites: cmake must be on PATH.
/// Metal GPU acceleration is enabled automatically on macOS/iOS.
library;

import 'dart:io';

import 'package:native_assets_cli/code_assets.dart';

void main(List<String> args) async {
  await build(args, _build);
}

Future<void> _build(BuildConfig config, BuildOutputBuilder output) async {
  final targetOS = config.codeConfig.targetOS;
  final libFile = config.outputDirectory.resolve(_libName(targetOS));

  final sdRoot =
      config.packageRoot.resolve('src/stable-diffusion.cpp/').toFilePath();
  final buildDir =
      config.outputDirectory.resolve('sd_cmake_build/').toFilePath();

  Directory(buildDir).createSync(recursive: true);

  // ── cmake configure ────────────────────────────────────────────────────────
  final configureArgs = [
    '-S', sdRoot,
    '-B', buildDir,
    '-DBUILD_SHARED_LIBS=ON',
    '-DCMAKE_BUILD_TYPE=Release',
    '-DSD_BUILD_EXAMPLES=OFF',
  ];
  if (targetOS == OS.macOS || targetOS == OS.iOS) {
    configureArgs.add('-DGGML_METAL=ON');
  }
  await _run('cmake', configureArgs);

  // ── cmake build ───────────────────────────────────────────────────────────
  await _run('cmake', [
    '--build', buildDir,
    '--config', 'Release',
    '--parallel',
  ]);

  // Copy the built library to the output directory
  final builtLib = File('$buildDir/${_libName(targetOS)}');
  await builtLib.copy(libFile.toFilePath());

  output.addDependencies([
    config.packageRoot.resolve('src/stable-diffusion.cpp/CMakeLists.txt'),
    config.packageRoot.resolve('src/stable-diffusion.cpp/stable-diffusion.h'),
  ]);

  output.codeAssets.add(
    CodeAsset(
      package: 'stable_diffusion_ffi',
      name: 'libstable_diffusion',
      linkMode: DynamicLoadingBundled(),
      os: targetOS,
      architecture: config.codeConfig.targetArchitecture,
      file: libFile,
    ),
  );
}

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
