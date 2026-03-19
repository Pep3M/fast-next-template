"use client"

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import { useRouter } from "next/navigation"
import { toast } from "sonner"

// Función para obtener la URL base de la API
// En el cliente, usa el dominio actual para evitar problemas con CORS y cookies
// Esto asegura que las peticiones se hagan al mismo dominio donde se ejecuta la app
const getApiBaseUrl = (): string => {
  // En el cliente (navegador), usar el dominio actual
  if (typeof window !== "undefined") {
    return window.location.origin
  }
  // En el servidor, usa la URL configurada
  return process.env.NEXT_PUBLIC_BETTER_AUTH_URL || "http://localhost:5023"
}

const API_BASE_URL = getApiBaseUrl()
const API_BASE_PATH = "/api/auth"

// Tipos
interface SignInRequest {
  email: string
  password: string
}

interface SignUpRequest {
  email: string
  password: string
  name: string
}

export type UserRole = "ADMIN" | "USER"

export interface User {
  id: string
  name?: string | null
  email: string
  phone?: string | null
  role?: UserRole
  emailVerified?: boolean
  image?: string | null
  createdAt?: Date
  updatedAt?: Date
}

interface AuthResponse {
  data?: {
    user?: User
    session?: {
      id: string
      userId: string
    }
  }
  error?: {
    message: string
    code?: string
  }
}

interface SessionResponse {
  data?: {
    user?: User
    session?: {
      id: string
      userId: string
    }
  }
  error?: {
    message: string
  }
}

// Funciones de API
const authApi = {
  signIn: async (credentials: SignInRequest): Promise<AuthResponse> => {
    const response = await fetch(`${API_BASE_URL}${API_BASE_PATH}/sign-in/email`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(credentials),
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: "Error al iniciar sesión" }))
      return { error }
    }

    return await response.json()
  },

  signUp: async (data: SignUpRequest): Promise<AuthResponse> => {
    const response = await fetch(`${API_BASE_URL}${API_BASE_PATH}/sign-up/email`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: "Error al crear cuenta" }))
      return { error }
    }

    return await response.json()
  },

  signOut: async (): Promise<void> => {
    await fetch(`${API_BASE_URL}${API_BASE_PATH}/sign-out`, {
      method: "POST",
      credentials: "include",
    })
  },

  getSession: async (): Promise<SessionResponse> => {
    const response = await fetch(`${API_BASE_URL}${API_BASE_PATH}/session`, {
      method: "GET",
      credentials: "include",
    })

    if (!response.ok) {
      return { error: { message: "No hay sesión activa" } }
    }

    return await response.json()
  },

  setupAdmin: async (userId: string): Promise<{ success: boolean }> => {
    const response = await fetch(`${API_BASE_URL}/api/auth/setup-admin`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify({ userId }),
    })

    if (!response.ok) {
      throw new Error("Error al asignar rol admin")
    }

    return await response.json()
  },

  updateProfile: async (data: { name?: string; phone?: string }): Promise<{ data?: { user: User }; error?: { message: string } }> => {
    const response = await fetch(`${API_BASE_URL}/api/user/profile`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: "Error al actualizar el perfil" }))
      return { error }
    }

    return await response.json()
  },

  changePassword: async (data: { currentPassword: string; newPassword: string }): Promise<{ success?: boolean; error?: { message: string } }> => {
    const response = await fetch(`${API_BASE_URL}/api/user/password`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: "Error al cambiar la contraseña" }))
      return { error }
    }

    return await response.json()
  },

  deleteAccount: async (): Promise<{ success?: boolean; error?: { message: string } }> => {
    const response = await fetch(`${API_BASE_URL}/api/user/delete`, {
      method: "DELETE",
      credentials: "include",
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: "Error al eliminar la cuenta" }))
      return { error }
    }

    return await response.json()
  },
}

