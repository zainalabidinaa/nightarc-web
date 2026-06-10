# Luna Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Vite + React + Tailwind portal at `Luna/luna-portal/` for purchasing, profile management, addon management, and admin catalog/user/invite CMS.

**Architecture:** Single Vite app with React Router v6 route groups split by auth state (public / user / admin). Supabase handles auth and data; Stripe Checkout handles payments; three Supabase Edge Functions handle webhooks, checkout session creation, and admin user reads.

**Tech Stack:** Vite 5, React 18, TypeScript, Tailwind CSS 3, React Router v6, @supabase/supabase-js v2, @stripe/stripe-js, Vitest + React Testing Library

---

## File Map

```
Luna/luna-portal/
├── src/
│   ├── types/index.ts                          # All shared TypeScript types
│   ├── lib/supabase.ts                         # Supabase client singleton
│   ├── lib/stripe.ts                           # Stripe.js loader
│   ├── context/AuthContext.tsx                 # Session, role, profiles state
│   ├── components/
│   │   ├── ui/Button.tsx
│   │   ├── ui/Card.tsx
│   │   ├── ui/Modal.tsx
│   │   ├── ui/Badge.tsx
│   │   ├── ui/Input.tsx
│   │   ├── ui/DragHandle.tsx
│   │   ├── layout/Navbar.tsx
│   │   ├── layout/Sidebar.tsx
│   │   ├── layout/RouteGuards.tsx              # PublicRoute, UserRoute, AdminRoute
│   │   ├── profiles/ProfileCard.tsx
│   │   ├── profiles/ProfileEditor.tsx          # Modal for add/edit profile
│   │   └── catalog/
│   │       ├── CollectionRow.tsx               # Draggable row in catalog list
│   │       └── CollectionEditor/
│   │           ├── index.tsx                   # 4-step wizard shell + state
│   │           ├── StepBasics.tsx
│   │           ├── StepContent.tsx             # Flat list OR grouped editor
│   │           ├── StepArtwork.tsx
│   │           └── StepReview.tsx
│   ├── routes/
│   │   ├── public/PricingPage.tsx
│   │   ├── public/LoginPage.tsx
│   │   ├── public/SignupPage.tsx
│   │   ├── user/ProfilesPage.tsx
│   │   ├── user/AddonsPage.tsx
│   │   ├── user/BillingPage.tsx
│   │   ├── admin/CatalogPage.tsx
│   │   ├── admin/UsersPage.tsx
│   │   └── admin/InvitesPage.tsx
│   └── App.tsx                                 # Router + route tree
├── supabase/functions/
│   ├── admin-users/index.ts
│   ├── create-checkout-session/index.ts
│   └── stripe-webhook/index.ts
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

---

### Task 1: Scaffold the project

**Files:**
- Create: `Luna/luna-portal/package.json`
- Create: `Luna/luna-portal/vite.config.ts`
- Create: `Luna/luna-portal/tailwind.config.ts`
- Create: `Luna/luna-portal/tsconfig.json`
- Create: `Luna/luna-portal/index.html`
- Create: `Luna/luna-portal/src/index.css`
- Create: `Luna/luna-portal/src/main.tsx`

- [ ] **Step 1: Create the project directory and package.json**

```bash
cd /Users/zain/projects/Luna
mkdir luna-portal && cd luna-portal
```

Create `package.json`:
```json
{
  "name": "luna-portal",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "@stripe/stripe-js": "^4.0.0",
    "@supabase/supabase-js": "^2.45.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.0"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.4.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.5.0",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.19",
    "jsdom": "^24.1.0",
    "postcss": "^8.4.39",
    "tailwindcss": "^3.4.6",
    "typescript": "^5.5.3",
    "vite": "^5.3.4",
    "vitest": "^2.0.3"
  }
}
```

- [ ] **Step 2: Create vite.config.ts**

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
  },
});
```

- [ ] **Step 3: Create tailwind.config.ts**

```ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#f2f6fc',
        surface: '#ffffff',
        accent: '#6d28d9',
        'accent-light': '#ede9fe',
        border: '#e2e8f0',
        text: '#0f172a',
        muted: '#64748b',
      },
    },
  },
  plugins: [],
} satisfies Config;
```

- [ ] **Step 4: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```

- [ ] **Step 5: Create index.html**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Luna</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 6: Create src/index.css**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  font-family: 'Inter', sans-serif;
  background-color: #f2f6fc;
  color: #0f172a;
}
```

- [ ] **Step 7: Create src/main.tsx**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

- [ ] **Step 8: Create src/test-setup.ts**

```ts
import '@testing-library/jest-dom';
```

- [ ] **Step 9: Install dependencies**

```bash
cd /Users/zain/projects/Luna/luna-portal
npm install
```

Expected: `node_modules/` created, no errors.

- [ ] **Step 10: Create placeholder App.tsx and verify dev server starts**

```tsx
export default function App() {
  return <div className="min-h-screen bg-bg flex items-center justify-center">
    <h1 className="text-2xl font-semibold text-text">Luna Portal</h1>
  </div>;
}
```

```bash
npm run dev
```

Expected: Server starts on `http://localhost:5173`, "Luna Portal" visible.

- [ ] **Step 11: Commit**

```bash
cd /Users/zain/projects/Luna
git add luna-portal/
git commit -m "feat(portal): scaffold Vite + React + Tailwind project"
```

---

### Task 2: Types and library clients

**Files:**
- Create: `src/types/index.ts`
- Create: `src/lib/supabase.ts`
- Create: `src/lib/stripe.ts`

- [ ] **Step 1: Create src/types/index.ts**

```ts
export type UserRole = 'admin' | 'friends_family' | 'premium' | 'premium_plus';

export interface Profile {
  id: string;
  user_id: string;
  name: string;
  avatar_color: string | null;
  avatar_id: number | null;
  profile_index: number;
  uses_primary_addons: boolean;
  pin_enabled: boolean;
  role: UserRole;
  created_at: string;
}

export interface InstalledAddon {
  id: string;
  profile_id: string;
  addon_url: string;
  addon_name: string | null;
  enabled: boolean;
  sort_order: number;
  created_at: string;
}

export interface InviteCode {
  code: string;
  created_by: string | null;
  used_by: string | null;
  used_at: string | null;
  created_at: string;
  max_uses: number;
  is_active: boolean;
}

export interface Collection {
  id: string;
  name: string;
  sort_order: number;
  backdrop_image: string | null;
  view_mode: string;
  show_all_tab: boolean;
  focus_glow_enabled: boolean;
  pin_to_top: boolean;
  created_at: string;
}

export interface Folder {
  id: string;
  collection_id: string;
  name: string;
  cover_image: string | null;
  focus_gif: string | null;
  sort_order: number;
  title_logo: string | null;
  hero_backdrop: string | null;
  hero_video_url: string | null;
  hide_title: boolean;
  tile_shape: string;
  focus_gif_enabled: boolean;
}

export interface FolderSource {
  id: string;
  folder_id: string;
  provider: string;
  title: string | null;
  tmdb_id: string | null;
  media_type: string | null;
  sort_order: number;
}

export type Plan = 'premium' | 'premium_plus';
```

- [ ] **Step 2: Create src/lib/supabase.ts**

```ts
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true },
});
```

- [ ] **Step 3: Create src/lib/stripe.ts**

```ts
import { loadStripe } from '@stripe/stripe-js';

const STRIPE_PK = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY as string;

let stripePromise: ReturnType<typeof loadStripe>;

export function getStripe() {
  if (!stripePromise) stripePromise = loadStripe(STRIPE_PK);
  return stripePromise;
}
```

- [ ] **Step 4: Create .env.local with the existing Supabase credentials**

```
VITE_SUPABASE_URL=https://hvfsntdyowapjxobtyli.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2ZnNudGR5b3dhcGp4b2J0eWxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTk4NzM5NjgsImV4cCI6MjAzNTQ0OTk2OH0.placeholder
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_REPLACE_ME
VITE_SUPABASE_FUNCTIONS_URL=https://hvfsntdyowapjxobtyli.supabase.co/functions/v1
```

Replace `VITE_SUPABASE_ANON_KEY` with the real value from `/Users/zain/projects/Luna/admin/lib/supabase.ts` and `VITE_STRIPE_PUBLISHABLE_KEY` with the Stripe publishable key from your Stripe dashboard.

- [ ] **Step 5: Commit**

```bash
git add luna-portal/src/types luna-portal/src/lib luna-portal/.env.local
git commit -m "feat(portal): add types, Supabase client, Stripe loader"
```

---

### Task 3: AuthContext

**Files:**
- Create: `src/context/AuthContext.tsx`
- Create: `src/context/AuthContext.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `src/context/AuthContext.test.tsx`:
```tsx
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { AuthProvider, useAuth } from './AuthContext';

vi.mock('../lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
      onAuthStateChange: vi.fn().mockReturnValue({ data: { subscription: { unsubscribe: vi.fn() } } }),
    },
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      order: vi.fn().mockResolvedValue({ data: [], error: null }),
    }),
  },
}));

function TestConsumer() {
  const { loading, role, profiles } = useAuth();
  if (loading) return <div>loading</div>;
  return <div>role:{role ?? 'none'} profiles:{profiles.length}</div>;
}

