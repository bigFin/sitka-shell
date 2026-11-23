import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const checker = fileURLToPath(new URL('../scripts/size/check.mjs', import.meta.url));

function fixture(t) {
    const cwd = mkdtempSync(join(tmpdir(), 'sitka-source-size-'));
    t.after(() => rmSync(cwd, { recursive: true, force: true }));
    const git = (...args) => execFileSync('git', ['-c', 'core.hooksPath=/dev/null',
        '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
        '-c', 'commit.gpgsign=false', ...args], { cwd });
    git('init', '--quiet');
    return {
        cwd, git,
        write(name, data) {
            const path = join(cwd, name);
            mkdirSync(dirname(path), { recursive: true });
            writeFileSync(path, data);
        },
        commit() { git('add', '.'); git('commit', '-qm', 'fixture'); },
        check(...names) { return spawnSync(process.execPath, [checker, ...names], { cwd, encoding: 'utf8' }); }
    };
}

test('allows 500 physical lines and rejects the 501st, including an unterminated line', t => {
    const f = fixture(t);
    f.write('a.qml', 'line\r\n'.repeat(500));
    assert.equal(f.check('a.qml').status, 0);
    f.write('a.qml', 'line\r\n'.repeat(500) + 'last');
    const result = f.check('a.qml');
    assert.equal(result.status, 1);
    assert.match(result.stderr, /a\.qml.*501.*500/);
});

test('checks source families, but not documentation or the two named upstream bundles', t => {
    const f = fixture(t);
    const sources = ['many words.js', 'x.mjs', 'x.cpp', 'x.hpp', 'x.frag', 'x.vert', 'x.glsl', 'x.nix', 'x.sh', 'x.py', 'CMakeLists.txt'];
    const exempt = ['README.md', 'utils/scripts/fzf.js', 'utils/scripts/fuzzysort.js'];
    for (const name of [...sources, ...exempt]) f.write(name, '\n'.repeat(501));
    assert.equal(f.check(...exempt).status, 0);
    const result = f.check(...sources);
    assert.equal(result.status, 1);
    for (const name of sources) assert.ok(result.stderr.includes(name), result.stderr);
});

test('legacy files may shrink but not regain lines or exceed their original ceiling', t => {
    const f = fixture(t);
    const name = 'services/SysMonitorService.qml';
    f.write(name, '\n'.repeat(938));
    f.commit();
    assert.equal(f.check(name).status, 0);
    f.write(name, '\n'.repeat(939));
    assert.match(f.check(name).stderr, /939.*938/);
    f.write(name, '\n'.repeat(550));
    assert.equal(f.check(name).status, 0);
    f.commit();
    f.write(name, '\n'.repeat(551));
    assert.match(f.check(name).stderr, /551.*550/);
    f.write(name, '\n'.repeat(499));
    f.commit();
    f.write(name, '\n'.repeat(500));
    assert.equal(f.check(name).status, 0);
    f.write(name, '\n'.repeat(501));
    assert.match(f.check(name).stderr, /501.*500/);
});

test('real hook uses the index for commits and the working tree for --all-files', t => {
    if (spawnSync('pre-commit', ['--version']).error?.code === 'ENOENT') {
        return t.skip('run in nix develop for pre-commit');
    }
    const f = fixture(t);
    f.write('.pre-commit-config.yaml', readFileSync(new URL('../.pre-commit-config.yaml', import.meta.url)));
    f.write('scripts/size/check.mjs', readFileSync(checker));
    f.commit();
    const run = (...args) => spawnSync('pre-commit', ['run', '--color=never', ...args], {
        cwd: f.cwd, encoding: 'utf8', env: { ...process.env, PRE_COMMIT_HOME: join(f.cwd, '.git/pc-cache') }
    });
    const path = 'oversized probe.qml';
    f.write(path, '\n'.repeat(501));
    f.git('add', path);
    f.write(path, 'small\n');
    const staged = run();
    assert.equal(staged.status, 1, staged.stdout + staged.stderr);
    assert.match(staged.stdout, /oversized probe\.qml: 501 lines \(limit 500\)/);
    assert.equal(readFileSync(join(f.cwd, path), 'utf8'), 'small\n');
    f.git('add', path);
    f.write(path, '\n'.repeat(501));
    const unstaged = run();
    assert.equal(unstaged.status, 0, unstaged.stdout + unstaged.stderr);
    const all = run('--all-files');
    assert.equal(all.status, 1, all.stdout + all.stderr);
    assert.match(all.stdout, /oversized probe\.qml: 501 lines \(limit 500\)/);
});
