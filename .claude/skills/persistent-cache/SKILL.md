---
name: persistent-cache
description: >-
  Add AsyncStorage-backed persistent caching to React Query hooks in noon2-frontend.
  Use when implementing or updating a query with withCache, fetchWithPersistentCache,
  PersistentCacheMaxAge, disk cache TTL, or persistent_cache_enabled feature flag.
---

# Persistent Cache for React Query

Persistent cache stores API responses in AsyncStorage so reference data survives app restarts. It is gated by the `persistent_cache_enabled` feature flag (wired in `appConfig.slice.ts` via `setPersistentCacheEnabled`).

**Key files**

| File                                                   | Role                                                          |
| ------------------------------------------------------ | ------------------------------------------------------------- |
| `packages/common/src/storage/PersistentCache.ts`       | `withCache`, `fetchWithPersistentCache`, invalidation helpers |
| `packages/common/src/storage/PersistentCacheConfig.ts` | Per-resource `maxAgeMs` TTL (`PersistentCacheMaxAge`)         |
| `packages/common/src/requests/**/Query.ts`             | Hook integration                                              |

---

## When to use

Use persistent cache for **slow-changing reference data** (countries, curriculum tags, learning goals, etc.) where:

- A network round-trip on every cold start is wasteful
- Stale data within a known TTL is acceptable
- The response shape is stable (or you can bump the global cache `version`)

Do **not** use it for user-specific, real-time, or mutation-heavy data unless product explicitly requires offline fallback.

---

## Implementation checklist

```
- [ ] 1. Add TTL entry in PersistentCacheConfig.ts (`PersistentCacheMaxAge`)
- [ ] 2. Wire queryFn with fetchWithPersistentCache (never withCache alone)
- [ ] 3. Invalidate disk + React Query cache on mutations (if applicable)
- [ ] 4. Run yarn workspace common check-types
```

---

## Step 1 — Add TTL entry

In `PersistentCacheConfig.ts`, add a named entry to `PersistentCacheMaxAge`:

```ts
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

export const PersistentCacheMaxAge = {
  myResource: SEVEN_DAYS_MS,
  myResourceById: THIRTY_DAYS_MS,
} satisfies Record<string, number>;
```

**TTL guidance**

| Data type                        | Typical TTL |
| -------------------------------- | ----------- |
| Countries, learning goals        | 30 days     |
| Boards, grades, subjects (lists) | 7 days      |
| Chapters (lists)                 | 1 day       |
| Single-entity by ID              | 30 days     |

Use separate keys for **list** vs **by-id** queries when TTLs differ (see `boards` / `boardById`).

**Cache version busting**

All on-disk entries share a single `CACHE_VERSION` constant in `PersistentCache.ts`. Bump it to invalidate every persisted entry after a breaking response shape change:

```ts
const CACHE_VERSION = '1'; // increment to bust all disk caches
```

---

## Step 2 — Wire the query hook

The AsyncStorage key is derived from the React Query `queryKey` via `toCacheKey`, which `JSON.stringify`s each segment (so object/array params stay distinct on disk). **Use the same `queryKey` in the hook and in `fetchWithPersistentCache`.**

```ts
import { useQuery } from '@tanstack/react-query';
import { fetchWithPersistentCache } from 'common/src/storage/PersistentCache';
import { PersistentCacheMaxAge } from 'common/src/storage/PersistentCacheConfig';
import { getMyResources } from './Api';

export const useMyResourcesQuery = (filter?: { active?: boolean }) => {
  return useQuery({
    queryKey: ['myResources', filter],
    queryFn: ({ queryKey }) =>
      fetchWithPersistentCache(queryKey, PersistentCacheMaxAge.myResource, () =>
        getMyResources(filter),
      ),
  });
};
```

### By-id query with conditional fetch

```ts
export const useMyResourceQuery = (id?: number) => {
  return useQuery({
    queryKey: ['myResource', id],
    enabled: !!id,
    queryFn: ({ queryKey }) =>
      fetchWithPersistentCache(
        queryKey,
        PersistentCacheMaxAge.myResourceById,
        () => getMyResource(id!),
      ),
  });
};
```