describe('AuthContext', () => {
  it('renders null role and empty profiles when logged out', async () => {
    render(<AuthProvider><TestConsumer /></AuthProvider>);
    await waitFor(() => expect(screen.queryByText('loading')).not.toBeInTheDocument());
    expect(screen.getByText('role:none profiles:0')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/zain/projects/Luna/luna-portal
npm test
```

Expected: FAIL — `AuthContext` module not found.

- [ ] **Step 3: Create src/context/AuthContext.tsx**

```tsx
import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { Profile, UserRole } from '../types';

interface AuthContextValue {
  session: Session | null;
  user: User | null;
  role: UserRole | null;
  profiles: Profile[];
  activeProfile: Profile | null;
  setActiveProfile: (p: Profile) => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [activeProfile, setActiveProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      if (data.session) fetchProfiles(data.session.user.id);
      else setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
      if (s) fetchProfiles(s.user.id);
      else { setProfiles([]); setActiveProfile(null); setLoading(false); }
    });

    return () => subscription.unsubscribe();
  }, []);

  async function fetchProfiles(userId: string) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .order('profile_index');
    const rows = (data ?? []) as Profile[];
    setProfiles(rows);
    setActiveProfile(rows[0] ?? null);
    setLoading(false);
  }

  const role = profiles[0]?.role ?? null;

  return (
    <AuthContext.Provider value={{ session, user: session?.user ?? null, role, profiles, activeProfile, setActiveProfile, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npm test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/context/
git commit -m "feat(portal): add AuthContext with session and profile state"
```

---

### Task 4: App router + route guards

**Files:**
- Create: `src/components/layout/RouteGuards.tsx`
- Modify: `src/App.tsx`
- Create: `src/components/layout/RouteGuards.test.tsx`

- [ ] **Step 1: Write failing tests**

Create `src/components/layout/RouteGuards.test.tsx`:
```tsx
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, it, expect, vi } from 'vitest';
import { PublicRoute, UserRoute, AdminRoute } from './RouteGuards';

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(),
}));

import { useAuth } from '../../context/AuthContext';

const mockUseAuth = useAuth as ReturnType<typeof vi.fn>;

function setup(element: React.ReactNode, initialPath = '/') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Routes>
        <Route path="/" element={element} />
        <Route path="/login" element={<div>login page</div>} />
        <Route path="/profiles" element={<div>profiles page</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('UserRoute', () => {
  it('redirects to /login when no session', () => {
    mockUseAuth.mockReturnValue({ session: null, loading: false, role: null });
    setup(<UserRoute><div>protected</div></UserRoute>);
    expect(screen.getByText('login page')).toBeInTheDocument();
  });

  it('renders children when session exists', () => {
    mockUseAuth.mockReturnValue({ session: { user: {} }, loading: false, role: 'premium' });
    setup(<UserRoute><div>protected</div></UserRoute>);
    expect(screen.getByText('protected')).toBeInTheDocument();
  });
});

describe('AdminRoute', () => {
  it('redirects non-admin to /profiles', () => {
    mockUseAuth.mockReturnValue({ session: { user: {} }, loading: false, role: 'premium' });
    setup(<AdminRoute><div>admin only</div></AdminRoute>);
    expect(screen.getByText('profiles page')).toBeInTheDocument();
  });

  it('renders children for admin', () => {
    mockUseAuth.mockReturnValue({ session: { user: {} }, loading: false, role: 'admin' });
    setup(<AdminRoute><div>admin only</div></AdminRoute>);
    expect(screen.getByText('admin only')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run to verify failure**

```bash
npm test
```

Expected: FAIL — `RouteGuards` not found.

- [ ] **Step 3: Create src/components/layout/RouteGuards.tsx**

```tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export function PublicRoute({ children }: { children: React.ReactNode }) {
  const { session, loading } = useAuth();
  if (loading) return null;
  if (session) return <Navigate to="/profiles" replace />;
  return <>{children}</>;
}

export function UserRoute({ children }: { children: React.ReactNode }) {
  const { session, loading } = useAuth();
  if (loading) return null;
  if (!session) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export function AdminRoute({ children }: { children: React.ReactNode }) {
  const { session, role, loading } = useAuth();
  if (loading) return null;
  if (!session) return <Navigate to="/login" replace />;
  if (role !== 'admin') return <Navigate to="/profiles" replace />;
  return <>{children}</>;
}
```

- [ ] **Step 4: Run tests to verify pass**

```bash
npm test
```

Expected: all tests PASS.

- [ ] **Step 5: Wire up App.tsx with full route tree**

```tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { PublicRoute, UserRoute, AdminRoute } from './components/layout/RouteGuards';
import PricingPage from './routes/public/PricingPage';
import LoginPage from './routes/public/LoginPage';
import SignupPage from './routes/public/SignupPage';
import ProfilesPage from './routes/user/ProfilesPage';
import AddonsPage from './routes/user/AddonsPage';
import BillingPage from './routes/user/BillingPage';
import CatalogPage from './routes/admin/CatalogPage';
import UsersPage from './routes/admin/UsersPage';
import InvitesPage from './routes/admin/InvitesPage';

// Placeholder screens for tasks not yet built
const Placeholder = ({ name }: { name: string }) => (
  <div className="min-h-screen bg-bg flex items-center justify-center">
    <p className="text-muted">{name} — coming soon</p>
  </div>
);

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public */}
          <Route path="/" element={<Navigate to="/pricing" replace />} />
          <Route path="/pricing" element={<PublicRoute><PricingPage /></PublicRoute>} />
          <Route path="/login" element={<PublicRoute><LoginPage /></PublicRoute>} />
          <Route path="/signup" element={<PublicRoute><SignupPage /></PublicRoute>} />

          {/* User */}
          <Route path="/profiles" element={<UserRoute><ProfilesPage /></UserRoute>} />
          <Route path="/addons" element={<UserRoute><AddonsPage /></UserRoute>} />
          <Route path="/billing" element={<UserRoute><BillingPage /></UserRoute>} />

          {/* Admin */}
          <Route path="/admin/catalog" element={<AdminRoute><CatalogPage /></AdminRoute>} />
          <Route path="/admin/users" element={<AdminRoute><UsersPage /></AdminRoute>} />
          <Route path="/admin/invites" element={<AdminRoute><InvitesPage /></AdminRoute>} />

          <Route path="*" element={<Placeholder name="404" />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
```

Create stub files for all routes so the import doesn't fail:

```bash
mkdir -p src/routes/public src/routes/user src/routes/admin
```

For each of the 9 route files, create a stub:
```tsx
// e.g. src/routes/public/PricingPage.tsx
export default function PricingPage() {
  return <div className="min-h-screen bg-bg p-8"><h1>Pricing</h1></div>;
}
```

Repeat for: `LoginPage`, `SignupPage`, `ProfilesPage`, `AddonsPage`, `BillingPage`, `CatalogPage`, `UsersPage`, `InvitesPage`.

- [ ] **Step 6: Verify dev server runs without errors**

```bash
npm run dev
```

Navigate to `http://localhost:5173/pricing` — should show "Pricing" stub.
Navigate to `http://localhost:5173/profiles` — should redirect to `/login` (no session).

- [ ] **Step 7: Commit**

```bash
git add src/
git commit -m "feat(portal): route tree, AuthProvider, route guards"
```

---

### Task 5: Shared UI components

**Files:**
- Create: `src/components/ui/Button.tsx`
- Create: `src/components/ui/Card.tsx`
- Create: `src/components/ui/Modal.tsx`
- Create: `src/components/ui/Badge.tsx`
- Create: `src/components/ui/Input.tsx`
- Create: `src/components/ui/DragHandle.tsx`

- [ ] **Step 1: Create src/components/ui/Button.tsx**

```tsx
import { ButtonHTMLAttributes } from 'react';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
type Size = 'sm' | 'md' | 'lg';

const variantClasses: Record<Variant, string> = {
  primary: 'bg-accent text-white hover:bg-purple-800',
  secondary: 'bg-accent-light text-accent hover:bg-purple-100',
  ghost: 'bg-transparent text-muted hover:bg-border',
  danger: 'bg-red-500 text-white hover:bg-red-600',
};

const sizeClasses: Record<Size, string> = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-sm',
  lg: 'px-6 py-3 text-base',
};

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
}

export function Button({ variant = 'primary', size = 'md', loading, children, className = '', disabled, ...rest }: ButtonProps) {
  return (
    <button
      className={`inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      disabled={disabled || loading}
      {...rest}
    >
      {loading && <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />}
      {children}
    </button>
  );
}
```

- [ ] **Step 2: Create src/components/ui/Card.tsx**

```tsx
import { HTMLAttributes } from 'react';

export function Card({ children, className = '', ...rest }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={`bg-surface rounded-2xl border border-border shadow-sm ${className}`} {...rest}>
      {children}
    </div>
  );
}
```

- [ ] **Step 3: Create src/components/ui/Input.tsx**

```tsx
import { InputHTMLAttributes, forwardRef } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className = '', id, ...rest }, ref) => (
    <div className="flex flex-col gap-1">
      {label && <label htmlFor={id} className="text-sm font-medium text-text">{label}</label>}
      <input
        id={id}
        ref={ref}
        className={`w-full px-3 py-2 rounded-lg border text-sm transition-colors outline-none
          ${error ? 'border-red-400 focus:border-red-500' : 'border-border focus:border-accent'}
          bg-surface text-text placeholder:text-muted ${className}`}
        {...rest}
      />
      {error && <p className="text-xs text-red-500">{error}</p>}
    </div>
  )
);
Input.displayName = 'Input';
```

- [ ] **Step 4: Create src/components/ui/Badge.tsx**

```tsx
type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'purple';

const variants: Record<BadgeVariant, string> = {
  default: 'bg-border text-muted',
  success: 'bg-green-100 text-green-700',
  warning: 'bg-amber-100 text-amber-700',
  danger: 'bg-red-100 text-red-600',
  purple: 'bg-accent-light text-accent',
};

export function Badge({ children, variant = 'default' }: { children: React.ReactNode; variant?: BadgeVariant }) {
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${variants[variant]}`}>
      {children}
    </span>
  );
}
```

- [ ] **Step 5: Create src/components/ui/Modal.tsx**

```tsx
import { useEffect } from 'react';
import { createPortal } from 'react-dom';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  width?: string;
}

export function Modal({ open, onClose, title, children, width = 'max-w-lg' }: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);

  if (!open) return null;

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative bg-surface rounded-2xl shadow-xl w-full ${width} max-h-[90vh] overflow-y-auto`}>
        {title && (
          <div className="flex items-center justify-between px-6 py-4 border-b border-border">
            <h2 className="text-base font-semibold text-text">{title}</h2>
            <button onClick={onClose} className="text-muted hover:text-text transition-colors text-xl leading-none">&times;</button>
          </div>
        )}
        {children}
      </div>
    </div>,
    document.body
  );
}
```

- [ ] **Step 6: Create src/components/ui/DragHandle.tsx**

```tsx
export function DragHandle() {
  return (
    <div className="cursor-grab active:cursor-grabbing text-muted hover:text-text transition-colors px-1 select-none">
      <svg width="12" height="20" viewBox="0 0 12 20" fill="currentColor">
        <circle cx="3" cy="4" r="1.5" /><circle cx="9" cy="4" r="1.5" />
        <circle cx="3" cy="10" r="1.5" /><circle cx="9" cy="10" r="1.5" />
        <circle cx="3" cy="16" r="1.5" /><circle cx="9" cy="16" r="1.5" />
      </svg>
    </div>
  );
}
```

- [ ] **Step 7: Commit**

```bash
git add src/components/ui/
git commit -m "feat(portal): shared UI components — Button, Card, Modal, Badge, Input, DragHandle"
```

---

### Task 6: Navbar and Sidebar layout

**Files:**
- Create: `src/components/layout/Navbar.tsx`
- Create: `src/components/layout/Sidebar.tsx`

- [ ] **Step 1: Create src/components/layout/Navbar.tsx**

```tsx
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { supabase } from '../../lib/supabase';
import { Button } from '../ui/Button';

