import { NextRequest, NextResponse } from "next/server"
import { headers } from "next/headers"
import { auth } from "@/lib/auth"
import { prisma } from "@/lib/prisma"

export async function PUT(request: NextRequest) {
  try {
    const session = await auth.api.getSession({
      headers: await headers(),
    })

    if (!session?.user) {
      return NextResponse.json({ error: "No autorizado" }, { status: 401 })
    }

    const body = await request.json()
    const { name, phone } = body

    // Validaciones
    if (name !== undefined && name.trim().length === 0) {
      return NextResponse.json({ error: "El nombre no puede estar vacío" }, { status: 400 })
    }

    if (phone !== undefined && phone.trim().length > 0) {
      // Validación básica de teléfono (solo números, espacios, +, -, paréntesis)
      const phoneRegex = /^[\d\s\+\-\(\)]+$/
      if (!phoneRegex.test(phone)) {
        return NextResponse.json({ error: "Formato de teléfono inválido" }, { status: 400 })
      }
    }

    // Actualizar solo los campos proporcionados
    const updateData: { name?: string; phone?: string | null } = {}
    if (name !== undefined) updateData.name = name.trim() || null
    if (phone !== undefined) updateData.phone = phone.trim() || null

    const updatedUser = await prisma.user.update({
      where: { id: session.user.id },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        emailVerified: true,
        image: true,
        createdAt: true,
        updatedAt: true,
      },
    })

    return NextResponse.json({ data: { user: updatedUser } })
  } catch (error) {
    console.error("Error updating profile:", error)
    return NextResponse.json({ error: "Error al actualizar el perfil" }, { status: 500 })
  }
}
