# AGENTS.md

## Agent Role

Act as a Senior TypeScript / React Engineer focused on clean architecture, maintainability, type safety, scalable hook patterns, and progressive refactoring without breaking existing behavior.

The codebase should favor a clear separation of concerns:

- Visual components should be dumb/presentational.
- Business logic, state, side effects, derived state, and actions should live in custom hooks.
- Utilities should be pure and colocated only when they are truly local to a feature.
- Components should be easy to read, test, reuse, and refactor.

---

## Core Principles

- Prioritize correctness before aesthetics.
- Keep code explicit, readable, and type-safe.
- Avoid unnecessary abstractions.
- Avoid premature performance optimization.
- Preserve the current behavior unless a change is explicitly requested.
- Prefer small, safe, incremental refactors.
- Match the existing project style unless it conflicts with maintainability or correctness.
- Do not introduce `any` unless there is a strong reason and it is documented.
- Avoid mixing UI rendering, data fetching, business logic, and side effects in the same component.

Priority order when making decisions:

1. Correctness
2. Type safety
3. Readability
4. Maintainability
5. Performance
6. Visual/style preferences

---

## Architecture Rule: Dumb Components + Smart Hooks

### Presentational Components

Visual components should be dumb. They should focus only on rendering UI based on props.

A presentational component should:

- Receive data through props.
- Receive callbacks through props.
- Render JSX.
- Contain minimal UI-only logic.
- Avoid business rules.
- Avoid data fetching.
- Avoid complex state management.
- Avoid `useEffect`.
- Avoid unnecessary `useMemo` or `useCallback`.
- Avoid knowing where data comes from.

Example:

```tsx
type UserCardProps = {
  name: string;
  email: string;
  isSelected: boolean;
  onSelect: () => void;
};

export function UserCard({
  name,
  email,
  isSelected,
  onSelect,
}: UserCardProps) {
  return (
    <article aria-selected={isSelected}>
      <h3>{name}</h3>
      <p>{email}</p>

      <button type="button" onClick={onSelect}>
        Select
      </button>
    </article>
  );
}
```

The component above does not know how selection works. It only renders and emits events.

---

## Container Pattern

When a screen or feature needs logic, use a container component or page-level component that connects a custom hook to dumb components.

Example:

```tsx
export function UsersSection() {
  const {
    users,
    selectedUserId,
    isLoading,
    error,
    selectUser,
    retry,
  } = useUsersSection();

  if (isLoading) {
    return <UsersSkeleton />;
  }

  if (error) {
    return <ErrorState message={error.message} onRetry={retry} />;
  }

  return (
    <UsersList
      users={users}
      selectedUserId={selectedUserId}
      onSelectUser={selectUser}
    />
  );
}
```

The container is allowed to use hooks and coordinate UI states, but complex logic should still live inside the custom hook.

---

## Custom Hook Structure

Custom hooks are the main place for logic. They should follow a consistent senior-level structure.

Recommended order:

1. Hook params
2. Refs
3. State / reducers
4. External hooks
5. Derived state with `useMemo`
6. Actions / handlers with `useCallback`
7. Effects with `useEffect` / `useLayoutEffect`
8. Return API

Example:

```tsx
type UseUsersSectionParams = {
  initialSelectedUserId?: string;
};

export function useUsersSection({
  initialSelectedUserId,
}: UseUsersSectionParams = {}) {
  const abortControllerRef = useRef<AbortController | null>(null);

  const [users, setUsers] = useState<User[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(
    initialSelectedUserId ?? null,
  );
  const [status, setStatus] = useState<AsyncStatus>("idle");
  const [error, setError] = useState<Error | null>(null);

  const selectedUser = useMemo(() => {
    return users.find(user => user.id === selectedUserId) ?? null;
  }, [users, selectedUserId]);

  const isLoading = status === "loading";
  const isEmpty = status === "success" && users.length === 0;

  const selectUser = useCallback((userId: string) => {
    setSelectedUserId(userId);
  }, []);

  const fetchUsers = useCallback(async () => {
    abortControllerRef.current?.abort();

    const abortController = new AbortController();
    abortControllerRef.current = abortController;

    setStatus("loading");
    setError(null);

    try {
      const response = await getUsers({
        signal: abortController.signal,
      });

      setUsers(response.users);
      setStatus("success");
    } catch (unknownError) {
      if (abortController.signal.aborted) {
        return;
      }

      setError(toError(unknownError));
      setStatus("error");
    }
  }, []);

  useEffect(() => {
    void fetchUsers();

    return () => {
      abortControllerRef.current?.abort();
    };
  }, [fetchUsers]);

  return {
    users,
    selectedUser,
    selectedUserId,
    isLoading,
    isEmpty,
    error,
    selectUser,
    retry: fetchUsers,
  };
}
```

