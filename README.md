# IronLog

Fitness tracking app: a Flutter mobile app, a Next.js website, and a Next.js API, sharing one Firebase backend. Managed as a pnpm + Turborepo monorepo — one repo, three deployable apps.

## Folder hierarchy

```
Ironlog/
├── apps/
│   ├── web/          Next.js website (the marketing/app site users visit in a browser)
│   ├── api/           Next.js API (backend — the only thing that talks to Firebase Admin)
│   └── mobile/         Flutter app (Android/iOS/web/Windows from one codebase)
├── packages/
│   ├── shared/        TypeScript types & zod validation schemas shared by web + api
│   └── ui/                  empty scaffold, not used yet
├── docs/                     project notes (e.g. calorie-calculation rules)
├── firebase.json, firestore.rules    Firestore security rules & Firebase project config
├── package.json, pnpm-workspace.yaml, turbo.json   monorepo/build tooling
└── .gitignore
```

`apps/*` are the three things you'd actually deploy (web → Vercel, api → Vercel, mobile → app stores). `packages/*` are code shared between them. Nothing in `packages/` is deployed on its own.

---

## apps/web — the website (Next.js + React + Tailwind)

```
apps/web/
├── app/
│   └── globals.css        global styles
├── components/
│   └── AuthProvider.tsx   React context wrapping Firebase auth
├── lib/
│   ├── api-client.ts       fetch wrapper that calls apps/api
│   └── firebase-client.ts  Firebase client SDK init
└── tailwind.config.ts      design tokens (colors, spacing, fonts) for the whole site
```

**Heads up:** this app is still a skeleton — there's no `app/page.tsx` or `app/layout.tsx` yet, so it doesn't render a page yet. When you (or I) start building screens, they'll live under `app/` as Next.js "app router" routes, e.g. `app/dashboard/page.tsx`.

## apps/api — the backend (Next.js API routes, no UI)

```
apps/api/
├── app/api/            one folder per endpoint — this IS the API surface
│   ├── dashboard/route.ts
│   ├── exercises/route.ts
│   ├── health/route.ts
│   ├── measurements/route.ts
│   ├── templates/route.ts (+ [id]/route.ts for single-item)
│   ├── users/me/route.ts
│   ├── weight/route.ts
│   └── workouts/route.ts
├── lib/                Firebase Admin SDK init, shared response helpers
├── middleware.ts + middleware/auth.ts   verifies the Firebase auth token on requests
├── repositories/        raw Firestore reads/writes, one file per data type
├── services/             business logic, sits between routes and repositories
└── validators/           zod schemas validating request bodies
```

Request flow here is `route.ts` → `services/*` → `repositories/*` → Firestore. There's no UI in this app at all — it's purely JSON endpoints.

## apps/mobile — the Flutter app

```
apps/mobile/lib/
├── screens/            every screen/page in the app — this is where UI lives
│   ├── auth/            login, register
│   ├── dashboard/        home dashboard
│   ├── exercises/        exercise library
│   ├── profile/          profile, stats, calendar, theme settings
│   ├── tools/            calculators (BMI, BMR, calories, water intake...)
│   ├── workouts/         logging/tracking workouts
│   └── root_screen.dart  bottom-nav shell that hosts the screens above
├── core/               theme & app-wide config — the OTHER place UI lives
│   ├── app_colors.dart, palettes.dart, theme_vars.dart   color definitions
│   ├── app_typography.dart, app_spacing.dart              text styles & spacing scale
│   ├── app_theme.dart, premium_theme.dart, theme_controller.dart   ThemeData + light/dark switching
│   ├── premium_widgets.dart, responsive.dart              reusable styled widgets, breakpoints
│   └── api_client.dart, api_config.dart, api_exception.dart   HTTP client talking to apps/api
├── models/              plain data classes (Workout, WeightLog, User, ...)
├── repositories/        fetch/save data (calls api_client.dart or local storage)
├── data/                local-only stores (mock data, on-device caches)
├── auth/                Firebase auth + a demo/offline auth mode
└── utils/               pure helper functions (e.g. health_formulas.dart)
```

Platform folders (`android/`, `ios/`, `windows/`, `web/`) are Flutter's generated native shells — you basically never touch these by hand.

## packages/shared — types shared between web and api

```
packages/shared/src/
├── schemas/    zod schemas (exercise, template, user, weight, workout) — one source of truth
│               for what a valid request/object looks like, used by BOTH apps/web and apps/api
├── types/api.ts   shared TypeScript types for API request/response shapes
└── index.ts      re-exports everything above
```

If you change a data shape (e.g. add a field to a workout), it belongs here so both the website and the API agree on it.

---

## "I just want to edit the UI" — where to look

| I want to change... | Website (apps/web) | Mobile app (apps/mobile) |
|---|---|---|
| Colors, fonts, spacing (theme-wide) | `tailwind.config.ts`, `app/globals.css` | `lib/core/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `theme_vars.dart` |
| A specific screen's layout | `app/**/page.tsx` (once pages exist), `components/*.tsx` | `lib/screens/**/*.dart` |
| Light/dark mode behavior | n/a yet | `lib/core/theme_controller.dart`, `app_theme.dart` |
| A reusable styled button/card/etc. | `components/*.tsx` | `lib/core/premium_widgets.dart` |

You do **not** need to touch `apps/api`, `packages/shared`, or any `repositories/`/`services/`/`models/` files for pure visual changes — those only matter when the *data* changes, not how it's displayed. The one exception: if a screen calls a new/different backend field, the mobile `models/` file and `packages/shared/schemas/` need to agree with what `apps/api` returns.

---

## Running things locally

```bash
pnpm install          # once, from repo root
pnpm dev:web           # website at localhost:3100
pnpm dev:api            # API at localhost:4000
```

Mobile is run separately via Flutter (`flutter run`) from `apps/mobile/`, using `apps/mobile/env/firebase.json` for Firebase config (see `.vscode/launch.json`).
