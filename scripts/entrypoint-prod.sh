#!/bin/sh
set -e

echo "========================================="
echo "  fast-next-template - Production Startup"
echo "========================================="
echo ""

# 1. Check critical environment variables
echo "📋 Step 1/4: Checking environment variables..."
echo "  NODE_ENV: ${NODE_ENV:-not set}"
echo "  POSTGRES_HOST: ${POSTGRES_HOST:-not set}"
echo "  POSTGRES_PORT: ${POSTGRES_PORT:-not set}"
echo "  POSTGRES_USER: ${POSTGRES_USER:-not set}"
echo "  POSTGRES_DB: ${POSTGRES_DB:-not set}"

if [ -z "$DATABASE_URL" ]; then
  echo "❌ ERROR: DATABASE_URL is not set!"
  echo "   Available environment variables:"
  env | grep -E "(POSTGRES|DATABASE)" || echo "   No POSTGRES/DATABASE variables found"
  exit 1
else
  SAFE_URL=$(echo "$DATABASE_URL" | sed 's/:\/\/[^:]*:[^@]*@/:\/\/***:***@/')
  echo "  DATABASE_URL: $SAFE_URL"
fi
echo "✓ Environment variables OK"
echo ""

# 2. Wait for database connectivity
echo "📡 Step 2/4: Testing database connectivity..."
echo "  Waiting for database to be ready..."

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if nc -z ${POSTGRES_HOST:-db} ${POSTGRES_PORT:-5432} 2>/dev/null; then
    echo "✓ Database is reachable"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "  Attempt $RETRY_COUNT/$MAX_RETRIES - waiting for database..."
  sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ ERROR: Could not connect to database after $MAX_RETRIES attempts"
  echo "   Host: ${POSTGRES_HOST:-db}"
  echo "   Port: ${POSTGRES_PORT:-5432}"
  exit 1
fi
echo ""

# 3. Check Prisma CLI
echo "🔧 Step 3/4: Checking Prisma CLI..."
if ! command -v bunx > /dev/null; then
  echo "❌ ERROR: bunx command not found"
  exit 1
fi

if ! bunx prisma --version > /dev/null 2>&1; then
  echo "❌ ERROR: Prisma CLI not available"
  exit 1
fi

PRISMA_VERSION=$(bunx prisma --version | grep "prisma" | head -1 || echo "unknown")
echo "  Prisma: $PRISMA_VERSION"
BUN_VERSION=$(bun --version)
echo "  Bun: $BUN_VERSION"
echo "✓ Runtime OK"
echo ""

# 4. Run migrations and seed
echo "🔄 Step 4/4: Running database migrations..."
if bunx prisma migrate deploy; then
  echo "✓ Migrations applied successfully"
else
  echo "❌ ERROR: Failed to apply migrations"
  exit 1
fi

echo ""
echo "🌱 Seeding database..."
if bunx prisma db seed; then
  echo "✓ Database seeded successfully"
else
  echo "⚠️  Warning: Seeding failed or no seed script configured"
  echo "   This is not critical - continuing with server startup..."
fi

echo ""
echo "========================================="
echo "  Starting Next.js production server..."
echo "========================================="
exec bun run server.js
