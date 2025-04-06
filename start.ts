import { $ } from 'bun';

await Promise.any([
	$`bin/watchexec -e go -r --wrap-process session -- 'go run .'`,
	$`bin/bun run dev`,
]);
