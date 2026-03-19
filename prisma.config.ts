// Prisma 7 configuration file
// In Prisma 7, datasource URL must be in this file for migrations
// 
// IMPORTANTE: Usar process.env directamente, no env() de Prisma
// Razón: env() no funciona correctamente en Bun + Docker + Prisma 7
//
import { defineConfig } from "prisma/config";
import { config } from "dotenv";
import { resolve } from "path";
import { existsSync } from "fs";

// Cargar variables de entorno desde .env solo si:
// 1. DATABASE_URL no está disponible (compatible con Docker donde se inyecta directamente)
// 2. El archivo .env existe (no falla en Docker donde puede no estar presente)
if (!process.env.DATABASE_URL) {
  const envPath = resolve(process.cwd(), ".env");
  if (existsSync(envPath)) {
    // Solo cargar si el archivo existe (evita errores en Docker)
    config({ path: envPath });
  }
}

// Verificar que DATABASE_URL está disponible
if (!process.env.DATABASE_URL) {
  console.error("❌ ERROR: DATABASE_URL not found in process.env");
  console.error("Available env vars:", Object.keys(process.env).filter(k => k.includes("DATABASE") || k.includes("POSTGRES")));
  throw new Error("DATABASE_URL is required");
}

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "bun ./prisma/seed/index.ts",
  },
  datasource: {
    // Usar process.env directamente - más confiable que env()
    url: process.env.DATABASE_URL,
  },
});
