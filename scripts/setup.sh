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

# 3. CI/CD workflow configuration
echo ""
echo "GitHub Actions is configured to build a Docker image whenever you push to 'main'."
echo ""
echo "Would you like to keep this behavior?"
echo "  1) Yes  — keep automatic image builds on push to main"
echo "  2) No   — remove the push trigger (you can still trigger builds manually)"
echo "  3) Not now, maybe later — comment out the push trigger (easy to re-enable)"
echo ""
read -p "Enter your choice [1/2/3]: " CICD_CHOICE

WORKFLOW=".github/workflows/build-and-push.yml"
if [ -f "$WORKFLOW" ]; then
  case "$CICD_CHOICE" in
    1)
      echo "  ✓ CI/CD workflow kept as is"
      ;;
    2)
      # Remove the push: block, keep only workflow_dispatch
      sed -i.bak '/^  push:/,/^  workflow_dispatch:/{/^  workflow_dispatch:/!d}' "$WORKFLOW" && rm -f "$WORKFLOW.bak"
      echo "  ✓ Push trigger removed — builds can still be triggered manually from GitHub Actions"
      ;;
    3)
      # Comment out the push: block lines
      sed -i.bak '/^  push:/,/^  workflow_dispatch:/{/^  workflow_dispatch:/!s/^/# /}' "$WORKFLOW" && rm -f "$WORKFLOW.bak"
      echo "  ✓ Push trigger commented out — uncomment in .github/workflows/build-and-push.yml to re-enable"
      ;;
    *)
      echo "  ⚠ Invalid choice, skipping CI/CD configuration"
      ;;
  esac
fi

# 4. Generate secrets and create .env
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

# 5. Optionally install dependencies
echo ""
read -p "Install dependencies with 'bun install'? (y/N): " INSTALL_DEPS
if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
  echo ""
  bun install
  echo "  ✓ Dependencies installed"
fi

# 6. Next steps
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
