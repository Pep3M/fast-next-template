"use client"

import { createAuthClient } from "better-auth/react"

// En el cliente, usar el dominio actual para evitar problemas con CORS y cookies
// Esto asegura que las peticiones se hagan al mismo dominio donde se ejecuta la app
const getBaseURL = (): string => {
  if (typeof window !== "undefined") {
    // En el cliente, usar el dominio actual (window.location.origin)
    // Esto garantiza que las cookies y las peticiones funcionen correctamente
    return window.location.origin
  }
  // En el servidor (aunque este archivo es "use client")
  return process.env.NEXT_PUBLIC_BETTER_AUTH_URL || "http://localhost:5023"
}

export const authClient = createAuthClient({
  baseURL: getBaseURL(),
  basePath: "/api/auth",
})

export const { signIn, signUp, signOut, useSession } = authClient
