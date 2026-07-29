#!/usr/bin/env node

/**
 * Build, Developer ID sign, notarize, staple, verify, and FTPS-upload the
 * universal New Text File installer.
 *
 *   npm run deploy
 *   npm run deploy -- --no-upload
 *   npm run upload
 *
 * Credentials and release-account settings are loaded from .env.
 */

const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const BUILDS_DIR = path.join(ROOT, 'Builds');
const RELEASES_DIR = path.join(ROOT, 'releases');
const SOURCE_APP = path.join(
  ROOT,
  '.build',
  'DerivedData',
  'Build',
  'Products',
  'Release',
  'New Text File.app'
);

function loadEnv() {
  const envPath = process.env.ENV_FILE
    ? path.resolve(process.env.ENV_FILE)
    : path.join(ROOT, '.env');
  if (!fs.existsSync(envPath)) return;

  for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (match && (!(match[1] in process.env) || process.env[match[1]] === '')) {
      process.env[match[1]] = match[2].replace(/^["']|["']$/g, '');
    }
  }
}

function version() {
  const value = fs.readFileSync(path.join(ROOT, 'VERSION'), 'utf8').trim();
  if (!/^\d+\.\d+\.\d+$/.test(value)) {
    throw new Error(`VERSION must contain x.y.z; got ${value}`);
  }
  return value;
}

function commandText(command, args) {
  return [command, ...args.map(arg => (
    /\s/.test(arg) ? JSON.stringify(arg) : arg
  ))].join(' ');
}

function runChecked(command, args, options = {}) {
  console.log(`   $ ${commandText(command, args)}`);
  execFileSync(command, args, { stdio: 'inherit', ...options });
}

function runCaptured(command, args, options = {}) {
  console.log(`   $ ${commandText(command, args)}`);
  const result = spawnSync(command, args, { encoding: 'utf8', ...options });
  if (result.error) throw result.error;
  const output = `${result.stdout || ''}${result.stderr || ''}`;
  if (result.status !== 0) {
    process.stdout.write(output);
    throw new Error(`${command} exited with status ${result.status}`);
  }
  return output;
}

function assertReleaseEnvironment() {
  if (process.platform !== 'darwin') {
    throw new Error('macOS releases must be built on macOS');
  }

  const requiredUser = process.env.MAC_RELEASE_USER || 'cutecat';
  const currentUser = os.userInfo().username;
  if (currentUser !== requiredUser) {
    throw new Error(
      `Release signing must run as ${requiredUser}; current user is ${currentUser}`
    );
  }

  if (!process.env.APPLE_KEYCHAIN_PROFILE) {
    throw new Error('APPLE_KEYCHAIN_PROFILE is required for notarization');
  }
}

function appExecutables() {
  return {
    app: path.join(SOURCE_APP, 'Contents', 'MacOS', 'New Text File'),
    extension: path.join(
      SOURCE_APP,
      'Contents',
      'PlugIns',
      'NewTextFileFinderSync.appex',
      'Contents',
      'MacOS',
      'NewTextFileFinderSync'
    ),
  };
}

function verifyUniversalApplication() {
  for (const [label, executable] of Object.entries(appExecutables())) {
    runChecked('lipo', [executable, '-verify_arch', 'arm64', 'x86_64']);
    console.log(`✅ Universal ${label} binary verified`);
  }

  runChecked('codesign', ['--verify', '--deep', '--strict', '--verbose=2', SOURCE_APP]);
  const signature = runCaptured('codesign', ['--display', '--verbose=4', SOURCE_APP]);
  for (const expected of [
    'Authority=Developer ID Application:',
    'TeamIdentifier=',
    'Runtime Version=',
  ]) {
    if (!signature.includes(expected)) {
      throw new Error(`Application signature is missing ${expected}`);
    }
  }
}

function verifyReleasePackage(file) {
  console.log(`🔍 Verifying ${path.basename(file)}`);
  const signature = runCaptured('pkgutil', ['--check-signature', file]);
  if (!signature.includes('Developer ID Installer:')) {
    throw new Error('Installer is not signed with a Developer ID Installer identity');
  }
  runChecked('xcrun', ['stapler', 'validate', file]);
  runChecked('spctl', ['--assess', '--verbose=4', '--type', 'install', file]);
}

function buildRelease() {
  const releaseVersion = version();
  const buildNumber = new Date()
    .toISOString()
    .replace(/\D/g, '')
    .slice(0, 12);

  console.log(`🔨 Building universal New Text File ${releaseVersion}`);
  runChecked(path.join(ROOT, 'Scripts', 'build-package.sh'), [], {
    cwd: ROOT,
    env: {
      ...process.env,
      BUILD_NUMBER: buildNumber,
      REQUIRE_RELEASE_SIGNING: '1',
      NOTARY_PROFILE: process.env.APPLE_KEYCHAIN_PROFILE,
    },
  });

  verifyUniversalApplication();

  const builtPackage = path.join(
    BUILDS_DIR,
    `New Text File Installer ${releaseVersion}.pkg`
  );
  if (!fs.existsSync(builtPackage)) {
    throw new Error(`Build did not produce ${builtPackage}`);
  }

  fs.mkdirSync(RELEASES_DIR, { recursive: true });
  const releasePackage = path.join(
    RELEASES_DIR,
    `new-text-file-${releaseVersion}-release.pkg`
  );
  fs.copyFileSync(builtPackage, releasePackage);
  verifyReleasePackage(releasePackage);
  return releasePackage;
}

function existingRelease() {
  const file = path.join(
    RELEASES_DIR,
    `new-text-file-${version()}-release.pkg`
  );
  if (!fs.existsSync(file)) {
    throw new Error(`Existing release not found: ${file}`);
  }
  verifyReleasePackage(file);
  return file;
}

async function upload(files) {
  const { Client } = require('basic-ftp');
  const host = process.env.FTP_HOST || 'ftp.area90.com';
  const user = process.env.FTP_USER;
  const password = process.env.FTP_PASS;
  const port = Number.parseInt(process.env.FTP_PORT || '21', 10);
  const remoteDir = process.env.FTP_REMOTE_DIR || 'new-text-file';
  const publicBase = (
    process.env.PUBLIC_BASE_URL ||
    'https://area90.com/releases/new-text-file'
  ).replace(/\/$/, '');

  if (!user || !password) {
    throw new Error('FTP_USER and FTP_PASS are required for upload');
  }

  const client = new Client();
  try {
    console.log(`🔌 Connecting to ${host}:${port} over FTPS`);
    await client.access({
      host,
      port,
      user,
      password,
      secure: true,
      secureOptions: { rejectUnauthorized: false },
    });
    await client.ensureDir(remoteDir);
    console.log(`📁 Remote directory: ${await client.pwd()}`);

    for (const file of files) {
      const fileName = path.basename(file);
      console.log(`📤 Uploading ${fileName}`);
      await client.uploadFrom(file, fileName);

      const localSize = fs.statSync(file).size;
      const remoteSize = await client.size(fileName);
      if (remoteSize !== localSize) {
        throw new Error(
          `Remote size mismatch for ${fileName}: ${remoteSize} != ${localSize}`
        );
      }
      console.log(`✅ Remote size verified: ${remoteSize} bytes`);
      console.log(`🌐 ${publicBase}/${encodeURIComponent(fileName)}`);
    }

    const latestScript = path.join(__dirname, 'latest-release.php');
    await client.uploadFrom(latestScript, 'latest-release.php');
    console.log(`🌐 Latest: ${publicBase}/latest-release.php?action=redirect`);
  } finally {
    client.close();
  }
}

function elapsed(startedAt) {
  const seconds = Math.round((Date.now() - startedAt) / 1000);
  return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
}

async function main() {
  const startedAt = Date.now();
  loadEnv();
  assertReleaseEnvironment();

  const uploadExisting = process.argv.includes('--upload-existing');
  const noUpload = process.argv.includes('--no-upload');
  const artifact = uploadExisting ? existingRelease() : buildRelease();

  const size = fs.statSync(artifact).size;
  console.log(`📦 ${path.basename(artifact)} (${size} bytes)`);

  if (noUpload) {
    console.log('⏭️  --no-upload: build and verification complete');
  } else {
    await upload([artifact]);
  }
  console.log(`⏱️  Total: ${elapsed(startedAt)}`);
}

main().catch(error => {
  console.error(`❌ ${error.message}`);
  process.exitCode = 1;
});
