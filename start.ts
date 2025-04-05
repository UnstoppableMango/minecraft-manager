import { $ } from 'bun';

await Promise.all([
	$`bun run build --watch`,
	$`go run ./`,
]);