// Hooks
export function useSession() {
  return useQuery({
    queryKey: ["auth", "session"],
    queryFn: authApi.getSession,
    retry: false,
    refetchOnWindowFocus: false,
    staleTime: 5 * 60 * 1000, // 5 minutos
  })
}

export function useSignIn() {
  const queryClient = useQueryClient()
  const router = useRouter()

  return useMutation({
    mutationFn: authApi.signIn,
    onSuccess: (data) => {
      if (data.error) {
        toast.error(data.error.message || "Error al iniciar sesión")
        return
      }

      // Invalidar y refetch la sesión
      queryClient.invalidateQueries({ queryKey: ["auth", "session"] })
      toast.success("Sesión iniciada correctamente")
      router.push("/dashboard")
      router.refresh()
    },
    onError: (error) => {
      toast.error("Error al iniciar sesión. Por favor, intenta de nuevo.")
      console.error("Login error:", error)
    },
  })
}

export function useSignUp() {
  const queryClient = useQueryClient()
  const router = useRouter()

  return useMutation({
    mutationFn: authApi.signUp,
    onSuccess: async (data) => {
      if (data.error) {
        toast.error(data.error.message || "Error al crear la cuenta")
        return
      }

      // Asignar rol ADMIN al primer usuario
      if (data.data?.user?.id) {
        try {
          await authApi.setupAdmin(data.data.user.id)
        } catch (error) {
          console.error("Error al asignar rol admin:", error)
        }
      }

      // Invalidar y refetch la sesión
      queryClient.invalidateQueries({ queryKey: ["auth", "session"] })
      toast.success("Cuenta de administrador creada correctamente")
      router.push("/dashboard")
      router.refresh()
    },
    onError: (error) => {
      toast.error("Error al crear la cuenta. Por favor, intenta de nuevo.")
      console.error("Register error:", error)
    },
  })
}

export function useSignOut() {
  const queryClient = useQueryClient()
  const router = useRouter()

  return useMutation({
    mutationFn: authApi.signOut,
    onSuccess: () => {
      // Limpiar todas las queries relacionadas con auth
      queryClient.clear()
      toast.success("Sesión cerrada correctamente")
      router.push("/login")
      router.refresh()
    },
    onError: (error) => {
      toast.error("Error al cerrar sesión")
      console.error("Sign out error:", error)
    },
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: authApi.updateProfile,
    onSuccess: (data) => {
      if (data.error) {
        toast.error(data.error.message || "Error al actualizar el perfil")
        return
      }

      // Invalidar y refetch la sesión para obtener los datos actualizados
      queryClient.invalidateQueries({ queryKey: ["auth", "session"] })
      toast.success("Perfil actualizado correctamente")
    },
    onError: (error) => {
      toast.error("Error al actualizar el perfil. Por favor, intenta de nuevo.")
      console.error("Update profile error:", error)
    },
  })
}

export function useChangePassword() {
  return useMutation({
    mutationFn: authApi.changePassword,
    onSuccess: (data) => {
      if (data.error) {
        toast.error(data.error.message || "Error al cambiar la contraseña")
        return
      }

      toast.success("Contraseña actualizada correctamente")
    },
    onError: (error) => {
      toast.error("Error al cambiar la contraseña. Por favor, intenta de nuevo.")
      console.error("Change password error:", error)
    },
  })
}

export function useDeleteAccount() {
  const queryClient = useQueryClient()
  const router = useRouter()

  return useMutation({
    mutationFn: authApi.deleteAccount,
    onSuccess: (data) => {
      if (data.error) {
        toast.error(data.error.message || "Error al eliminar la cuenta")
        return
      }

      // Limpiar todas las queries y redirigir al login
      queryClient.clear()
      toast.success("Cuenta eliminada correctamente")
      router.push("/login")
      router.refresh()
    },
    onError: (error) => {
      toast.error("Error al eliminar la cuenta. Por favor, intenta de nuevo.")
      console.error("Delete account error:", error)
    },
  })
}
