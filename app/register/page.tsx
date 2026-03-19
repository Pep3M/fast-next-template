import { notFound } from "next/navigation"
import { prisma } from "@/lib/prisma"
import { RegisterForm } from "@/components/auth/register-form"

// Forzar renderizado dinámico - esta página necesita acceso a la DB en runtime
export const dynamic = "force-dynamic"

export default async function RegisterPage() {
  // Verificar si ya existen usuarios en la base de datos
  const userCount = await prisma.user.count()

  // Si ya hay usuarios, retornar 404
  if (userCount > 0) {
    notFound()
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="w-full max-w-6xl grid lg:grid-cols-2 gap-8 items-center">
        {/* Lado izquierdo - Branding */}
        <div className="hidden lg:flex flex-col justify-center space-y-6 p-8">
          <div className="space-y-2">
            <div className="flex items-center gap-3 mb-6">
              <div className="h-12 w-12 rounded-lg bg-primary flex items-center justify-center">
                <svg
                  className="h-6 w-6 text-primary-foreground"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4v16m8-8H4"
                  />
                </svg>
              </div>
              <h1 className="text-3xl font-bold text-foreground">MyApp</h1>
            </div>
            <h2 className="text-4xl font-bold text-foreground text-balance">
              Configuración inicial del sistema
            </h2>
            <p className="text-lg text-muted-foreground text-pretty">
              Crea la cuenta de administrador para comenzar a gestionar tu plataforma de servicios
              telefónicos e internet.
            </p>
            <div className="mt-6 p-4 rounded-lg bg-primary/10 border border-primary/20">
              <p className="text-sm text-foreground">
                <strong>Nota:</strong> Esta página solo está disponible durante la configuración inicial.
                Una vez creado el primer usuario, deberás iniciar sesión para crear usuarios adicionales.
              </p>
            </div>
          </div>
        </div>

        {/* Lado derecho - Formulario */}
        <RegisterForm />
      </div>
    </div>
  )
}
