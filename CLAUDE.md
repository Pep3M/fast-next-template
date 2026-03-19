# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**fast-next-template** is a production-ready Next.js 16 starter template with TypeScript, PostgreSQL/Prisma, Better Auth, shadcn/ui, Docker, and GitHub Actions CI/CD. Use it as the foundation for any web application — run `scripts/setup.sh` to rename the project and bootstrap your `.env`.

## Development Commands

### Local Development (Bun - Recommended)
```bash
bun install                    # Install dependencies
bun run dev                    # Start dev server on http://localhost:5023
bun run build                  # Build for production
bun run start                  # Start production server on port 3000
bun run lint                   # Run linter
```

### Local Development (Docker)
```bash
docker-compose -f docker-compose.dev.yml up -d    # Start development services
docker-compose -f docker-compose.dev.yml logs -f  # View logs
docker-compose -f docker-compose.dev.yml down      # Stop services
```

### Database (Prisma)
```bash
npx prisma migrate dev         # Run migrations in development
npx prisma migrate deploy      # Run migrations in production
npx prisma migrate status      # Check migration status
npx prisma studio              # Open Prisma Studio GUI
npx prisma generate            # Generate Prisma Client
```

### Deploy on Servers

**On Development Server:**
```bash
./scripts/deploy-production.sh --env dev --skip-health-check
docker-compose -f docker-compose.dev.yml logs -f app
```

**On Production Server:**
```bash
./scripts/deploy-production.sh --env prod --skip-health-check
docker-compose -f docker-compose.prod.yml logs -f app
```

## Architecture

### Application Structure

- **Next.js App Router**: Next.js 16 with App Router pattern (`app/` directory)
- **Authentication**: Better Auth library with Prisma adapter for PostgreSQL
- **Database**: PostgreSQL 16 with Prisma ORM
- **UI**: Radix UI components with TailwindCSS 4 and shadcn/ui
- **Testing**: bun:test for fast unit/integration tests

### Key Directories

- `app/` - Next.js App Router pages and API routes
  - `(dashboard)/` - Protected dashboard routes (route group)
  - `api/` - API endpoints including auth
- `components/` - React components
  - `ui/` - Reusable UI components (shadcn/ui)
  - `app-sidebar.tsx`, `app-header.tsx` - Main layout components
- `lib/` - Core utilities and configurations
  - `auth.ts` - Better Auth configuration
  - `auth-client.ts` - Client-side auth helpers
  - `prisma.ts` - Prisma client singleton
  - `hooks/` - React hooks including `use-auth.ts`
- `scripts/` - Deployment and utility scripts
- `prisma/` - Prisma schema and migrations

### Path Aliases

TypeScript is configured with path alias `@/*` mapping to the root directory:
```typescript
import { auth } from "@/lib/auth"
import { Button } from "@/components/ui/button"
```

### Authentication Flow

1. Better Auth is configured in `lib/auth.ts` with:
   - Email/password authentication
   - PostgreSQL adapter via Prisma
   - Custom user role field (ADMIN/USER)
   - Base path: `/api/auth`

2. Protected routes use server-side session checks:
   ```typescript
   const session = await auth.api.getSession({ headers: await headers() })
   if (!session) redirect("/login")
   ```

3. Dashboard layout (`app/(dashboard)/layout.tsx`) enforces authentication for all nested routes

### Database Schema

Core Prisma models (auth-only):
- `User`: Main user table with role (ADMIN/USER), email, and soft delete support
- `Account`: Better Auth accounts with OAuth/password storage
- `Session`: User sessions with tokens and device info
- `Verification`: Email verification tokens

## Important Configuration Notes

### Environment Variables

Development uses port 5023 (configured in `package.json` dev script). Production uses port 3000.

Required environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `BETTER_AUTH_SECRET`: Secret for auth tokens (generate with `openssl rand -base64 32`)
- `BETTER_AUTH_URL`: Full base URL of the application
- `NEXT_PUBLIC_BETTER_AUTH_URL`: Public-facing base URL

Copy `.env.example` to `.env` and fill in the values, or run `scripts/setup.sh` to do it automatically.

### Docker Configuration

- **Development (local)**: `docker-compose.dev.yml` - Includes hot reload via `Dockerfile.dev`
- **Production**: `docker-compose.prod.yml` - Uses pre-built images from registry
- **Dockerfile**: Multi-stage build with standalone output
- **Registry**: GitHub Container Registry (ghcr.io)

### CI/CD

The project uses GitHub Actions (`.github/workflows/build-and-push.yml`):
- **`dev` branch** → builds image `:dev` → deploys to development server
- **`main` branch** → builds images `:latest` and `:production` → deploys to production server

Required GitHub Secrets: `SSH_HOST`, `SSH_USERNAME`, `SSH_PRIVATE_KEY`, `SSH_PORT` (dev), and `*_PROD` variants for production.

## Working with This Template

### Adding New Dashboard Pages

1. Create page in `app/(dashboard)/your-route/page.tsx`
2. Add loading state in `app/(dashboard)/your-route/loading.tsx`
3. Update sidebar navigation in `components/app-sidebar.tsx`
4. Protected by default (layout enforces authentication)

### Adding API Routes

Create route handlers in `app/api/your-endpoint/route.ts`. For protected endpoints:
```typescript
import { auth } from "@/lib/auth"
import { headers } from "next/headers"

const session = await auth.api.getSession({ headers: await headers() })
if (!session) return new Response("Unauthorized", { status: 401 })
```

### Database Changes

1. Modify `prisma/schema.prisma`
2. Run `npx prisma migrate dev --name your_migration_name`
3. Commit both schema and migration files
4. In production, migrations run automatically via `scripts/entrypoint-prod.sh`

## Testing

The project uses **bun:test** for fast, stable testing.

### Running Tests

```bash
bun test                    # Run all tests
bun run test:watch          # Watch mode
bun run test:coverage       # Run with coverage report
```

### Test Structure

```
__tests__/
├── setup.ts                # Global test configuration
└── unit/
    └── auth.test.ts        # Example unit tests
```

### Writing Tests

```typescript
import { describe, test, expect, beforeEach, afterEach, mock } from 'bun:test';

describe('MyService', () => {
  test('should do something', async () => {
    // Test implementation
    expect(result).toBe(expected);
  });
});
```
