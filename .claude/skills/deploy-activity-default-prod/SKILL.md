---
name: deploy-activity-default-prod
description: Deploy one activity through the manual publish GitHub workflow using gh CLI, defaulting to prod unless the user specifies staging/dev or multiple environments. Use when the user provides an activity name and wants deployment.
disable-model-invocation: true
---
# Deploy Activity Default Prod

## Purpose
Deploy an activity with `gh workflow run` using `.github/workflows/manual-publish-activity.yml`.

## Inputs
- Required: activity name (folder under `activities/`)
- Optional: environment list (`prod`, `staging`, `dev`)

## Default behavior
- If no environment is specified, deploy to `prod`.
- If one environment is specified, deploy only there.
- If multiple environments are specified, trigger one run per environment.
- Do not execute any deploy command automatically; only provide commands for the user to run.

## Commands
Single environment (default prod):
```bash
gh workflow run manual-publish-activity.yml -f activity_path="<activity-name>" -f environment="prod"
```

Single explicit environment:
```bash
gh workflow run manual-publish-activity.yml -f activity_path="<activity-name>" -f environment="<prod|staging|dev>"
```

Multiple environments:
```bash
for env in prod staging dev; do
  gh workflow run manual-publish-activity.yml -f activity_path="<activity-name>" -f environment="$env"
done
```

## Validation checklist
1. Confirm `gh auth status` is valid.
2. Confirm activity path exists: `activities/<activity-name>`.
3. Do not trigger workflow run(s) from the agent.
4. Share run tracking commands:
   - `gh run list --workflow=manual-publish-activity.yml`
   - `gh run watch`

## Response style
- Keep responses short.
- Echo the exact command(s) to run.
- Mention defaulting to `prod` when environment is omitted.
- Include optional watch/list commands so the user can view outputs after running.