### App-type branching (admin / teacher)

Keep branching inside the `fetch` callback — one `queryKey`, one TTL entry:

```ts
queryFn: ({ queryKey }) =>
  fetchWithPersistentCache(
    queryKey,
    PersistentCacheMaxAge.boardById,
    () =>
      appType === 'admin'
        ? getAdminBoard(boardId!)
        : getTeacherBoard(boardId!),
  ),
```

---

## Step 3 — Why `fetchWithPersistentCache`, not `withCache`

**Never call `withCache` directly from a React Query `queryFn`.** `withCache` is module-private; `fetchWithPersistentCache` is the public `queryFn` wrapper.

Disk-level TTL is enforced inside `withCache` against each entry's stored `cachedAt`, so a 29-day-old entry is treated as stale once it crosses its `maxAgeMs` — there is no React Query `dataUpdatedAt` plumbing to keep in sync.

### React Query `staleTime` / `gcTime`

Hooks in this codebase **do not** set `staleTime` or `gcTime`. TTL enforcement lives in `withCache` inside `queryFn`:

- React Query may still call `queryFn` on mount, focus, reconnect, etc.
- A fresh disk hit avoids the network; only AsyncStorage is read
- When the disk entry is stale, `withCache` fetches from the network

This keeps disk TTL as the single source of truth. Optionally add `refetchOnWindowFocus: false` for noisy reference-data queries if needed.

---

## Step 4 — Invalidate on mutations

When create/update/delete mutations change cached data, clear **both** AsyncStorage and the in-memory React Query cache. Use `clearPersistentCachesAndInvalidate`, which awaits the disk clear **before** invalidating so the refetch triggered by invalidation cannot read a still-fresh disk entry and serve pre-mutation data:

```ts
import { clearPersistentCachesAndInvalidate } from '../../../storage/PersistentCache';
import { fallbackErrorHandler } from '../../../utils/FallbackErrorHandler';

const useInvalidateQueries = () => {
  const queryClient = useQueryClient();
  return () => {
    // Pass every related prefix — detail (['board']) and list (['boards']).
    clearPersistentCachesAndInvalidate(queryClient, [
      ['board'],
      ['boards'],
    ]).catch(fallbackErrorHandler);
  };
};
```

List the **first segment** of each related `queryKey` as a separate prefix. Because `toCacheKey` quotes each segment, `['board']` no longer matches `['boards', ...]` on disk — include both detail and list prefixes explicitly.

---

## Behavior reference

| Condition                  | Result                                                  |
| -------------------------- | ------------------------------------------------------- |
| Feature flag off           | Always network fetch; no disk read/write                |
| Fresh disk hit             | Return cached data; no network call                     |
| Stale / missing disk       | Network fetch; write new envelope with `cachedAt = now` |
| Network error + stale disk | Serve stale disk data (offline fallback)                |
| `CACHE_VERSION` mismatch   | Treat as cache miss                                     |

---

## Anti-patterns

- ❌ `queryFn: () => withCache(...)` — `withCache` is private; use `fetchWithPersistentCache`
- ❌ Separate manual AsyncStorage keys unrelated to `queryKey` — breaks invalidation
- ❌ Forgetting to bump `CACHE_VERSION` after breaking response shape changes
- ❌ Caching paginated or user-specific endpoints without a scoped `queryKey`
- ❌ Mutations that only `invalidateQueries` without clearing the disk cache (use `clearPersistentCachesAndInvalidate`)

---

## Existing examples

| Hook                                   | `PersistentCacheMaxAge` key |
| -------------------------------------- | --------------------------- |
| `useCountries`                         | `countries`                 |
| `useLearningGoalsQuery`                | `learningGoals`             |
| `useGoalQuery`                         | `learningGoalById`          |
| `useBoardsQuery` / `useBoardQuery`     | `boards` / `boardById`      |
| `useGradesQuery` / `useGradeQuery`     | `grades` / `gradeById`      |
| `useSubjectsQuery` / `useSubjectQuery` | `subjects` / `subjectById`  |
| `useQuestionTagsQueries`               | multiple entries            |

Read these files before adding a new cached query.