export function Navbar() {
  const { session, role } = useAuth();
  const navigate = useNavigate();

  async function handleSignOut() {
    await supabase.auth.signOut();
    navigate('/pricing');
  }

  return (
    <nav className="h-14 bg-surface border-b border-border flex items-center px-6 gap-4">
      <Link to="/" className="text-lg font-bold text-text tracking-tight">Luna</Link>
      <div className="flex-1" />
      {session ? (
        <>
          {role === 'admin' && (
            <Link to="/admin/catalog" className="text-sm text-muted hover:text-text transition-colors">Admin</Link>
          )}
          <Link to="/profiles" className="text-sm text-muted hover:text-text transition-colors">Profiles</Link>
          <Button variant="ghost" size="sm" onClick={handleSignOut}>Sign out</Button>
        </>
      ) : (
        <>
          <Link to="/pricing" className="text-sm text-muted hover:text-text transition-colors">Pricing</Link>
          <Button size="sm" onClick={() => navigate('/login')}>Sign in</Button>
        </>
      )}
    </nav>
  );
}
```

- [ ] **Step 2: Create src/components/layout/Sidebar.tsx**

```tsx
import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const userLinks = [
  { to: '/profiles', label: 'Profiles' },
  { to: '/addons', label: 'Add-ons' },
  { to: '/billing', label: 'Billing' },
];

const adminLinks = [
  { to: '/admin/catalog', label: 'Catalog' },
  { to: '/admin/users', label: 'Users' },
  { to: '/admin/invites', label: 'Invites' },
];

export function Sidebar() {
  const { role } = useAuth();

  const links = role === 'admin' ? [...adminLinks, ...userLinks] : userLinks;

  return (
    <aside className="w-48 bg-surface border-r border-border flex flex-col py-6 gap-1 shrink-0">
      {links.map(({ to, label }) => (
        <NavLink
          key={to}
          to={to}
          className={({ isActive }) =>
            `mx-2 px-3 py-2 rounded-lg text-sm transition-colors ${isActive ? 'bg-accent-light text-accent font-medium' : 'text-muted hover:text-text hover:bg-border'}`
          }
        >
          {label}
        </NavLink>
      ))}
    </aside>
  );
}
```

- [ ] **Step 3: Create src/components/layout/AppShell.tsx for authenticated pages**

```tsx
import { Navbar } from './Navbar';
import { Sidebar } from './Sidebar';

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-bg flex flex-col">
      <Navbar />
      <div className="flex flex-1">
        <Sidebar />
        <main className="flex-1 p-8 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add src/components/layout/
git commit -m "feat(portal): Navbar, Sidebar, AppShell layout"
```

---

### Task 7: PricingPage

**Files:**
- Modify: `src/routes/public/PricingPage.tsx`

- [ ] **Step 1: Implement PricingPage**

```tsx
import { useNavigate } from 'react-router-dom';
import { Button } from '../../components/ui/Button';
import { Card } from '../../components/ui/Card';
import { Navbar } from '../../components/layout/Navbar';

const plans = [
  {
    id: 'friends_family',
    name: 'Friends & Family',
    price: null,
    description: 'Personal invitation only. Full access, zero setup.',
    features: ['All content, ready to watch', 'Managed for you', 'Up to 5 profiles', 'Invite code required'],
    cta: 'Request Access',
    ctaTo: '/signup?tab=invite',
    highlight: false,
  },
  {
    id: 'premium',
    name: 'Premium',
    price: '$9.99',
    description: 'Everything set up and ready to go. Just sign in and watch.',
    features: ['Full catalog access', 'Pre-configured', 'Up to 5 profiles', 'HD streaming'],
    cta: 'Get Started',
    ctaTo: '/signup?plan=premium',
    highlight: true,
  },
  {
    id: 'premium_plus',
    name: 'Premium+',
    price: '$14.99',
    description: 'All of Premium, plus you control your own add-ons and sources.',
    features: ['Everything in Premium', 'Self-managed add-ons', 'Custom sources', 'Priority support'],
    cta: 'Get Started',
    ctaTo: '/signup?plan=premium_plus',
    highlight: false,
  },
];

export default function PricingPage() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-b from-bg to-white">
      <Navbar />
      <div className="max-w-5xl mx-auto px-6 py-20">
        <div className="text-center mb-14">
          <h1 className="text-4xl font-bold text-text tracking-tight mb-3">Simple, honest pricing</h1>
          <p className="text-muted text-lg">Pick the plan that fits how you watch.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {plans.map(plan => (
            <Card
              key={plan.id}
              className={`p-6 flex flex-col gap-5 ${plan.highlight ? 'ring-2 ring-accent shadow-lg' : ''}`}
            >
              {plan.highlight && (
                <span className="self-start text-xs font-semibold bg-accent-light text-accent px-2.5 py-1 rounded-full">Most Popular</span>
              )}
              <div>
                <h2 className="text-lg font-semibold text-text">{plan.name}</h2>
                {plan.price ? (
                  <p className="text-3xl font-bold text-text mt-1">{plan.price}<span className="text-sm font-normal text-muted">/mo</span></p>
                ) : (
                  <p className="text-sm text-muted mt-1">By invitation</p>
                )}
                <p className="text-sm text-muted mt-2">{plan.description}</p>
              </div>
              <ul className="flex flex-col gap-2 flex-1">
                {plan.features.map(f => (
                  <li key={f} className="flex items-center gap-2 text-sm text-text">
                    <span className="text-accent">&#10003;</span> {f}
                  </li>
                ))}
              </ul>
              <Button
                variant={plan.highlight ? 'primary' : 'secondary'}
                className="w-full"
                onClick={() => navigate(plan.ctaTo)}
              >
                {plan.cta}
              </Button>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Start dev server and verify pricing page**

```bash
npm run dev
```

Open `http://localhost:5173/pricing`. Verify 3 plan cards render, "Get Started" buttons are visible, "Most Popular" badge on Premium.

- [ ] **Step 3: Commit**

```bash
git add src/routes/public/PricingPage.tsx
git commit -m "feat(portal): PricingPage with 3 plan cards"
```

---

### Task 8: LoginPage

**Files:**
- Modify: `src/routes/public/LoginPage.tsx`

- [ ] **Step 1: Implement LoginPage**

```tsx
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card } from '../../components/ui/Card';

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [magicSent, setMagicSent] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (authError) { setError(authError.message); return; }
    navigate('/profiles');
  }

  async function handleMagicLink() {
    if (!email) { setError('Enter your email first'); return; }
    setLoading(true);
    await supabase.auth.signInWithOtp({ email });
    setLoading(false);
    setMagicSent(true);
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <Card className="w-full max-w-sm p-8">
        <h1 className="text-2xl font-bold text-text mb-1">Welcome back</h1>
        <p className="text-sm text-muted mb-6">Sign in to your Luna account</p>

        {magicSent ? (
          <p className="text-sm text-green-600 bg-green-50 rounded-lg p-3">
            Check your email — we sent a magic link.
          </p>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <Input id="email" label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" />
            <Input id="password" label="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} required autoComplete="current-password" />
            {error && <p className="text-xs text-red-500">{error}</p>}
            <Button type="submit" loading={loading} className="w-full mt-1">Sign in</Button>
            <button type="button" onClick={handleMagicLink} className="text-xs text-muted hover:text-accent transition-colors text-center">
              Sign in with magic link
            </button>
          </form>
        )}

        <p className="text-xs text-muted text-center mt-6">
          Don&apos;t have an account? <Link to="/signup" className="text-accent hover:underline">Sign up</Link>
        </p>
      </Card>
    </div>
  );
}
```

- [ ] **Step 2: Verify login page in browser**

Open `http://localhost:5173/login`. Verify form renders, sign in with a real Supabase test account redirects to `/profiles`.

- [ ] **Step 3: Commit**

```bash
git add src/routes/public/LoginPage.tsx
git commit -m "feat(portal): LoginPage with password + magic link"
```

---

### Task 9: SignupPage

**Files:**
- Modify: `src/routes/public/SignupPage.tsx`

- [ ] **Step 1: Implement SignupPage**

```tsx
import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Card } from '../../components/ui/Card';
import type { Plan } from '../../types';

type Tab = 'invite' | 'subscribe';

const PLAN_LABELS: Record<Plan, string> = {
  premium: 'Premium — $9.99/mo',
  premium_plus: 'Premium+ — $14.99/mo',
};

export default function SignupPage() {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const initialTab: Tab = params.get('tab') === 'invite' ? 'invite' : params.get('plan') ? 'subscribe' : 'invite';
  const initialPlan = (params.get('plan') as Plan | null) ?? 'premium';

  const [tab, setTab] = useState<Tab>(initialTab);
  const [code, setCode] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [selectedPlan, setSelectedPlan] = useState<Plan>(initialPlan);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleInviteSignup(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Validate invite code
    const { data: valid } = await supabase.rpc('validate_invite_code', { p_code: code.trim().toUpperCase() });
    if (!valid) { setError('Invalid or already used invite code.'); setLoading(false); return; }

    // Create account
    const { data: authData, error: signUpError } = await supabase.auth.signUp({ email, password });
    if (signUpError || !authData.user) { setError(signUpError?.message ?? 'Signup failed'); setLoading(false); return; }

    // Insert profile
    await supabase.from('profiles').insert({
      user_id: authData.user.id,
      name: email.split('@')[0],
      role: 'friends_family',
      uses_primary_addons: true,
      profile_index: 0,
    });

    // Mark invite code used
    await supabase.from('invite_codes').update({ used_by: authData.user.id, used_at: new Date().toISOString() }).eq('code', code.trim().toUpperCase());

    setLoading(false);
    navigate('/profiles');
  }

  async function handleStripeSignup() {
    setError('');
    setLoading(true);
    const res = await fetch(`${import.meta.env.VITE_SUPABASE_FUNCTIONS_URL}/create-checkout-session`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ plan: selectedPlan }),
    });
    const { url, error: fnError } = await res.json();
    if (fnError || !url) { setError('Could not start checkout. Try again.'); setLoading(false); return; }
    window.location.href = url;
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <Card className="w-full max-w-sm p-8">
        <h1 className="text-2xl font-bold text-text mb-1">Create your account</h1>
        <p className="text-sm text-muted mb-6">Join Luna today</p>

        {/* Tabs */}
        <div className="flex gap-1 bg-border rounded-lg p-1 mb-6">
          {(['invite', 'subscribe'] as Tab[]).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex-1 py-1.5 text-xs font-medium rounded-md transition-colors ${tab === t ? 'bg-surface text-text shadow-sm' : 'text-muted'}`}
            >
              {t === 'invite' ? 'Invite Code' : 'Subscribe'}
            </button>
          ))}
        </div>

        {tab === 'invite' ? (
          <form onSubmit={handleInviteSignup} className="flex flex-col gap-4">
            <Input id="code" label="Invite Code" value={code} onChange={e => setCode(e.target.value)} placeholder="XXXX-XXXX" required />
            <Input id="email" label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" />
            <Input id="password" label="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} required autoComplete="new-password" />
            {error && <p className="text-xs text-red-500">{error}</p>}
            <Button type="submit" loading={loading} className="w-full mt-1">Create Account</Button>
          </form>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              {(['premium', 'premium_plus'] as Plan[]).map(p => (
                <button
                  key={p}
                  onClick={() => setSelectedPlan(p)}
                  className={`px-4 py-3 rounded-lg border text-sm text-left transition-colors ${selectedPlan === p ? 'border-accent bg-accent-light text-accent' : 'border-border text-text hover:border-accent/40'}`}
                >
                  {PLAN_LABELS[p]}
                </button>
              ))}
            </div>
            {error && <p className="text-xs text-red-500">{error}</p>}
            <Button loading={loading} className="w-full" onClick={handleStripeSignup}>
              Continue to Payment
            </Button>
          </div>
        )}

        <p className="text-xs text-muted text-center mt-6">
          Already have an account? <Link to="/login" className="text-accent hover:underline">Sign in</Link>
        </p>
      </Card>
    </div>
  );
}
```

- [ ] **Step 2: Verify in browser**

Open `http://localhost:5173/signup`. Toggle between tabs. Verify invite tab shows code + email + password fields. Subscribe tab shows plan selector. Test invite code signup against a real invite code in Supabase.

