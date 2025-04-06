import { $ } from "bun";

await Promise.any([
  $`bin/watchexec -e go -- go run ./`,
  $`bin/bun run dev`,
]);
