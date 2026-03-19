#!/bin/bash
set -e

echo "========================================"
echo "  fast-next-template Setup"
echo "========================================"
echo ""

# 1. Get project name
while true; do
  read -p "Enter your project name (lowercase letters, numbers, hyphens only): " PROJECT_NAME
  if [[ "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
    break
  else
    echo "  Invalid name. Use only lowercase letters, numbers, and hyphens."
  fi
done

echo ""
echo "Setting up project: $PROJECT_NAME"
echo ""

# 2. Replace fast-next-template in key files
FILES=(
  "package.json"
  "docker-compose.dev.yml"
  "docker-compose.prod.yml"
  ".github/workflows/build-and-push.yml"
  "README.md"
  "CLAUDE.md"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    sed -i.bak "s/fast-next-template/$PROJECT_NAME/g" "$FILE" && rm -f "$FILE.bak"
    echo "  ✓ Updated $FILE"
  fi
done

# 3. Generate secrets and create .env
echo ""
echo "Generating secrets and creating .env..."

DB_NAME="${PROJECT_NAME//-/_}_dev"

if command -v openssl &> /dev/null; then
  AUTH_SECRET=$(openssl rand -base64 32)
  DB_PASSWORD=$(openssl rand -hex 16)
  echo "  ✓ Secrets generated with openssl"
else
  AUTH_SECRET="change-me-to-a-secure-random-string"
  DB_PASSWORD="change-me-to-hash"
  echo "  ⚠ openssl not found — placeholder secrets used. Replace them in .env before running the app."
fi

DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@localhost:5432/${DB_NAME}"

cp .env.example .env

# Fill in the generated values
sed -i.bak "s|BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$AUTH_SECRET|" .env && rm -f .env.bak
sed -i.bak "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASSWORD|" .env && rm -f .env.bak
sed -i.bak "s|DATABASE_URL=.*|DATABASE_URL=$DATABASE_URL|" .env && rm -f .env.bak
sed -i.bak "s|POSTGRES_DB=.*|POSTGRES_DB=$DB_NAME|" .env && rm -f .env.bak

echo "  ✓ Created .env with generated secrets"

# 4. Optionally install dependencies
echo ""
read -p "Install dependencies with 'bun install'? (y/N): " INSTALL_DEPS
if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
  echo ""
  bun install
  echo "  ✓ Dependencies installed"
fi

# 5. Next steps
echo ""
echo "========================================"
echo "  Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Start your database:  docker-compose -f docker-compose.dev.yml up -d db"
echo "  2. Run migrations:       npx prisma migrate dev"
echo "  3. Start dev server:     bun run dev"
echo ""
echo "The app will be available at http://localhost:5023"
echo ""