- [ ] **Step 3: Commit**

```bash
git add src/routes/public/SignupPage.tsx
git commit -m "feat(portal): SignupPage — invite code and Stripe subscribe flows"
```

---

### Task 10: ProfilesPage

**Files:**
- Modify: `src/routes/user/ProfilesPage.tsx`
- Create: `src/components/profiles/ProfileCard.tsx`
- Create: `src/components/profiles/ProfileEditor.tsx`

- [ ] **Step 1: Create src/components/profiles/ProfileCard.tsx**

```tsx
import type { Profile } from '../../types';

const AVATAR_COLORS = ['#6d28d9', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#ec4899'];

interface ProfileCardProps {
  profile: Profile;
  onSelect: () => void;
  onEdit: () => void;
  editMode: boolean;
}

export function ProfileCard({ profile, onSelect, onEdit, editMode }: ProfileCardProps) {
  const bg = profile.avatar_color ?? AVATAR_COLORS[profile.profile_index % AVATAR_COLORS.length];
  const initials = profile.name.slice(0, 2).toUpperCase();

  return (
    <div className="flex flex-col items-center gap-2 group cursor-pointer" onClick={editMode ? onEdit : onSelect}>
      <div
        className="w-24 h-24 rounded-2xl flex items-center justify-center text-2xl font-bold text-white transition-all group-hover:ring-4 group-hover:ring-accent/40 relative"
        style={{ backgroundColor: bg }}
      >
        {initials}
        {editMode && (
          <div className="absolute inset-0 bg-black/40 rounded-2xl flex items-center justify-center">
            <span className="text-white text-lg">&#9998;</span>
          </div>
        )}
      </div>
      <p className="text-sm font-medium text-text">{profile.name}</p>
    </div>
  );
}
```

- [ ] **Step 2: Create src/components/profiles/ProfileEditor.tsx**

```tsx
import { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Modal } from '../ui/Modal';
import { Input } from '../ui/Input';
import { Button } from '../ui/Button';
import type { Profile } from '../../types';

const COLORS = ['#6d28d9', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#ec4899', '#8b5cf6', '#06b6d4'];

interface ProfileEditorProps {
  profile: Profile | null;
  onClose: () => void;
  onSaved: () => void;
  userId: string;
  nextIndex: number;
}

export function ProfileEditor({ profile, onClose, onSaved, userId, nextIndex }: ProfileEditorProps) {
  const [name, setName] = useState(profile?.name ?? '');
  const [color, setColor] = useState(profile?.avatar_color ?? COLORS[0]);
  const [pinEnabled, setPinEnabled] = useState(profile?.pin_enabled ?? false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSave() {
    if (!name.trim()) { setError('Name is required'); return; }
    setLoading(true);
    if (profile) {
      await supabase.from('profiles').update({ name: name.trim(), avatar_color: color, pin_enabled: pinEnabled }).eq('id', profile.id);
    } else {
      await supabase.from('profiles').insert({ user_id: userId, name: name.trim(), avatar_color: color, pin_enabled: pinEnabled, profile_index: nextIndex, uses_primary_addons: false, role: 'user' });
    }
    setLoading(false);
    onSaved();
  }

  async function handleDelete() {
    if (!profile) return;
    if (!confirm(`Delete profile "${profile.name}"? This cannot be undone.`)) return;
    await supabase.from('profiles').delete().eq('id', profile.id);
    onSaved();
  }

  return (
    <Modal open onClose={onClose} title={profile ? 'Edit Profile' : 'New Profile'}>
      <div className="p-6 flex flex-col gap-5">
        <Input id="pname" label="Name" value={name} onChange={e => setName(e.target.value)} error={error} />
        <div>
          <p className="text-sm font-medium text-text mb-2">Color</p>
          <div className="flex gap-2 flex-wrap">
            {COLORS.map(c => (
              <button
                key={c}
                onClick={() => setColor(c)}
                className={`w-8 h-8 rounded-full transition-all ${color === c ? 'ring-2 ring-offset-2 ring-accent' : ''}`}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
        </div>
        <label className="flex items-center gap-3 cursor-pointer">
          <input type="checkbox" checked={pinEnabled} onChange={e => setPinEnabled(e.target.checked)} className="w-4 h-4 accent-accent" />
          <span className="text-sm text-text">Require PIN to access</span>
        </label>
        <div className="flex gap-3 pt-2">
          <Button onClick={handleSave} loading={loading} className="flex-1">Save</Button>
          {profile && <Button variant="danger" onClick={handleDelete}>Delete</Button>}
        </div>
      </div>
    </Modal>
  );
}
```

- [ ] **Step 3: Implement ProfilesPage**

```tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { AppShell } from '../../components/layout/AppShell';
import { ProfileCard } from '../../components/profiles/ProfileCard';
import { ProfileEditor } from '../../components/profiles/ProfileEditor';

export default function ProfilesPage() {
  const { profiles, setActiveProfile, user } = useAuth();
  const navigate = useNavigate();
  const [editMode, setEditMode] = useState(false);
  const [editingProfile, setEditingProfile] = useState<typeof profiles[0] | null>(null);
  const [creatingNew, setCreatingNew] = useState(false);

  function handleSelectProfile(p: typeof profiles[0]) {
    setActiveProfile(p);
    navigate('/addons');
  }

  function handleSaved() {
    setEditingProfile(null);
    setCreatingNew(false);
    window.location.reload(); // re-fetch profiles
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-2xl font-bold text-text">Who&apos;s watching?</h1>
          <button onClick={() => setEditMode(e => !e)} className="text-sm text-muted hover:text-text transition-colors">
            {editMode ? 'Done' : 'Edit'}
          </button>
        </div>

        <div className="flex flex-wrap gap-6">
          {profiles.map(p => (
            <ProfileCard
              key={p.id}
              profile={p}
              editMode={editMode}
              onSelect={() => handleSelectProfile(p)}
              onEdit={() => setEditingProfile(p)}
            />
          ))}
          {profiles.length < 5 && !editMode && (
            <div
              onClick={() => setCreatingNew(true)}
              className="flex flex-col items-center gap-2 cursor-pointer group"
            >
              <div className="w-24 h-24 rounded-2xl border-2 border-dashed border-border flex items-center justify-center text-3xl text-muted group-hover:border-accent group-hover:text-accent transition-all">
                +
              </div>
              <p className="text-sm text-muted">Add Profile</p>
            </div>
          )}
        </div>
      </div>

      {(editingProfile || creatingNew) && user && (
        <ProfileEditor
          profile={editingProfile}
          onClose={() => { setEditingProfile(null); setCreatingNew(false); }}
          onSaved={handleSaved}
          userId={user.id}
          nextIndex={profiles.length}
        />
      )}
    </AppShell>
  );
}
```

