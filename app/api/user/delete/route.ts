import { NextRequest, NextResponse } from "next/server"
import { headers } from "next/headers"
import { auth } from "@/lib/auth"
import { prisma } from "@/lib/prisma"

export async function DELETE(request: NextRequest) {
  try {
    const session = await auth.api.getSession({
      headers: await headers(),
    })

    if (!session?.user) {
      return NextResponse.json({ error: "No autorizado" }, { status: 401 })
    }

    // Verificar que no sea el único usuario activo (no eliminado)
    const activeUserCount = await prisma.user.count({
      where: {
        deletedAt: null,
      },
    })

    if (activeUserCount <= 1) {
      return NextResponse.json(
        { error: "No se puede eliminar la cuenta. Debe haber al menos un usuario activo en el sistema" },
        { status: 403 }
      )
    }

    // Soft delete: marcar como eliminado
    await prisma.user.update({
      where: { id: session.user.id },
      data: { deletedAt: new Date() },
    })

    // Cerrar todas las sesiones del usuario
    await prisma.session.deleteMany({
      where: { userId: session.user.id },
    })

    return NextResponse.json({ success: true, message: "Cuenta eliminada correctamente" })
  } catch (error) {
    console.error("Error deleting account:", error)
    return NextResponse.json({ error: "Error al eliminar la cuenta" }, { status: 500 })
  }
}
