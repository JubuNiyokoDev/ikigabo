import {existsSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const engineRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const venvDir = resolve(engineRoot, '.venv');
const pythonBin = resolve(venvDir, 'bin', 'python');
const audioScript = resolve(engineRoot, 'scripts', 'generate-guide-audio.py');

const run = (command, args) => {
  const result = spawnSync(command, args, {
    cwd: engineRoot,
    stdio: 'inherit'
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
};

if (!existsSync(pythonBin)) {
  run('python3', ['-m', 'venv', '.venv']);
}

const edgeCheck = spawnSync(
  pythonBin,
  ['-c', 'import edge_tts'],
  {
    cwd: engineRoot,
    stdio: 'ignore'
  }
);

if (edgeCheck.status !== 0) {
  run(pythonBin, ['-m', 'pip', 'install', '--upgrade', 'pip']);
  run(pythonBin, ['-m', 'pip', 'install', 'edge-tts']);
}

run(pythonBin, [audioScript]);
