/// Native Assets build hook — compiles stable-diffusion.cpp into a shared
/// library (.dylib/.so/.dll) bundled with the Flutter app.
///
/// Prerequisites: cmake must be on PATH.
/// Metal GPU acceleration is enabled automatically on macOS/iOS.
library;

import 'dart:io';

import 'package:native_assets_cli/code_assets.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

void main(List<String> args) async {
  await build(args, _build);
}

Future<void> _build(BuildInput input, BuildOutputBuilder output) async {
  if (!input.config.buildCodeAssets) return;

  final targetOS = input.config.code.targetOS;
  final libFile = input.outputDirectory.resolve(_libName(targetOS));

  final sdRoot =
      input.packageRoot.resolve('src/stable-diffusion.cpp/').toFilePath();
  final buildDir =
      input.outputDirectory.resolve('sd_cmake_build/').toFilePath();

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
  }
  await _run('cmake', configureArgs);

  // ── cmake build ───────────────────────────────────────────────────────────
  await _run('cmake', [
    '--build', buildDir,
    '--config', 'Release',
    '--parallel',
  ]);

  // Copy the built library to the output directory (cmake puts it in bin/)
  final builtLib = File('${buildDir}bin/${_libName(targetOS)}');
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
