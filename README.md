# fast-next-template

A production-ready Next.js 16 starter template with authentication, a protected dashboard, Docker support, and CI/CD via GitHub Actions. Clone it, run `setup.sh`, and start building your app.

[![Next.js](https://img.shields.io/badge/Next.js-16-black?style=for-the-badge&logo=next.js)](https://nextjs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=for-the-badge&logo=postgresql)](https://www.postgresql.org)
[![Bun](https://img.shields.io/badge/Bun-latest-fbf0df?style=for-the-badge&logo=bun)](https://bun.sh)

## Features

- **Authentication** — Email/password login & registration with [Better Auth](https://www.better-auth.com)
- **Protected dashboard** — Route-group layout with server-side session checks
- **Role-based access** — ADMIN and USER roles out of the box
- **Database** — PostgreSQL 16 with [Prisma 7](https://www.prisma.io) ORM
- **UI** — [shadcn/ui](https://ui.shadcn.com) + [Radix UI](https://www.radix-ui.com) + TailwindCSS 4
- **Dark/light mode** — Theme toggler included
- **Docker** — Multi-stage Dockerfile with hot-reload dev compose and production compose
- **CI/CD** — GitHub Actions: build → push image to ghcr.io on every push to `main`
- **Testing** — [bun:test](https://bun.sh/docs/cli/test) with example unit tests

## Quick Start

```bash
git clone https://github.com/your-username/fast-next-template.git my-app
cd my-app
./scripts/setup.sh    # Rename project, generate secrets, create .env
bun install
npx prisma migrate dev
bun run dev           # http://localhost:5023
```

## Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript 5 |
| Runtime | Bun |
| Database | PostgreSQL 16 |
| ORM | Prisma 7 |
| Auth | Better Auth 1.4 |
| UI | shadcn/ui + Radix UI + TailwindCSS 4 |
| Forms | React Hook Form + Zod |
| Data fetching | TanStack React Query 5 |
| Testing | bun:test |
| Containers | Docker + Docker Compose |
| CI/CD | GitHub Actions |

## Project Structure

```
app/
├── (dashboard)/          # Protected routes (auth enforced in layout)
│   ├── layout.tsx        # Session check — redirects to /login if unauthenticated
│   ├── dashboard/        # Main dashboard page
│   └── settings/         # User settings
├── api/
│   ├── auth/             # Better Auth handler
│   └── user/             # Profile, password, delete
├── login/                # Login page
└── register/             # Registration page

components/
├── ui/                   # shadcn/ui components
├── auth/                 # Register form
├── app-header.tsx        # Top navigation bar
└── app-sidebar.tsx       # Side navigation

lib/
├── auth.ts               # Better Auth server config
├── auth-client.ts        # Better Auth client helpers
├── prisma.ts             # Prisma singleton
└── hooks/
    └── use-auth.ts       # useSession, useSignOut hooks

prisma/
├── schema.prisma         # Database schema (User, Account, Session, Verification)
└── seed/
    └── index.ts          # Database seeder

scripts/
├── setup.sh              # Interactive project setup script
├── build-and-push.sh     # Manual Docker build & push to registry
├── entrypoint-prod.sh    # Production container startup (migrations + server)
└── entrypoint-dev.sh     # Development container startup
```

## Environment Variables

Copy `.env.example` to `.env` (or run `setup.sh` to generate it automatically):

```bash
cp .env.example .env
```

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `BETTER_AUTH_SECRET` | Auth token secret (`openssl rand -base64 32`) |
| `BETTER_AUTH_URL` | Full base URL of the application |
| `NEXT_PUBLIC_BETTER_AUTH_URL` | Public-facing base URL |
| `POSTGRES_*` | Database connection details for Docker |

## Docker

```bash
# Development (with hot reload)
docker-compose -f docker-compose.dev.yml up -d

# Production (pre-built image from registry)
docker-compose -f docker-compose.prod.yml up -d
```

See `config.env.build.example` and `config.env.prod.example` for registry configuration.

## CI/CD

Every push to `main` triggers `.github/workflows/build-and-push.yml`, which:

1. Builds the Docker image
2. Pushes it to GitHub Container Registry (`ghcr.io`) with tags `:latest` and `:production`

No secrets are required beyond the default `GITHUB_TOKEN`. Deployment to servers is handled separately.

**Optional:** set `NEXT_PUBLIC_BETTER_AUTH_URL` as a GitHub Actions secret to embed the correct URL at build time.

## Testing

```bash
bun test               # Run all tests
bun run test:coverage  # With coverage report
```

## License

MIT