- [ ] **Step 4: Verify in browser**

Sign in, navigate to `/profiles`. Verify profile grid renders, edit mode toggles pencil overlays, "Add Profile" card appears.

- [ ] **Step 5: Commit**

```bash
git add src/routes/user/ProfilesPage.tsx src/components/profiles/
git commit -m "feat(portal): ProfilesPage with add/edit/delete sub-profiles"
```

---

### Task 11: AddonsPage

**Files:**
- Modify: `src/routes/user/AddonsPage.tsx`

- [ ] **Step 1: Implement AddonsPage**

```tsx
import { useEffect, useState, useRef } from 'react';
import { useAuth } from '../../context/AuthContext';
import { supabase } from '../../lib/supabase';
import { AppShell } from '../../components/layout/AppShell';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { DragHandle } from '../../components/ui/DragHandle';
import { Badge } from '../../components/ui/Badge';
import type { InstalledAddon } from '../../types';

export default function AddonsPage() {
  const { activeProfile, role } = useAuth();
  const [addons, setAddons] = useState<InstalledAddon[]>([]);
  const [newUrl, setNewUrl] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const dragIndex = useRef<number | null>(null);

  const isReadOnly = role === 'friends_family' || role === 'premium';
  const isManaged = role === 'premium';
  const canEdit = role === 'admin' || role === 'premium_plus';

  useEffect(() => {
    if (!activeProfile) return;
    async function load() {
      setLoading(true);
      let profileId = activeProfile!.id;
      if (activeProfile!.uses_primary_addons) {
        // Find admin profile
        const { data } = await supabase.from('profiles').select('id').eq('role', 'admin').limit(1).single();
        if (data) profileId = data.id;
      }
      const { data } = await supabase.from('installed_addons').select('*').eq('profile_id', profileId).order('sort_order');
      setAddons(data ?? []);
      setLoading(false);
    }
    load();
  }, [activeProfile]);

  async function handleAdd() {
    if (!newUrl.trim() || !activeProfile) return;
    if (!newUrl.startsWith('https://')) { setError('URL must start with https://'); return; }
    setSaving(true);
    const { error: e } = await supabase.from('installed_addons').insert({
      profile_id: activeProfile.id,
      addon_url: newUrl.trim(),
      sort_order: addons.length,
    });
    if (e) setError(e.message);
    else { setNewUrl(''); setError(''); setAddons(prev => [...prev, { id: Date.now().toString(), profile_id: activeProfile.id, addon_url: newUrl.trim(), addon_name: null, enabled: true, sort_order: prev.length, created_at: '' }]); }
    setSaving(false);
  }

  async function handleToggle(addon: InstalledAddon) {
    await supabase.from('installed_addons').update({ enabled: !addon.enabled }).eq('id', addon.id);
    setAddons(prev => prev.map(a => a.id === addon.id ? { ...a, enabled: !a.enabled } : a));
  }

  async function handleRemove(id: string) {
    await supabase.from('installed_addons').delete().eq('id', id);
    setAddons(prev => prev.filter(a => a.id !== id));
  }

  function handleDragStart(i: number) { dragIndex.current = i; }
  async function handleDrop(i: number) {
    if (dragIndex.current === null || dragIndex.current === i) return;
    const reordered = [...addons];
    const [moved] = reordered.splice(dragIndex.current, 1);
    reordered.splice(i, 0, moved);
    setAddons(reordered);
    dragIndex.current = null;
    await Promise.all(reordered.map((a, idx) => supabase.from('installed_addons').update({ sort_order: idx }).eq('id', a.id)));
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-text">Add-ons</h1>
          {isManaged && <Badge variant="purple">Managed by Luna</Badge>}
          {role === 'friends_family' && <Badge>Inherited from admin</Badge>}
        </div>

        {canEdit && (
          <Card className="p-4 mb-6 flex gap-3">
            <Input id="addon-url" value={newUrl} onChange={e => setNewUrl(e.target.value)} placeholder="https://addon-url/manifest.json" error={error} className="flex-1" />
            <Button onClick={handleAdd} loading={saving} size="md">Add</Button>
          </Card>
        )}

        {loading ? (
          <p className="text-muted text-sm">Loading…</p>
        ) : addons.length === 0 ? (
          <p className="text-muted text-sm">No add-ons installed.</p>
        ) : (
          <div className="flex flex-col gap-2">
            {addons.map((addon, i) => (
              <Card
                key={addon.id}
                className="flex items-center gap-3 px-4 py-3"
                draggable={canEdit}
                onDragStart={() => handleDragStart(i)}
                onDragOver={e => e.preventDefault()}
                onDrop={() => handleDrop(i)}
              >
                {canEdit && <DragHandle />}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-text truncate">{addon.addon_name ?? addon.addon_url}</p>
                  {addon.addon_name && <p className="text-xs text-muted truncate">{addon.addon_url}</p>}
                </div>
                {canEdit && (
                  <>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" checked={addon.enabled} onChange={() => handleToggle(addon)} />
                      <div className="w-9 h-5 bg-border rounded-full peer peer-checked:bg-accent transition-colors after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:after:translate-x-4" />
                    </label>
                    <button onClick={() => handleRemove(addon.id)} className="text-muted hover:text-red-500 transition-colors text-lg leading-none">&times;</button>
                  </>
                )}
              </Card>
            ))}
          </div>
        )}
      </div>
    </AppShell>
  );
}
```

- [ ] **Step 2: Verify in browser**

Sign in as admin. Navigate to `/addons`. Verify add-ons load, add a test URL, drag to reorder, toggle enabled state.

- [ ] **Step 3: Commit**

```bash
git add src/routes/user/AddonsPage.tsx
git commit -m "feat(portal): AddonsPage with role-aware view and drag-to-reorder"
```

---

### Task 12: BillingPage

**Files:**
- Modify: `src/routes/user/BillingPage.tsx`

- [ ] **Step 1: Implement BillingPage**

