import { $ } from 'bun';

await Promise.all([
	$`bin/bun --watch build.ts`,
	// TODO: This leaves a dangling process
	// $`bin/watchexec -e go -r --wrap-process session -- go run ./`,
	$`go run ./`,
]);
