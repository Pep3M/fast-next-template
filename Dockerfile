# Dockerfile for Next.js with Bun
FROM oven/bun:1 AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Rebuild source only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ARG DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy"
ENV DATABASE_URL=$DATABASE_URL
ARG NEXT_PUBLIC_BETTER_AUTH_URL="http://localhost:5023"
ENV NEXT_PUBLIC_BETTER_AUTH_URL=$NEXT_PUBLIC_BETTER_AUTH_URL
ENV NEXT_PHASE="phase-production-build"

RUN bunx prisma generate
RUN bun run build

# Production image with Bun
FROM oven/bun:1-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN apk add --no-cache \
    netcat-openbsd \
    curl \
    bash

RUN addgroup --system --gid 1001 bunjs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:bunjs /app/public ./public
COPY --from=builder --chown=nextjs:bunjs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:bunjs /app/.next/static ./.next/static

COPY --from=builder --chown=nextjs:bunjs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:bunjs /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder --chown=nextjs:bunjs /app/package.json ./
COPY --from=builder --chown=nextjs:bunjs /app/node_modules ./node_modules

COPY --chown=nextjs:bunjs scripts/ ./scripts/
RUN chmod +x ./scripts/entrypoint-prod.sh

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["./scripts/entrypoint-prod.sh"]