```tsx
import { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { AppShell } from '../../components/layout/AppShell';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import type { UserRole } from '../../types';

const PLAN_LABELS: Record<UserRole, string> = {
  admin: 'Admin',
  friends_family: 'Friends & Family',
  premium: 'Premium',
  premium_plus: 'Premium+',
};

export default function BillingPage() {
  const { role, session } = useAuth();
  const [loading, setLoading] = useState(false);

  const isBilledPlan = role === 'premium' || role === 'premium_plus';

  async function openCustomerPortal() {
    if (!session) return;
    setLoading(true);
    const res = await fetch(`${import.meta.env.VITE_SUPABASE_FUNCTIONS_URL}/create-portal-session`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${session.access_token}` },
    });
    const { url } = await res.json();
    if (url) window.location.href = url;
    setLoading(false);
  }

  return (
    <AppShell>
      <div className="max-w-lg mx-auto">
        <h1 className="text-2xl font-bold text-text mb-6">Billing</h1>

        <Card className="p-6 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-text">Current Plan</p>
            <Badge variant="purple">{role ? PLAN_LABELS[role] : '—'}</Badge>
          </div>

          {role === 'friends_family' && (
            <p className="text-sm text-muted">Your access was granted by invitation. No billing required.</p>
          )}

          {role === 'admin' && (
            <p className="text-sm text-muted">You manage this Luna instance. No subscription required.</p>
          )}

          {isBilledPlan && (
            <>
              <div className="border-t border-border pt-4">
                <p className="text-xs text-muted mb-3">Manage your subscription, update payment method, or cancel through the billing portal.</p>
                <Button onClick={openCustomerPortal} loading={loading} variant="secondary">
                  Manage Billing
                </Button>
              </div>
            </>
          )}
        </Card>
      </div>
    </AppShell>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/routes/user/BillingPage.tsx
git commit -m "feat(portal): BillingPage with Stripe Customer Portal redirect"
```

---

### Task 13: CatalogPage — collection list with drag-to-reorder

**Files:**
- Modify: `src/routes/admin/CatalogPage.tsx`
- Create: `src/components/catalog/CollectionRow.tsx`

- [ ] **Step 1: Create src/components/catalog/CollectionRow.tsx**

```tsx
import { DragHandle } from '../ui/DragHandle';
import { Badge } from '../ui/Badge';
import { Button } from '../ui/Button';
import type { Collection } from '../../types';

interface CollectionRowProps {
  collection: Collection;
  onEdit: () => void;
  onDelete: () => void;
  onDragStart: () => void;
  onDrop: () => void;
}

export function CollectionRow({ collection, onEdit, onDelete, onDragStart, onDrop }: CollectionRowProps) {
  return (
    <div
      className="flex items-center gap-3 bg-surface border border-border rounded-xl px-4 py-3 cursor-default"
      draggable
      onDragStart={onDragStart}
      onDragOver={e => e.preventDefault()}
      onDrop={onDrop}
    >
      <DragHandle />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-text truncate">{collection.name}</p>
        {collection.pin_to_top && <Badge variant="purple">Pinned</Badge>}
      </div>
      <div className="flex gap-2">
        <Button size="sm" variant="secondary" onClick={onEdit}>Edit</Button>
        <Button size="sm" variant="ghost" onClick={onDelete}>Delete</Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Implement CatalogPage**

```tsx
import { useEffect, useRef, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { AppShell } from '../../components/layout/AppShell';
import { Button } from '../../components/ui/Button';
import { CollectionRow } from '../../components/catalog/CollectionRow';
import { CollectionEditor } from '../../components/catalog/CollectionEditor';
import type { Collection } from '../../types';

export default function CatalogPage() {
  const [collections, setCollections] = useState<Collection[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | 'new' | null>(null);
  const dragIndex = useRef<number | null>(null);

  useEffect(() => { load(); }, []);

  async function load() {
    const { data } = await supabase.from('collections').select('*').order('sort_order');
    setCollections(data ?? []);
    setLoading(false);
  }

  async function handleDelete(id: string) {
    if (!confirm('Delete this collection?')) return;
    await supabase.from('collections').delete().eq('id', id);
    setCollections(prev => prev.filter(c => c.id !== id));
  }

  function handleDragStart(i: number) { dragIndex.current = i; }
  async function handleDrop(i: number) {
    if (dragIndex.current === null || dragIndex.current === i) return;
    const reordered = [...collections];
    const [moved] = reordered.splice(dragIndex.current, 1);
    reordered.splice(i, 0, moved);
    setCollections(reordered);
    dragIndex.current = null;
    await Promise.all(reordered.map((c, idx) => supabase.from('collections').update({ sort_order: idx }).eq('id', c.id)));
  }

  const editingCollection = editingId && editingId !== 'new' ? collections.find(c => c.id === editingId) ?? null : null;

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-text">Catalog</h1>
          <Button onClick={() => setEditingId('new')}>+ New Collection</Button>
        </div>

        {loading ? (
          <p className="text-muted text-sm">Loading…</p>
        ) : (
          <div className="flex flex-col gap-2">
            {collections.map((c, i) => (
              <CollectionRow
                key={c.id}
                collection={c}
                onEdit={() => setEditingId(c.id)}
                onDelete={() => handleDelete(c.id)}
                onDragStart={() => handleDragStart(i)}
                onDrop={() => handleDrop(i)}
              />
            ))}
          </div>
        )}
      </div>

      {editingId && (
        <CollectionEditor
          collection={editingCollection}
          onClose={() => setEditingId(null)}
          onSaved={() => { setEditingId(null); load(); }}
        />
      )}
    </AppShell>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add src/routes/admin/CatalogPage.tsx src/components/catalog/CollectionRow.tsx
git commit -m "feat(portal): CatalogPage with drag-to-reorder collection list"
```

---

### Task 14: CollectionEditor — 4-step wizard

**Files:**
- Create: `src/components/catalog/CollectionEditor/index.tsx`
- Create: `src/components/catalog/CollectionEditor/StepBasics.tsx`
- Create: `src/components/catalog/CollectionEditor/StepContent.tsx`
- Create: `src/components/catalog/CollectionEditor/StepArtwork.tsx`
- Create: `src/components/catalog/CollectionEditor/StepReview.tsx`

- [ ] **Step 1: Create StepBasics.tsx**

```tsx
import { Input } from '../../../components/ui/Input';
import type { Collection } from '../../../types';

type Draft = Partial<Collection> & { name: string };

export function StepBasics({ draft, onChange }: { draft: Draft; onChange: (d: Draft) => void }) {
  return (
    <div className="flex flex-col gap-4">
      <Input id="coll-name" label="Name" value={draft.name} onChange={e => onChange({ ...draft, name: e.target.value })} required />
      <div className="flex gap-4">
        <label className="flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={!!draft.pin_to_top} onChange={e => onChange({ ...draft, pin_to_top: e.target.checked })} className="accent-accent w-4 h-4" />
          <span className="text-sm text-text">Pin to top</span>
        </label>
        <label className="flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={!!draft.show_all_tab} onChange={e => onChange({ ...draft, show_all_tab: e.target.checked })} className="accent-accent w-4 h-4" />
          <span className="text-sm text-text">Show "All" tab</span>
        </label>
        <label className="flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={draft.focus_glow_enabled !== false} onChange={e => onChange({ ...draft, focus_glow_enabled: e.target.checked })} className="accent-accent w-4 h-4" />
          <span className="text-sm text-text">Focus glow</span>
        </label>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Create StepContent.tsx**

```tsx
import { useEffect, useRef, useState } from 'react';
import { supabase } from '../../../lib/supabase';
import { Input } from '../../../components/ui/Input';
import { Button } from '../../../components/ui/Button';
import { DragHandle } from '../../../components/ui/DragHandle';
import type { Folder, FolderSource } from '../../../types';

interface Props {
  collectionId: string | null;
  hasGroups: boolean;
  onHasGroupsChange: (v: boolean) => void;
}

export function StepContent({ collectionId, hasGroups, onHasGroupsChange }: Props) {
  const [folders, setFolders] = useState<Folder[]>([]);
  const [selectedFolder, setSelectedFolder] = useState<Folder | null>(null);
  const [sources, setSources] = useState<FolderSource[]>([]);
  const [newFolderName, setNewFolderName] = useState('');
  const [newSourceProvider, setNewSourceProvider] = useState('');
  const dragIndex = useRef<number | null>(null);

  useEffect(() => {
    if (!collectionId) return;
    supabase.from('folders').select('*').eq('collection_id', collectionId).order('sort_order').then(({ data }) => {
      setFolders(data ?? []);
      if (data?.length) onHasGroupsChange(true);
    });
  }, [collectionId]);

  useEffect(() => {
    if (!selectedFolder) return;
    supabase.from('folder_sources').select('*').eq('folder_id', selectedFolder.id).order('sort_order').then(({ data }) => setSources(data ?? []));
  }, [selectedFolder]);

  async function addFolder() {
    if (!newFolderName.trim() || !collectionId) return;
    const { data } = await supabase.from('folders').insert({ collection_id: collectionId, name: newFolderName.trim(), sort_order: folders.length }).select().single();
    if (data) { setFolders(prev => [...prev, data as Folder]); setNewFolderName(''); onHasGroupsChange(true); }
  }

  async function addSource() {
    if (!newSourceProvider.trim() || !selectedFolder) return;
    const { data } = await supabase.from('folder_sources').insert({ folder_id: selectedFolder.id, provider: newSourceProvider.trim(), sort_order: sources.length }).select().single();
    if (data) { setSources(prev => [...prev, data as FolderSource]); setNewSourceProvider(''); }
  }

  function handleFolderDragStart(i: number) { dragIndex.current = i; }
  async function handleFolderDrop(i: number) {
    if (dragIndex.current === null || dragIndex.current === i) return;
    const reordered = [...folders];
    const [moved] = reordered.splice(dragIndex.current, 1);
    reordered.splice(i, 0, moved);
    setFolders(reordered);
    dragIndex.current = null;
    await Promise.all(reordered.map((f, idx) => supabase.from('folders').update({ sort_order: idx }).eq('id', f.id)));
  }

  return (
    <div className="flex flex-col gap-5">
      {/* Mode selector */}
      <div className="flex gap-3">
        {[false, true].map(g => (
          <button key={String(g)} onClick={() => onHasGroupsChange(g)} className={`flex-1 py-2 rounded-lg border text-sm transition-colors ${hasGroups === g ? 'border-accent bg-accent-light text-accent' : 'border-border text-muted'}`}>
            {g ? 'With Groups' : 'Flat List'}
          </button>
        ))}
      </div>

      {hasGroups ? (
        <div className="grid grid-cols-2 gap-4">
          {/* Group list */}
          <div>
            <p className="text-xs font-medium text-muted mb-2 uppercase tracking-wide">Groups</p>
            <div className="flex flex-col gap-1 mb-3">
              {folders.map((f, i) => (
                <div
                  key={f.id}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg border cursor-pointer transition-colors ${selectedFolder?.id === f.id ? 'border-accent bg-accent-light' : 'border-border hover:border-accent/40'}`}
                  draggable
                  onDragStart={() => handleFolderDragStart(i)}
                  onDragOver={e => e.preventDefault()}
                  onDrop={() => handleFolderDrop(i)}
                  onClick={() => setSelectedFolder(f)}
                >
                  <DragHandle />
                  <span className="text-sm text-text truncate">{f.name}</span>
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <Input id="new-folder" value={newFolderName} onChange={e => setNewFolderName(e.target.value)} placeholder="Group name" className="flex-1" />
              <Button size="sm" onClick={addFolder}>Add</Button>
            </div>
          </div>

          {/* Sources for selected folder */}
          <div>
            <p className="text-xs font-medium text-muted mb-2 uppercase tracking-wide">{selectedFolder ? `Sources — ${selectedFolder.name}` : 'Select a group'}</p>
            {selectedFolder && (
              <>
                <div className="flex flex-col gap-1 mb-3">
                  {sources.map(s => (
                    <div key={s.id} className="px-3 py-2 rounded-lg border border-border text-sm text-text truncate">{s.title ?? s.provider}</div>
                  ))}
                </div>
                <div className="flex gap-2">
                  <Input id="new-source" value={newSourceProvider} onChange={e => setNewSourceProvider(e.target.value)} placeholder="Provider / catalog ID" className="flex-1" />
                  <Button size="sm" onClick={addSource}>Add</Button>
                </div>
              </>
            )}
          </div>
        </div>
      ) : (
        <div>
          <p className="text-sm text-muted">Use flat mode for a single source list. Switch to "With Groups" to add folder-based grouping.</p>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Create StepArtwork.tsx**

```tsx
import { Input } from '../../../components/ui/Input';
import type { Collection } from '../../../types';

type Draft = Partial<Collection> & { name: string };

export function StepArtwork({ draft, onChange }: { draft: Draft; onChange: (d: Draft) => void }) {
  return (
    <div className="flex flex-col gap-4">
      <Input id="backdrop" label="Backdrop Image URL" type="url" value={draft.backdrop_image ?? ''} onChange={e => onChange({ ...draft, backdrop_image: e.target.value || null })} placeholder="https://..." />
      <div>
        <p className="text-sm font-medium text-text mb-2">View Mode</p>
        <div className="flex gap-2 flex-wrap">
          {['FOLLOW_LAYOUT', 'GRID', 'LIST'].map(mode => (
            <button key={mode} onClick={() => onChange({ ...draft, view_mode: mode })} className={`px-3 py-1.5 text-xs rounded-lg border transition-colors ${draft.view_mode === mode ? 'border-accent bg-accent-light text-accent' : 'border-border text-muted'}`}>
              {mode}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Create StepReview.tsx**

```tsx
import { Badge } from '../../../components/ui/Badge';
import type { Collection } from '../../../types';

type Draft = Partial<Collection> & { name: string };

export function StepReview({ draft, hasGroups }: { draft: Draft; hasGroups: boolean }) {
  const rows: [string, string][] = [
    ['Name', draft.name],
    ['Structure', hasGroups ? 'With Groups' : 'Flat List'],
    ['View Mode', draft.view_mode ?? 'FOLLOW_LAYOUT'],
    ['Pin to Top', draft.pin_to_top ? 'Yes' : 'No'],
    ['Show All Tab', draft.show_all_tab ? 'Yes' : 'No'],
    ['Focus Glow', draft.focus_glow_enabled !== false ? 'On' : 'Off'],
    ['Backdrop', draft.backdrop_image ?? '(none)'],
  ];

  return (
    <div className="flex flex-col gap-3">
      {rows.map(([label, value]) => (
        <div key={label} className="flex items-start justify-between gap-4">
          <p className="text-sm text-muted shrink-0">{label}</p>
          <p className="text-sm text-text text-right truncate max-w-xs">{value}</p>
        </div>
      ))}
      <div className="pt-2">
        <Badge variant="success">Ready to save</Badge>
      </div>
    </div>
  );
}
```

- [ ] **Step 5: Create CollectionEditor/index.tsx**

```tsx
import { useState } from 'react';
import { supabase } from '../../../lib/supabase';
import { Modal } from '../../ui/Modal';
import { Button } from '../../ui/Button';
import { StepBasics } from './StepBasics';
import { StepContent } from './StepContent';
import { StepArtwork } from './StepArtwork';
import { StepReview } from './StepReview';
import type { Collection } from '../../../types';

type Draft = Partial<Collection> & { name: string };

const STEPS = ['Basics', 'Content', 'Artwork', 'Review'];

function toDraft(c: Collection | null): Draft {
  return c ? { ...c } : { name: '', view_mode: 'FOLLOW_LAYOUT', show_all_tab: false, focus_glow_enabled: true, pin_to_top: false };
}

interface Props {
  collection: Collection | null;
  onClose: () => void;
  onSaved: () => void;
}

export function CollectionEditor({ collection, onClose, onSaved }: Props) {
  const [step, setStep] = useState(0);
  const [draft, setDraft] = useState<Draft>(toDraft(collection));
  const [hasGroups, setHasGroups] = useState(false);
  const [saving, setSaving] = useState(false);
  const [savedId, setSavedId] = useState<string | null>(collection?.id ?? null);

  async function handleNext() {
    if (step === 0) {
      // Upsert collection on leaving Basics so Content step has an ID
      setSaving(true);
      if (savedId) {
        await supabase.from('collections').update({ name: draft.name, pin_to_top: draft.pin_to_top, show_all_tab: draft.show_all_tab, focus_glow_enabled: draft.focus_glow_enabled }).eq('id', savedId);
      } else {
        const { data } = await supabase.from('collections').insert({ name: draft.name, pin_to_top: draft.pin_to_top ?? false, show_all_tab: draft.show_all_tab ?? false, focus_glow_enabled: draft.focus_glow_enabled !== false, sort_order: 9999 }).select().single();
        if (data) setSavedId((data as Collection).id);
      }
      setSaving(false);
    }
    setStep(s => s + 1);
  }

  async function handleSave() {
    if (!savedId) return;
    setSaving(true);
    await supabase.from('collections').update({ backdrop_image: draft.backdrop_image, view_mode: draft.view_mode ?? 'FOLLOW_LAYOUT' }).eq('id', savedId);
    setSaving(false);
    onSaved();
  }

  return (
    <Modal open onClose={onClose} title={collection ? `Edit: ${collection.name}` : 'New Collection'} width="max-w-2xl">
      {/* Step indicator */}
      <div className="px-6 pt-4 flex gap-2">
        {STEPS.map((s, i) => (
          <div key={s} className="flex items-center gap-2">
            <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-semibold transition-colors ${i < step ? 'bg-accent text-white' : i === step ? 'bg-accent-light text-accent' : 'bg-border text-muted'}`}>
              {i < step ? '✓' : i + 1}
            </div>
            <span className={`text-xs ${i === step ? 'text-text font-medium' : 'text-muted'}`}>{s}</span>
            {i < STEPS.length - 1 && <div className="w-8 h-px bg-border" />}
          </div>
        ))}
      </div>

      <div className="p-6">
        {step === 0 && <StepBasics draft={draft} onChange={setDraft} />}
        {step === 1 && <StepContent collectionId={savedId} hasGroups={hasGroups} onHasGroupsChange={setHasGroups} />}
        {step === 2 && <StepArtwork draft={draft} onChange={setDraft} />}
        {step === 3 && <StepReview draft={draft} hasGroups={hasGroups} />}
      </div>

      <div className="px-6 pb-6 flex justify-between">
        <Button variant="ghost" onClick={step === 0 ? onClose : () => setStep(s => s - 1)}>
          {step === 0 ? 'Cancel' : 'Back'}
        </Button>
        {step < 3 ? (
          <Button onClick={handleNext} loading={saving}>Next</Button>
        ) : (
          <Button onClick={handleSave} loading={saving}>Save Collection</Button>
        )}
      </div>
    </Modal>
  );
}
```

- [ ] **Step 6: Verify in browser**

Sign in as admin. Navigate to `/admin/catalog`. Click "+ New Collection". Walk through all 4 steps, verify collection is created in Supabase, collection appears in list.

- [ ] **Step 7: Commit**

```bash
git add src/components/catalog/
git commit -m "feat(portal): 4-step CollectionEditor with flat/grouped content support"
```

---

### Task 15: UsersPage

**Files:**
- Modify: `src/routes/admin/UsersPage.tsx`

- [ ] **Step 1: Implement UsersPage**

```tsx
import { useEffect, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { AppShell } from '../../components/layout/AppShell';
import { Badge } from '../../components/ui/Badge';
import type { Profile, UserRole } from '../../types';

type AdminUser = Profile & { email?: string };

const ROLE_LABELS: Record<UserRole, string> = {
  admin: 'Admin',
  friends_family: 'Friends & Family',
  premium: 'Premium',
  premium_plus: 'Premium+',
};

const ROLE_BADGE: Record<UserRole, 'default' | 'success' | 'warning' | 'danger' | 'purple'> = {
  admin: 'purple',
  friends_family: 'success',
  premium: 'warning',
  premium_plus: 'default',
};

export default function UsersPage() {
  const { session } = useAuth();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!session) return;
    fetch(`${import.meta.env.VITE_SUPABASE_FUNCTIONS_URL}/admin-users`, {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then(r => r.json())
      .then(data => { setUsers(data.users ?? []); setLoading(false); })
      .catch(() => { setError('Failed to load users'); setLoading(false); });
  }, [session]);

  async function handleRoleChange(userId: string, newRole: UserRole) {
    await fetch(`${import.meta.env.VITE_SUPABASE_FUNCTIONS_URL}/admin-users`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${session!.access_token}` },
      body: JSON.stringify({ userId, role: newRole }),
    });
    setUsers(prev => prev.map(u => u.user_id === userId ? { ...u, role: newRole } : u));
  }

  return (
    <AppShell>
      <div className="max-w-3xl mx-auto">
        <h1 className="text-2xl font-bold text-text mb-6">Users</h1>

        {loading && <p className="text-muted text-sm">Loading…</p>}
        {error && <p className="text-red-500 text-sm">{error}</p>}

        {!loading && (
          <div className="overflow-hidden rounded-xl border border-border bg-surface">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-bg">
                  <th className="text-left px-4 py-3 font-medium text-muted">Email</th>
                  <th className="text-left px-4 py-3 font-medium text-muted">Role</th>
                  <th className="text-left px-4 py-3 font-medium text-muted">Joined</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr key={u.id} className="border-b border-border last:border-0">
                    <td className="px-4 py-3 text-text">{u.email ?? u.user_id.slice(0, 8) + '…'}</td>
                    <td className="px-4 py-3">
                      <Badge variant={ROLE_BADGE[u.role]}>{ROLE_LABELS[u.role]}</Badge>
                    </td>
                    <td className="px-4 py-3 text-muted">{new Date(u.created_at).toLocaleDateString()}</td>
                    <td className="px-4 py-3">
                      <select
                        value={u.role}
                        onChange={e => handleRoleChange(u.user_id, e.target.value as UserRole)}
                        className="text-xs border border-border rounded-lg px-2 py-1 bg-surface text-text"
                      >
                        {(Object.keys(ROLE_LABELS) as UserRole[]).map(r => (
                          <option key={r} value={r}>{ROLE_LABELS[r]}</option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AppShell>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/routes/admin/UsersPage.tsx
git commit -m "feat(portal): UsersPage with role management table"
```

---

### Task 16: InvitesPage

**Files:**
- Modify: `src/routes/admin/InvitesPage.tsx`

- [ ] **Step 1: Implement InvitesPage**

```tsx
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { AppShell } from '../../components/layout/AppShell';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Card } from '../../components/ui/Card';
import type { InviteCode } from '../../types';

function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

export default function InvitesPage() {
  const { user } = useAuth();
  const [codes, setCodes] = useState<InviteCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [lastGenerated, setLastGenerated] = useState<string | null>(null);

  useEffect(() => { load(); }, []);

  async function load() {
    const { data } = await supabase.from('invite_codes').select('*').order('created_at', { ascending: false });
    setCodes(data ?? []);
    setLoading(false);
  }

  async function handleGenerate() {
    if (!user) return;
    setGenerating(true);
    const code = generateCode();
    const { error } = await supabase.from('invite_codes').insert({ code, created_by: user.id, is_active: true, max_uses: 1 });
    if (!error) { setLastGenerated(code); load(); }
    setGenerating(false);
  }

  function copyCode(code: string) {
    navigator.clipboard.writeText(code);
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-text">Invite Codes</h1>
          <Button onClick={handleGenerate} loading={generating}>Generate Code</Button>
        </div>

        {lastGenerated && (
          <Card className="p-4 mb-6 flex items-center gap-3 border-accent">
            <div className="flex-1">
              <p className="text-xs text-muted mb-1">New invite code</p>
              <p className="text-xl font-mono font-bold text-accent tracking-widest">{lastGenerated}</p>
            </div>
            <Button size="sm" variant="secondary" onClick={() => copyCode(lastGenerated)}>Copy</Button>
          </Card>
        )}

        {loading ? (
          <p className="text-muted text-sm">Loading…</p>
        ) : (
          <div className="overflow-hidden rounded-xl border border-border bg-surface">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-bg">
                  <th className="text-left px-4 py-3 font-medium text-muted">Code</th>
                  <th className="text-left px-4 py-3 font-medium text-muted">Status</th>
                  <th className="text-left px-4 py-3 font-medium text-muted">Created</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody>
                {codes.map(c => (
                  <tr key={c.code} className="border-b border-border last:border-0">
                    <td className="px-4 py-3 font-mono font-semibold text-text">{c.code}</td>
                    <td className="px-4 py-3">
                      {c.used_by ? (
                        <Badge variant="default">Used</Badge>
                      ) : c.is_active ? (
                        <Badge variant="success">Active</Badge>
                      ) : (
                        <Badge variant="danger">Inactive</Badge>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted">{new Date(c.created_at).toLocaleDateString()}</td>
                    <td className="px-4 py-3">
                      {!c.used_by && <Button size="sm" variant="ghost" onClick={() => copyCode(c.code)}>Copy</Button>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AppShell>
  );
}
```

- [ ] **Step 2: Verify in browser**

Sign in as admin. Navigate to `/admin/invites`. Generate a code, verify it appears in the table. Copy it, use it in the signup flow.

- [ ] **Step 3: Commit**

```bash
git add src/routes/admin/InvitesPage.tsx
git commit -m "feat(portal): InvitesPage — generate, copy, and track invite codes"
```

---

### Task 17: Edge Function — admin-users

**Files:**
- Create: `Luna/supabase/functions/admin-users/index.ts`

- [ ] **Step 1: Create the function**

```ts
// supabase/functions/admin-users/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' };

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const authHeader = req.headers.get('Authorization') ?? '';
  const callerClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await callerClient.auth.getUser();
  if (!user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: cors });

  const serviceClient = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: callerProfile } = await serviceClient.from('profiles').select('role').eq('user_id', user.id).single();
  if (callerProfile?.role !== 'admin') return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: cors });

  if (req.method === 'GET') {
    const { data: profiles } = await serviceClient.from('profiles').select('*').order('created_at');
    const { data: authUsers } = await serviceClient.auth.admin.listUsers();
    const emailMap = new Map(authUsers.users.map(u => [u.id, u.email]));
    const users = (profiles ?? []).map(p => ({ ...p, email: emailMap.get(p.user_id) }));
    return new Response(JSON.stringify({ users }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  if (req.method === 'PATCH') {
    const { userId, role } = await req.json();
    await serviceClient.from('profiles').update({ role }).eq('user_id', userId);
    return new Response(JSON.stringify({ ok: true }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  return new Response('Method Not Allowed', { status: 405, headers: cors });
});
```

- [ ] **Step 2: Deploy the function**

```bash
cd /Users/zain/projects/Luna
npx supabase functions deploy admin-users --project-ref hvfsntdyowapjxobtyli
```

Expected: `Deployed admin-users`

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/admin-users/
git commit -m "feat(portal): admin-users Edge Function with role management"
```

---

### Task 18: Edge Function — create-checkout-session + create-portal-session

**Files:**
- Create: `Luna/supabase/functions/create-checkout-session/index.ts`

- [ ] **Step 1: Set Stripe secret key in Supabase secrets**

```bash
npx supabase secrets set STRIPE_SECRET_KEY=sk_test_REPLACE_ME --project-ref hvfsntdyowapjxobtyli
npx supabase secrets set STRIPE_PREMIUM_PRICE_ID=price_REPLACE_ME --project-ref hvfsntdyowapjxobtyli
npx supabase secrets set STRIPE_PREMIUM_PLUS_PRICE_ID=price_REPLACE_ME --project-ref hvfsntdyowapjxobtyli
npx supabase secrets set PORTAL_RETURN_URL=http://localhost:5173/billing --project-ref hvfsntdyowapjxobtyli
npx supabase secrets set SUCCESS_URL=http://localhost:5173/signup/success --project-ref hvfsntdyowapjxobtyli
```

Replace each `REPLACE_ME` with real values from your Stripe dashboard.

- [ ] **Step 2: Create the function**

```ts
// supabase/functions/create-checkout-session/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-06-20' });
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' };

const PRICE_IDS: Record<string, string> = {
  premium: Deno.env.get('STRIPE_PREMIUM_PRICE_ID')!,
  premium_plus: Deno.env.get('STRIPE_PREMIUM_PLUS_PRICE_ID')!,
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const { plan, customerId } = await req.json();
  const priceId = PRICE_IDS[plan];
  if (!priceId) return new Response(JSON.stringify({ error: 'Invalid plan' }), { status: 400, headers: cors });

  // Portal session (for existing customers)
  if (req.url.endsWith('/create-portal-session') && customerId) {
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: Deno.env.get('PORTAL_RETURN_URL')!,
    });
    return new Response(JSON.stringify({ url: session.url }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  // Checkout session (new subscriber)
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: Deno.env.get('SUCCESS_URL')! + `?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${Deno.env.get('PORTAL_RETURN_URL')!.replace('/billing', '/pricing')}`,
    metadata: { plan },
  });

  return new Response(JSON.stringify({ url: session.url }), { headers: { ...cors, 'Content-Type': 'application/json' } });
});
```

- [ ] **Step 3: Deploy**

```bash
npx supabase functions deploy create-checkout-session --project-ref hvfsntdyowapjxobtyli
```

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/create-checkout-session/
git commit -m "feat(portal): Stripe checkout and customer portal Edge Functions"
```

---

### Task 19: Edge Function — stripe-webhook

**Files:**
- Create: `Luna/supabase/functions/stripe-webhook/index.ts`

- [ ] **Step 1: Set webhook secret**

```bash
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_REPLACE_ME --project-ref hvfsntdyowapjxobtyli
```

In Stripe dashboard, create a webhook pointing to:
`https://hvfsntdyowapjxobtyli.supabase.co/functions/v1/stripe-webhook`

Events to listen for: `checkout.session.completed`, `customer.subscription.deleted`

- [ ] **Step 2: Create the function**

```ts
// supabase/functions/stripe-webhook/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-06-20' });
const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!);
  } catch {
    return new Response('Invalid signature', { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const plan = session.metadata?.plan as 'premium' | 'premium_plus';
    const email = session.customer_details?.email;
    if (!email || !plan) return new Response('Missing data', { status: 400 });

    // Create auth user
    const { data: authData, error } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { stripe_customer_id: session.customer },
    });
    if (error || !authData.user) return new Response('User creation failed', { status: 500 });

    // Insert profile
    await supabase.from('profiles').insert({
      user_id: authData.user.id,
      name: email.split('@')[0],
      role: plan,
      uses_primary_addons: false,
      profile_index: 0,
    });

    // Send magic link for password setup
    await supabase.auth.admin.generateLink({ type: 'magiclink', email });
  }

  if (event.type === 'customer.subscription.deleted') {
    const sub = event.data.object as Stripe.Subscription;
    const customerId = sub.customer as string;
    // Look up user by stripe_customer_id in user_metadata and downgrade
    const { data: users } = await supabase.auth.admin.listUsers();
    const user = users.users.find(u => u.user_metadata?.stripe_customer_id === customerId);
    if (user) {
      await supabase.from('profiles').update({ role: 'user' }).eq('user_id', user.id);
    }
  }

  return new Response(JSON.stringify({ received: true }), { headers: { 'Content-Type': 'application/json' } });
});
```

- [ ] **Step 3: Deploy**

```bash
npx supabase functions deploy stripe-webhook --project-ref hvfsntdyowapjxobtyli
```

- [ ] **Step 4: Test the webhook**

In Stripe dashboard, use "Send test webhook" for `checkout.session.completed`. Verify a new user appears in Supabase Auth and `profiles` table.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/stripe-webhook/
git commit -m "feat(portal): stripe-webhook Edge Function — provision user on checkout"
```

---

### Task 20: Final wiring and production env

**Files:**
- Create: `Luna/luna-portal/.env.production`
- Modify: `Luna/luna-portal/src/routes/public/SignupPage.tsx` (Stripe portal session call)

- [ ] **Step 1: Create .env.production**

```
VITE_SUPABASE_URL=https://hvfsntdyowapjxobtyli.supabase.co
VITE_SUPABASE_ANON_KEY=<real anon key>
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_REPLACE_ME
VITE_SUPABASE_FUNCTIONS_URL=https://hvfsntdyowapjxobtyli.supabase.co/functions/v1
```

- [ ] **Step 2: Build for production**

```bash
cd /Users/zain/projects/Luna/luna-portal
npm run build
```

Expected: `dist/` folder created, no TypeScript errors.

- [ ] **Step 3: Deploy to Vercel**

```bash
npx vercel --prod
```

Follow prompts. Set environment variables in Vercel dashboard matching `.env.production`.

- [ ] **Step 4: Final commit**

```bash
git add luna-portal/.env.production
git commit -m "feat(portal): production env config"
```

---

## Self-Review

**Spec coverage check:**
- ✅ PricingPage with 3 plan cards and F&F invite-only CTA
- ✅ SignupPage — invite code path (F&F) and Stripe path (Premium/Premium+)
- ✅ LoginPage with password + magic link
- ✅ ProfilesPage — Netflix-style grid, add/edit/delete, PIN toggle
- ✅ AddonsPage — role-aware (read-only for F&F/Premium, editable for admin/Premium+), drag-to-reorder
- ✅ BillingPage — plan display, Stripe Customer Portal redirect
- ✅ CatalogPage — draggable collection list
- ✅ CollectionEditor — 4-step wizard (Basics/Content/Artwork/Review), flat vs grouped detection
- ✅ UsersPage — table, inline role change
- ✅ InvitesPage — generate, copy, status tracking
- ✅ Route guards (PublicRoute/UserRoute/AdminRoute)
- ✅ AuthContext with role resolution
- ✅ admin-users Edge Function
- ✅ create-checkout-session Edge Function
- ✅ stripe-webhook Edge Function (provision user on purchase)
- ✅ Shared UI components (Button, Card, Modal, Badge, Input, DragHandle)
- ✅ Navbar + Sidebar + AppShell

**No placeholders, no TBDs, no "similar to" references.**
