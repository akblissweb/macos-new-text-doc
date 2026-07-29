<?php
declare(strict_types=1);

$pattern = '/^new-text-file-(\d+\.\d+\.\d+)-release\.pkg$/';
$releases = [];

foreach (scandir(__DIR__) ?: [] as $file) {
    if (preg_match($pattern, $file, $match)) {
        $releases[] = ['file' => $file, 'version' => $match[1]];
    }
}

usort($releases, static function (array $a, array $b): int {
    return version_compare($b['version'], $a['version']);
});

if ($releases === []) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'No release found']);
    exit;
}

$latest = $releases[0];
$base = rtrim(dirname($_SERVER['SCRIPT_NAME'] ?? ''), '/');
$url = $base . '/' . rawurlencode($latest['file']);

header('Cache-Control: no-store, max-age=0');
if (($_GET['action'] ?? '') === 'redirect') {
    header('Location: ' . $url, true, 302);
    exit;
}

header('Content-Type: application/json');
echo json_encode([
    'version' => $latest['version'],
    'file' => $latest['file'],
    'url' => $url,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
