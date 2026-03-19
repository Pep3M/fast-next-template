import { NextRequest, NextResponse } from "next/server"
import { headers } from "next/headers"
import { auth } from "@/lib/auth"
import { prisma } from "@/lib/prisma"
import bcrypt from "bcryptjs"

export async function PUT(request: NextRequest) {
  try {
    const session = await auth.api.getSession({
      headers: await headers(),
    })

    if (!session?.user) {
      return NextResponse.json({ error: "No autorizado" }, { status: 401 })
    }

    const body = await request.json()
    const { currentPassword, newPassword } = body

    // Validaciones
    if (!currentPassword || !newPassword) {
      return NextResponse.json(
        { error: "La contraseña actual y la nueva contraseña son requeridas" },
        { status: 400 }
      )
    }

    if (newPassword.length < 8) {
      return NextResponse.json(
        { error: "La nueva contraseña debe tener al menos 8 caracteres" },
        { status: 400 }
      )
    }

    // Obtener la cuenta del usuario para verificar la contraseña actual
    const account = await prisma.account.findFirst({
      where: {
        userId: session.user.id,
        providerId: "credential",
      },
    })

    if (!account || !account.password) {
      return NextResponse.json({ error: "No se encontró la cuenta del usuario" }, { status: 404 })
    }

    // Verificar contraseña actual usando bcrypt
    const isValidPassword = await bcrypt.compare(currentPassword, account.password)

    if (!isValidPassword) {
      return NextResponse.json({ error: "La contraseña actual es incorrecta" }, { status: 401 })
    }

    // Hashear la nueva contraseña
    const hashedPassword = await bcrypt.hash(newPassword, 10)

    // Actualizar la contraseña
    await prisma.account.update({
      where: { id: account.id },
      data: { password: hashedPassword },
    })

    return NextResponse.json({ success: true, message: "Contraseña actualizada correctamente" })
  } catch (error) {
    console.error("Error updating password:", error)
    return NextResponse.json({ error: "Error al actualizar la contraseña" }, { status: 500 })
  }
}