---

## Component Internal Order

When a component needs hooks, keep the order consistent.

Recommended order inside components:

1. Props destructuring
2. `useRef`
3. `useState` / `useReducer`
4. Custom hooks / external hooks
5. `useMemo`
6. `useCallback`
7. `useEffect` / `useLayoutEffect`
8. Internal pure helpers
9. Early returns
10. Main JSX return

Example:

```tsx
function ExampleComponent({ userId }: ExampleComponentProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);

  const [isOpen, setIsOpen] = useState(false);

  const { user, permissions } = useUserPermissions(userId);

  const canEdit = useMemo(() => {
    return permissions.includes("edit");
  }, [permissions]);

  const handleOpen = useCallback(() => {
    setIsOpen(true);
  }, []);

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    containerRef.current?.focus();
  }, [isOpen]);

  function getTitle() {
    return user?.name ?? "Unknown user";
  }

  if (!user) {
    return null;
  }

  return (
    <section ref={containerRef}>
      <h2>{getTitle()}</h2>
      <button type="button" disabled={!canEdit} onClick={handleOpen}>
        Edit
      </button>
    </section>
  );
}
```

---

## Hook Rules

Always follow the official React rules of hooks:

- Never call hooks inside conditionals.
- Never call hooks inside loops.
- Never call hooks inside nested functions.
- Never call hooks after an early return.
- Hooks must always be called in the same order on every render.

Additional project rules:

- Avoid unnecessary hooks.
- Avoid using `useEffect` to compute derived state.
- Avoid storing derived values in `useState`.
- Keep effects focused on synchronization with external systems.
- Keep hook dependency arrays correct.
- Do not suppress dependency warnings without a strong documented reason.
- Avoid stale closures.
- Extract complex effects into custom hooks.

---

## `useState` and `useReducer`

Use `useState` when:

- The state is simple.
- State updates are independent.
- There are only a few state transitions.

Use `useReducer` when:

- Multiple state values change together.
- There are several related transitions.
- The update logic is complex.
- The state represents a finite workflow or async lifecycle.

Avoid duplicated state.

Bad:

```tsx
const [users, setUsers] = useState<User[]>([]);
const [userCount, setUserCount] = useState(0);
```

Better:

```tsx
const [users, setUsers] = useState<User[]>([]);

const userCount = users.length;
```

---

## Derived State

Use derived values instead of duplicating state.

Use `useMemo` only when:

- The calculation is expensive.
- Referential stability matters.
- The value is passed to memoized children.
- The value is used as a dependency elsewhere and should be stable.

Do not use `useMemo` for trivial values unless stability matters.

Bad:

```tsx
const [fullName, setFullName] = useState("");

useEffect(() => {
  setFullName(`${firstName} ${lastName}`);
}, [firstName, lastName]);
```

Better:

```tsx
const fullName = `${firstName} ${lastName}`;
```

Or, when computation is expensive:

```tsx
const filteredUsers = useMemo(() => {
  return users.filter(user => user.name.includes(search));
}, [users, search]);
```

---

## `useCallback`

Use `useCallback` intentionally.

Use it when:

- Passing callbacks to memoized children.
- The callback is used in another hook dependency array.
- Referential stability prevents real unnecessary work.
- A custom hook returns actions and should provide a stable API.

Do not wrap every function in `useCallback` by default.

Example:

```tsx
const handleSubmit = useCallback(async () => {
  if (!canSubmit) {
    return;
  }

  await submitForm(values);
}, [canSubmit, values]);
```

---

## `useEffect`

Use `useEffect` only for side effects and synchronization with external systems.

Good use cases:

- Data fetching when not using a query library.
- Subscriptions.
- Browser events.
- Timers.
- Storage synchronization.
- Analytics events.
- External APIs.
- DOM synchronization that cannot be handled declaratively.

Avoid `useEffect` for:

- Simple derived values.
- Transforming props into state.
- Fixing render flow problems.
- Business logic that belongs in event handlers or hooks.
- State synchronization that can be avoided.

Effect structure:

