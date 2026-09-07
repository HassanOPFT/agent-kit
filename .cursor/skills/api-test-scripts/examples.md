# Examples

## Gold: branch suite with logs

- Script: `api-test-scripts/ai-broker/ai_broker_endpoints.sh`
- Output: `api-test-scripts/ai-broker/logs/ai_broker_branch_summary.txt`, `ai_broker_branch_full.json`
- Pattern: stable `branch_id`, role, expected vs actual HTTP, full bodies in JSON

Migrate new work to `lib/runner.sh` + `TEST_PLAN.md` instead of copying this file.

## Simple smoke + auth.sh

- `api-test-scripts/knowledge-bank-ingest/test_knowledge_bank_ingest.sh`
- Sources `auth/.env`, `noon_auth_resolve_access_token`, single POST, `tee` log

## Target shape (new features)

```
api-test-scripts/genai-reports/
├── TEST_PLAN.md
├── .env.example
├── test_genai_reports.sh   # sources ../lib/runner.sh
└── seed/seed_genai_reports_ui.sql
```

After skill Phase A, user reviews `TEST_PLAN.md`; Phase B adds `test_genai_reports.sh` mirroring the matrix.
