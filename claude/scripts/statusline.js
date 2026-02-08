// windows statusline for claude code
// reads context json from stdin, shows: progress bar | jj bookmark | description

let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const j = JSON.parse(data);
    const p = Math.round(j.context_window?.remaining_percentage ?? 100);
    const f = Math.floor(p / 10);
    const e = 10 - f;
    const color = p > 50 ? '\x1b[32m' : p >= 20 ? '\x1b[33m' : '\x1b[31m';
    const bar = color + '\u2588'.repeat(f) + '\u2591'.repeat(e) + ' ' + p + '%\x1b[0m';

    const { execSync } = require('child_process');
    let bookmark = '';
    try { bookmark = execSync('jj.exe log --ignore-working-copy -r @ --no-graph -T local_bookmarks', { encoding: 'utf8', timeout: 3000 }).trim(); } catch {}
    if (!bookmark) {
      try { bookmark = execSync('jj.exe log --ignore-working-copy -r "ancestors(@) & bookmarks()" --limit 1 --no-graph -T local_bookmarks', { encoding: 'utf8', timeout: 3000 }).trim(); } catch {}
    }

    let desc = '';
    try { desc = execSync('jj.exe log --ignore-working-copy -r @ --no-graph -T "description.first_line()"', { encoding: 'utf8', timeout: 3000 }).trim(); } catch {}

    const parts = [bar];
    if (bookmark) parts.push('\x1b[36m' + bookmark + '\x1b[0m');
    if (desc) parts.push(desc.slice(0, 72));
    process.stdout.write(parts.join(' \u2502 '));
  } catch {}
});
