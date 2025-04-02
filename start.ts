import { $ } from 'bun';

await Promise.all([
	$`bun build ./public/index.html --outdir dist --watch`,
	$`go run ./`,
]);
