import { NextRequest, NextResponse } from "next/server"
import { prisma } from "@/lib/prisma"

export async function POST(request: NextRequest) {
  try {
    const { userId } = await request.json()

    if (!userId) {
      return NextResponse.json({ error: "User ID is required" }, { status: 400 })
    }

    // Verificar que no haya otros usuarios (solo el primero puede ser admin)
    const userCount = await prisma.user.count()

    if (userCount > 1) {
      return NextResponse.json({ error: "Only the first user can be admin" }, { status: 403 })
    }

    // Asignar rol ADMIN al primer usuario
    await prisma.user.update({
      where: { id: userId },
      data: { role: "ADMIN" },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error setting up admin:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
