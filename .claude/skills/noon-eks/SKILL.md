---
name: noon-eks
description: >-
  Access noon EKS clusters (QA, staging, prod) with kubectl via k8sReadonly.
  Use when the user asks for kube/k8s/EKS access, pods, logs, port-forward
  targets, or env-specific cluster commands. Staging shares the QA cluster
  (noon2-staging ns). Prefer playground/bin/noon_eks.sh over ad-hoc exports.
---

# noon EKS (QA / staging / prod)

Read-only kubectl access via `AWS_PROFILE=dev` (`k8sReadonly`). Do **not** dump
kubeconfig contents or AWS tokens into chat.

## Map

| Env | Cluster | Region | Kubeconfig | Namespace | Pod prefix |
| --- | --- | --- | --- | --- | --- |
| **qa** | `noon2-eks-qa` | `eu-west-1` | `~/.kube/noon2-eks-qa` | `default` | `dev-noon2-` |
| **staging** | same as qa | `eu-west-1` | same as qa | `noon2-staging` | (ns-wide) |
| **prod** | `noon2-eks-prod` | `eu-central-1` | `~/.kube/noon2-eks-prod` | `default` | `prod-noon2-` |

Staging is **not** a separate cluster — only a namespace on QA.

## Paths

| Item | Path |
| --- | --- |
| Helper | `playground/bin/noon_eks.sh` |
| QA kubeconfig | `~/.kube/noon2-eks-qa` |
| Prod kubeconfig | `~/.kube/noon2-eks-prod` |
| Auth port-forward | skill **auth-port-forward** (QA auth → `:8771`) |

## Workflow

1. `playground/bin/noon_eks.sh ensure <qa|staging|prod>` — SSO + kubeconfig if needed, then smoke-test.
2. Use script wrappers (`pods`, `kubectl`) **or** `eval "$(playground/bin/noon_eks.sh env <env>)"` then plain `kubectl`.
3. Prefer **qa/staging** for exploration. Use **prod** only when the user asks for prod.
4. Do not attempt `apply` / `delete` / secret reads unless the user explicitly asks and RBAC allows (default role is read-only + port-forward/exec/logs).

## Commands

```bash
playground/bin/noon_eks.sh ensure qa
playground/bin/noon_eks.sh ensure prod
playground/bin/noon_eks.sh status staging

playground/bin/noon_eks.sh pods qa
playground/bin/noon_eks.sh pods staging
playground/bin/noon_eks.sh pods prod

# Shell session for ad-hoc kubectl
eval "$(playground/bin/noon_eks.sh env prod)"
kubectl get pods -n default | grep noon2

# One-shot kubectl through the helper
playground/bin/noon_eks.sh kubectl prod -- logs -n default deploy/prod-noon2-core-http-srv --tail=50

# Regenerate kubeconfig (uses developers SSO for eks:DescribeCluster, then patches profile to `dev`)
playground/bin/noon_eks.sh update-kubeconfig prod
```

## Setup notes (one-time)

Prod kubeconfig (Yaqoob):

```bash
aws eks --region eu-central-1 update-kubeconfig --name noon2-eks-prod --kubeconfig ~/.kube/noon2-eks-prod
```

`update-kubeconfig` / `ensure` need the **developers** SSO profile for `eks:DescribeCluster`.
kubectl itself uses **`dev`** → `k8sReadonly`. The helper patches `AWS_PROFILE=dev` into the kubeconfig.

## Failures → next action

| Failure | Next action |
| --- | --- |
| SSO expired / Unauthorized | `aws sso login` then `noon_eks.sh ensure <env>` |
| Missing `~/.kube/noon2-eks-prod` | `noon_eks.sh update-kubeconfig prod` (or `ensure prod`) |
| `eks:DescribeCluster` denied on `dev` profile | Expected — use helper / developers profile for update-kubeconfig only |
| Auth for local bootRun | Use **auth-port-forward** (QA), not prod |

## Closing line

`noon-eks: ready env=<qa|staging|prod>` or `noon-eks: failed — <reason>`

## Related

- **auth-port-forward** — local `:8771` tunnel to QA `dev-noon2-auth-app-srv`
- **pritunl-vpn** / **noon-mysql** — DB access (separate from EKS)