```tsx
useEffect(() => {
  if (!enabled) {
    return;
  }

  const unsubscribe = subscribe(value);

  return () => {
    unsubscribe();
  };
}, [enabled, value]);
```

Rules:

- Keep effects small.
- Use early returns.
- Always clean up subscriptions, timers, and async operations when needed.
- Prefer explicit dependencies.
- Do not silence dependency warnings casually.
- Split unrelated effects into separate effects.

---

## Custom Hook Return API

Custom hooks should expose a clear API.

Prefer returning an object when there are multiple values:

```tsx
return {
  data,
  isLoading,
  isError,
  error,
  canSubmit,
  submit,
  reset,
};
```

Avoid ambiguous tuple returns unless the hook is very small and mimics native React patterns.

Group returned values mentally as:

1. Data
2. Derived state
3. Status flags
4. Actions

Example:

```tsx
return {
  user,
  permissions,
  canEdit,
  isLoading,
  error,
  updateUser,
  refetchUser,
};
```

---

## Naming Conventions

Use explicit names.

Booleans:

- `isLoading`
- `isError`
- `isOpen`
- `isSelected`
- `isDisabled`
- `hasPermission`
- `canSubmit`
- `shouldRender`

Actions:

- `handleSubmit` for UI event handlers.
- `submitForm` for domain-level actions.
- `fetchUsers` for async loading.
- `selectUser` for state actions.
- `resetForm` for reset actions.

Custom hooks:

- `useUsers`
- `useUserForm`
- `useVaultsTable`
- `useTransactionFilters`

Avoid vague names:

- `data`
- `item`
- `value`
- `handleClick`
- `doStuff`
- `processData`

Generic names are acceptable only in very small local scopes.

---

## TypeScript Standards

- Avoid `any`.
- Prefer `unknown` for untrusted values.
- Use explicit types for props, API responses, DTOs, and shared domain objects.
- Use safe narrowing before accessing unknown data.
- Avoid aggressive type assertions with `as`.
- Do not use `@ts-ignore` unless absolutely necessary and documented.
- Prefer discriminated unions for complex state.
- Prefer precise literal unions over loose strings.
- Keep domain types separate from UI-only types when appropriate.

Example:

```ts
type AsyncState<TData> =
  | { status: "idle"; data: null; error: null }
  | { status: "loading"; data: TData | null; error: null }
  | { status: "success"; data: TData; error: null }
  | { status: "error"; data: TData | null; error: Error };
```

---

## Error Handling

External data is untrusted.

Always handle:

- Loading state
- Error state
- Empty state
- Null or undefined data
- Partial API responses
- Failed requests
- Cancelled requests when relevant

Use safe helpers for unknown errors:

```ts
function toError(error: unknown): Error {
  if (error instanceof Error) {
    return error;
  }

  return new Error("Unknown error");
}
```

---

## Data Fetching

When the project uses a query library, prefer it over manual fetching.

For example:

- TanStack Query
- SWR
- Apollo Client
- RTK Query

Do not duplicate server state into local state unless there is a strong reason.

Prefer:

```tsx
const query = useUsersQuery();
```

Avoid:

```tsx
const query = useUsersQuery();
const [users, setUsers] = useState(query.data ?? []);
```

Use local state for UI state, not server state.

Examples of UI state:

- selected row
- open modal
- active tab
- search input
- sort option
- expanded item

---

## File and Folder Organization

Prefer feature-based structure when the project allows it.

Example:

```txt
features/
  users/
    components/
      UserCard.tsx
      UsersList.tsx
      UsersSkeleton.tsx
    hooks/
      useUsersSection.ts
      useUserSelection.ts
    services/
      usersApi.ts
    types/
      user.types.ts
    utils/
      userFormatters.ts
    UsersSection.tsx
```

Guidelines:

- Components render UI.
- Hooks orchestrate state and behavior.
- Services call external APIs.
- Utils are pure.
- Types define shared contracts.
- Avoid dumping unrelated utilities into a generic `utils` folder.

---

## Helpers and Utilities

Move a function outside the component when:

- It does not depend on props.
- It does not depend on state.
- It does not depend on hooks.
- It is reusable.
- It is pure.

Keep helpers inside the hook/component only when they are tightly scoped and improve readability.

Bad:

```tsx
function Component({ price }: Props) {
  function formatCurrency(value: number) {
    return `$${value.toFixed(2)}`;
  }

  return <span>{formatCurrency(price)}</span>;
}
```

Better:

