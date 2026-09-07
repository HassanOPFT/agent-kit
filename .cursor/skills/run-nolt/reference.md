# Run Nolt — reference

## Workspace Docker script

Path: `noon_workspace/scripts/build-and-run-nolt.sh`

| Constant | Value |
| --- | --- |
| `IMAGE_TAG` | `nolt-local:fix` |
| `CONTAINER_NAME` | `nolt-local-fix` |
| `PORT` | `3000` |
| `ENV_FILE` | `.env.local` (inside `nolt.diy`) |
| `WORK_DIR` | `nolt.diy` |

Must run from workspace root so `$WORK_DIR` resolves.

`VITE_*` keys from `.env.local` become `--build-arg` (except `VITE_HMR_*`).

## App ports

| Mode | Port |
| --- | --- |
| `npm run dev` / Docker script | 3000 |
| `docker-compose.yaml` `app-dev` / `app-prod` | 5173 |

## Related skills

- `run-nolt` — start server
- `open-nolt-browser` — Chrome
