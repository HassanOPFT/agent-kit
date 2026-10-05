# Examples

## Target layout (new feature)

```
api-test-scripts/
├── auth/
│   ├── auth.sh
│   ├── .env.example
│   └── .env              # gitignored credentials
├── lib/
│   └── runner.sh
└── items/                # kebab-case feature folder
    ├── TEST_PLAN.md
    ├── .env.example
    ├── test_items.sh
    └── logs/             # gitignored
```

## Example matrix (REST resource)

| branch_id | method | path | expected | body_oracle |
|-----------|--------|------|----------|-------------|
| ITEMS-LIST-OK | GET | `/items?page=1&limit=10` | 200 | `.items != null or .data != null or (type == "array")` |
| ITEMS-CREATE-OK | POST | `/items` | 201 or 200 | `.id != null` |
| ITEMS-CREATE-400 | POST | `/items` | 400 | `.message != null or .statusCode == 400 or .error != null` |
| ITEMS-GET-404 | GET | `/items/00000000-0000-0000-0000-000000000000` | 404 | `.statusCode == 404 or .message != null` |

Adapt paths, status codes, and jq filters to the real API. Nest POST often returns **201**; Express/Spring vary.

## Workflow

Default: implement plan + script + run (A→B→C). Plan-only only if the user asks.

## Harness bootstrap

```bash
mkdir -p api-test-scripts/{auth,lib,items}
# From this skill (project-local or user skills install):
#   <repo>/.cursor/skills/api-test-scripts/scripts/
#   ~/.cursor/skills/api-test-scripts/scripts/
cp path/to/api-test-scripts/scripts/runner.sh api-test-scripts/lib/runner.sh
cp path/to/api-test-scripts/scripts/auth.sh api-test-scripts/auth/auth.sh
cp path/to/api-test-scripts/scripts/auth.env.example api-test-scripts/auth/.env.example
cp api-test-scripts/auth/.env.example api-test-scripts/auth/.env
# Fill AUTH_EMAIL / AUTH_PASSWORD (or ACCESS_TOKEN) and BASE_URL
```

Then adapt `auth.sh` login URL, body fields, and token jq path for the target API.

**Windows:** Git Bash + `curl` + `jq`. Optional portable jq: place `jq.exe` at `api-test-scripts/bin/jq.exe` and prepend that dir to `PATH` in feature scripts.