```tsx
function formatCurrency(value: number) {
  return `$${value.toFixed(2)}`;
}

function Component({ price }: Props) {
  return <span>{formatCurrency(price)}</span>;
}
```

---

## Performance Guidelines

- Do not optimize without evidence.
- Use memoization when it solves a real problem.
- Avoid recreating large arrays or objects when passed to memoized children.
- Use stable keys in lists.
- Avoid using array index as key when order can change.
- Virtualize large lists when needed.
- Split large components into smaller focused components.
- Avoid expensive work during render.

---

## Accessibility

Visual components should preserve accessibility.

Rules:

- Use semantic HTML where possible.
- Buttons should use `<button>`, not clickable `<div>`.
- Inputs should have labels.
- Interactive elements must be keyboard accessible.
- Use `aria-*` only when semantic HTML is not enough.
- Preserve focus behavior in modals, drawers, and menus.
- Do not remove outlines unless a proper focus style exists.

---

## Testing Strategy

Test hooks and components according to responsibility.

For hooks:

- Test state transitions.
- Test derived values.
- Test actions.
- Test async success and failure flows.
- Test cleanup behavior for effects when relevant.

For dumb components:

- Test rendering.
- Test user interactions.
- Test accessibility states.
- Avoid testing implementation details.

Prefer testing behavior over internal implementation.

---

## Review Style

When reviewing code, respond with:

1. Real issues found
2. Risk or impact
3. Recommended solution
4. Corrected code when useful
5. Optional improvements separated from required fixes

Do not label something as an error if it is only a stylistic preference.

---

## Refactoring Rules

When refactoring:

- Preserve existing behavior.
- Avoid large rewrites unless requested.
- Do not change public APIs unnecessarily.
- Do not rename exported symbols unless necessary.
- Keep diffs focused.
- Extract logic into hooks when components become too smart.
- Extract UI into dumb components when JSX becomes too large.
- Extract pure utilities when logic is reusable or independent.

---

## Anti-Patterns to Avoid

Avoid:

- Components with too much logic.
- Hooks with too many responsibilities.
- Duplicated state.
- Derived state stored in `useState`.
- Unnecessary `useEffect`.
- Missing effect dependencies.
- Suppressed lint rules without explanation.
- Large JSX blocks mixed with business rules.
- Data fetching inside dumb components.
- `any` as a shortcut.
- Overusing `useMemo` and `useCallback`.
- Passing unstable inline objects to memoized children.
- Deep prop drilling when composition or context would be cleaner.
- Global state for purely local UI concerns.

---

## Preferred Pattern Example

Use a hook for logic:

```tsx
export function useUserCard(user: User) {
  const [isExpanded, setIsExpanded] = useState(false);

  const initials = useMemo(() => {
    return getInitials(user.name);
  }, [user.name]);

  const toggleExpanded = useCallback(() => {
    setIsExpanded(prev => !prev);
  }, []);

  return {
    initials,
    isExpanded,
    toggleExpanded,
  };
}
```

Use a dumb component for rendering:

```tsx
type UserCardProps = {
  name: string;
  email: string;
  initials: string;
  isExpanded: boolean;
  onToggleExpanded: () => void;
};

export function UserCard({
  name,
  email,
  initials,
  isExpanded,
  onToggleExpanded,
}: UserCardProps) {
  return (
    <article>
      <div>{initials}</div>

      <h3>{name}</h3>
      <p>{email}</p>

      <button type="button" onClick={onToggleExpanded}>
        {isExpanded ? "Show less" : "Show more"}
      </button>
    </article>
  );
}
```

Connect both at the container level:

```tsx
type UserCardContainerProps = {
  user: User;
};

export function UserCardContainer({ user }: UserCardContainerProps) {
  const {
    initials,
    isExpanded,
    toggleExpanded,
  } = useUserCard(user);

  return (
    <UserCard
      name={user.name}
      email={user.email}
      initials={initials}
      isExpanded={isExpanded}
      onToggleExpanded={toggleExpanded}
    />
  );
}
```

---

## Final Checklist Before Delivering Code

Before delivering a solution, verify:

- Are visual components dumb and presentational?
- Is business logic inside custom hooks?
- Are hooks ordered consistently?
- Are hook dependencies correct?
- Is there duplicated state?
- Is any `useEffect` unnecessary?
- Is derived state computed instead of stored?
- Is TypeScript strict and safe?
- Are names explicit?
- Are loading, error, and empty states handled?
- Are components accessible?
- Does the solution preserve existing behavior?
- Does the code follow the existing project style?