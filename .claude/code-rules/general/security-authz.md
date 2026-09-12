# Authorization & Object Ownership (Language-Agnostic)

## Broken Object-Level Authorization (IDOR)

Applies to any action that looks up a resource by an id/slug coming from params/route/body
(update, delete, read-one, and sometimes list) — regardless of language or framework.

**The check:** trace how the record reaches the handler. It is safe only if ONE of these is true:
1. The query/lookup itself is scoped to the current actor
   (e.g. `current_user.orders.find(id)`, `Order.objects.filter(user=request.user).get(id=id)`,
   `WHERE user_id = :current_user_id AND id = :id`).
2. The authorization layer (policy/ability/guard/middleware) checks ownership on the
   **specific record's own foreign key to the actor** — not just on a related/nested
   attribute that merely narrows the *type* of records visible.

**Red flag pattern:** the record is fetched generically (`Model.find(params[:id])`,
`Model.objects.get(pk=id)`, `SELECT * FROM t WHERE id = ?`) and the only authorization
check is on an attribute of a *related* object (e.g. "belongs to a course the user is
enrolled in", "status = published", "tenant matches"), without checking that the record's
own owner/user_id/account_id column equals the current actor's id.

**Why the red flag matters even when the current call site is safe:** ownership checks
belong in the authorization layer so every future call site inherits the protection.
If ownership is only enforced by how *this* controller happens to build its query, the
next endpoint/service that reuses the same authorization rule but does a generic lookup
(`find(params[:id])`, a GraphQL resolver, an internal RPC, a background job) silently
loses that protection. Flag it as a hardening suggestion even if today's code path is
not exploitable — but only report it as **Critical/Warning** if you can show a concrete
call site (existing code, not hypothetical) where the generic lookup is actually reachable
without additional scoping.

## How to verify (do not skip — see core review methodology)

1. Find the query/ORM call that resolves the record from the request-supplied id.
2. Check whether that query filters by the current actor, OR
3. Check whether the authorization rule/policy condition includes the record's own
   owner/user/account foreign key equal to the current actor.
4. If neither — construct the concrete attack: "user B, who owns record X (satisfying
   the type-level condition the policy checks), can call this same endpoint with
   another user's record id and pass authorization because the policy never compares
   ownership." If you can't name the specific reachable endpoint, it's a **Suggestion**
   (hardening), not a Critical/Warning finding.

## Examples across stacks (for pattern recognition only — verify against actual code, don't assume)

- **Rails / CanCanCan / Pundit:** `can :update, Model, related: { attr: value }` without
  `owner_id: user.id` — safe only if every controller action builds the record via
  `current_user.association.find(...)` first.
- **Django REST Framework:** a `permission_classes` / `get_queryset()` that doesn't filter
  `.filter(user=request.user)`, relying only on a `has_object_permission` that checks an
  unrelated field.
- **Express/Node:** `Model.findById(req.params.id)` followed by a permission check that
  reads a joined table's field but not `record.userId === req.user.id`.
- **Laravel:** route-model-binding (`Route::model`) without a Policy's `update()` method
  comparing `$model->user_id === $user->id`.
- **Spring:** `@PreAuthorize` expressions checking a role or a joined entity's field, not
  `#model.ownerId == authentication.principal.id`.

## Related, but out of scope for this rule
- Missing authentication entirely (no login check) — covered separately, always Critical.
- Mass-assignment / over-permissive param whitelisting — separate finding category.
