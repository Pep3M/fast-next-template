import { NextRequest, NextResponse } from "next/server"
import { headers } from "next/headers"
import { auth } from "@/lib/auth"

export async function GET(request: NextRequest) {
  try {
    const session = await auth.api.getSession({
      headers: await headers(),
    })

    if (!session) {
      return NextResponse.json(
        { error: { message: "No hay sesión activa" } },
        { status: 401 }
      )
    }

    return NextResponse.json({
      data: {
        user: session.user,
        session: {
          id: session.session.id,
          userId: session.session.userId,
        },
      },
    })
  } catch (error) {
    console.error("Error getting session:", error)
    return NextResponse.json(
      { error: { message: "Error al obtener la sesión" } },
      { status: 500 }
    )
  }
}
