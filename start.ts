import { $ } from 'bun';

await Promise.all([
	$`bin/bun run dev`,
	$`bin/watchexec -e go -- go run ./`,
]);
