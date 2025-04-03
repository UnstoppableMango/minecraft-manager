import { $ } from 'bun';
import { exists, readdir, rm } from 'node:fs/promises';

const outdir = './dist';

if (await exists(outdir)) {
	for (const f of await readdir(outdir)) {
		await rm(f, { recursive: true, force: true });
	}
}

await $`bin/bun x @tailwindcss/cli -o public/styles.css`;

const result = await Bun.build({
	entrypoints: ['./public/index.html'],
	outdir,
});

result.logs.forEach(console.log);
