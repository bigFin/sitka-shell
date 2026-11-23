// pre-commit supplies regular files from the staged snapshot (or working
// tree for --all-files); do not re-enumerate files or reread the Git index.
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

const limit = 500;
const source = /\.(qml|[cm]?[jt]sx?|c|cc|cpp|cxx|h|hh|hpp|hxx|glsl|vert|frag|comp|nix|sh|bash|py|cmake)$/i;
// These upstream bundles carry their own licenses; don't split them locally.
const upstream = new Set(['utils/scripts/fzf.js', 'utils/scripts/fuzzysort.js']);

// The existing first-party files above the limit at 30a0b99c9. Keep these
// ceilings only to allow incremental extraction instead of a mass rewrite.
// HEAD tightens each ceiling automatically as reductions land. No new entries.
const legacy = new Map([
    ['modules/controlcenter/bluetooth/Details.qml', 662],
    ['modules/controlcenter/bluetooth/Settings.qml', 538],
    ['modules/dashboard/Media.qml', 638],
    ['modules/notifications/Notification.qml', 523],
    ['modules/windowinfo/ProcessList/PerformanceTab.qml', 601],
    ['services/Colours.qml', 529],
    ['services/Niri.qml', 610],
    ['services/SysMonitorService.qml', 938],
    ['services/WMStateMachine.qml', 560],
]);

function lines(bytes) {
    let count = 0;
    for (const byte of bytes) if (byte === 10) ++count;
    return count + (bytes.length > 0 && bytes.at(-1) !== 10 ? 1 : 0);
}

for (const path of process.argv.slice(2)) {
    if (upstream.has(path) || (!source.test(path) && basename(path) !== 'CMakeLists.txt')) continue;
    const count = lines(readFileSync(path));
    if (count <= limit) continue;
    let ceiling = limit;
    if (legacy.has(path)) {
        const previous = spawnSync('git', ['cat-file', 'blob', `HEAD:${path}`]);
        // A deleted legacy file recreated under its old name gets no exception.
        if (previous.status === 0) ceiling = Math.max(limit, Math.min(legacy.get(path), lines(previous.stdout)));
    }
    if (count > ceiling) {
        console.error(`${path}: ${count} lines (limit ${ceiling}). Split the file before committing.`);
        process.exitCode = 1;
    }
}
