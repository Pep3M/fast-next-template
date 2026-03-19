import { PrismaClient } from "@prisma/client"
import { PrismaPg } from "@prisma/adapter-pg"
import { Pool } from "pg"

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

const databaseUrl = process.env.DATABASE_URL

// Durante el build time de Next.js, si no hay DATABASE_URL, crear un cliente mock
// Esto previene errores durante el build cuando se pre-renderizan páginas SSR
const isBuildTime = process.env.NEXT_PHASE === "phase-production-build"

if (!databaseUrl && !isBuildTime) {
  throw new Error("DATABASE_URL environment variable is not set")
}

// Función para crear el cliente de Prisma
const createPrismaClient = () => {
  if (!databaseUrl) {
    // Durante build time, retornar un cliente básico sin adapter
    // Esto permite que el build complete, pero las queries fallarán si se ejecutan
    return new PrismaClient({
      log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
    })
  }

  // En runtime, crear adapter de PostgreSQL para Prisma 7
const pool = new Pool({ connectionString: databaseUrl })
const adapter = new PrismaPg(pool)

  return new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  })
}

export const prisma = globalForPrisma.prisma ?? createPrismaClient()

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma
