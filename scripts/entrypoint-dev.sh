#!/bin/bash
set -e

echo "🔧 Generating Prisma client..."
bunx prisma generate

echo "🔄 Running development migrations..."
bunx prisma migrate dev --name auto_migration --skip-generate --create-only 2>/dev/null || {
  echo "⚠️  No new migrations or error, continuing..."
}

echo "🌱 Running database seed..."
bunx prisma db seed || {
  echo "⚠️  Seeding failed, continuing without initial data..."
}

echo "🚀 Starting development server..."
exec bun run dev
