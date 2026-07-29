#!/usr/bin/env node

/**
 * Publish the already signed, notarized, and stapled current-version package
 * to GitHub Releases. The local release build remains responsible for Apple
 * signing so private certificate material never needs to leave the Mac.
 *
 *   npm run release:github
 *   npm run release:github -- --dry-run
 */

const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const dryRun = process.argv.includes('--dry-run');

function version() {
  const canonical = fs.readFileSync(path.join(ROOT, 'VERSION'), 'utf8').trim();
  const packageVersion = JSON.parse(
    fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8')
  ).version;
  const lockVersion = JSON.parse(
    fs.readFileSync(path.join(ROOT, 'package-lock.json'), 'utf8')
  ).packages[''].version;

  if (!/^\d+\.\d+\.\d+$/.test(canonical)) {
    throw new Error(`VERSION must contain x.y.z; got ${canonical}`);
  }
  if (canonical !== packageVersion || canonical !== lockVersion) {
    throw new Error(
      `Version files differ: VERSION=${canonical}, package.json=${packageVersion}, ` +
      `package-lock.json=${lockVersion}`
    );
  }
  return canonical;
}

function run(command, args, options = {}) {
  console.log(`   $ ${[command, ...args].map(value => (
    /\s/.test(value) ? JSON.stringify(value) : value
  )).join(' ')}`);
  return execFileSync(command, args, { stdio: 'inherit', cwd: ROOT, ...options });
}

function status(command, args) {
  return spawnSync(command, args, { cwd: ROOT, stdio: 'ignore' }).status;
}

function ensureReleaseSourceIsPublished() {
  const dirty = execFileSync('git', ['status', '--porcelain'], {
    cwd: ROOT,
    encoding: 'utf8',
  }).trim();
  if (dirty) {
    throw new Error(
      'Commit the release source before publishing; the working tree is not clean.'
    );
  }

  const head = execFileSync('git', ['rev-parse', 'HEAD'], {
    cwd: ROOT,
    encoding: 'utf8',
  }).trim();
  const remoteBranches = execFileSync(
    'git',
    ['branch', '-r', '--contains', head],
    { cwd: ROOT, encoding: 'utf8' }
  ).trim();
  if (!remoteBranches) {
    throw new Error('Push the release commit before publishing it.');
  }
  return head;
}

function verifyPackage(file) {
  run('pkgutil', ['--check-signature', file]);
  run('xcrun', ['stapler', 'validate', file]);
  run('spctl', ['--assess', '--verbose=4', '--type', 'install', file]);
}

function writeChecksum(file) {
  const digest = crypto
    .createHash('sha256')
    .update(fs.readFileSync(file))
    .digest('hex');
  const checksum = `${file}.sha256`;
  fs.writeFileSync(checksum, `${digest}  ${path.basename(file)}\n`);
  return checksum;
}

function main() {
  const releaseVersion = version();
  const tag = `v${releaseVersion}`;
  const artifact = path.join(
    ROOT,
    'releases',
    `new-text-file-${releaseVersion}-release.pkg`
  );
  if (!fs.existsSync(artifact)) {
    throw new Error(`Release package not found: ${artifact}`);
  }

  verifyPackage(artifact);

  if (dryRun) {
    console.log(`✅ Dry run: ${tag} is ready for GitHub Releases.`);
    return;
  }

  const head = ensureReleaseSourceIsPublished();
  run('gh', ['auth', 'status']);
  const checksum = writeChecksum(artifact);

  if (status('gh', ['release', 'view', tag]) === 0) {
    run('gh', ['release', 'upload', tag, artifact, checksum, '--clobber']);
    run('gh', ['release', 'edit', tag, '--title', `New Text File ${releaseVersion}`, '--latest']);
  } else {
    run('gh', [
      'release',
      'create',
      tag,
      artifact,
      checksum,
      '--target',
      head,
      '--title',
      `New Text File ${releaseVersion}`,
      '--generate-notes',
      '--latest',
    ]);
  }

  console.log(`✅ Published GitHub Release ${tag}`);
}

try {
  main();
} catch (error) {
  console.error(`❌ ${error.message}`);
  process.exitCode = 1;
}
