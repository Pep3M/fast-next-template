"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { Separator } from "@/components/ui/separator"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { useSession, useUpdateProfile, useChangePassword, useDeleteAccount } from "@/lib/hooks/use-auth"
import { Loader2 } from "lucide-react"

export default function SettingsPage() {
  const { data: sessionData, isLoading: isLoadingSession } = useSession()
  const user = sessionData?.data?.user

  // Estados para el formulario de perfil
  const [name, setName] = useState(user?.name || "")
  const [phone, setPhone] = useState(user?.phone || "")
  const [isProfileDirty, setIsProfileDirty] = useState(false)

  // Estados para el formulario de contraseña
  const [currentPassword, setCurrentPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [passwordErrors, setPasswordErrors] = useState<Record<string, string>>({})

  // Hooks de mutación
  const updateProfileMutation = useUpdateProfile()
  const changePasswordMutation = useChangePassword()
  const deleteAccountMutation = useDeleteAccount()

  // Actualizar estados cuando cambie el usuario
  useEffect(() => {
    if (user) {
      setName(user.name || "")
      setPhone(user.phone || "")
      setIsProfileDirty(false)
    }
  }, [user])

  // Validar cambios en el perfil
  const handleProfileChange = (field: "name" | "phone", value: string) => {
    if (field === "name") {
      setName(value)
      setIsProfileDirty(value !== (user?.name || ""))
    } else if (field === "phone") {
      setPhone(value)
      setIsProfileDirty(value !== (user?.phone || ""))
    }
  }

  // Validar formulario de contraseña
  const validatePassword = () => {
    const errors: Record<string, string> = {}

    if (!currentPassword) {
      errors.currentPassword = "La contraseña actual es requerida"
    }

    if (!newPassword) {
      errors.newPassword = "La nueva contraseña es requerida"
    } else if (newPassword.length < 8) {
      errors.newPassword = "La contraseña debe tener al menos 8 caracteres"
    }

    if (!confirmPassword) {
      errors.confirmPassword = "Confirma la nueva contraseña"
    } else if (newPassword !== confirmPassword) {
      errors.confirmPassword = "Las contraseñas no coinciden"
    }

    if (currentPassword && newPassword && currentPassword === newPassword) {
      errors.newPassword = "La nueva contraseña debe ser diferente a la actual"
    }

    setPasswordErrors(errors)
    return Object.keys(errors).length === 0
  }

  // Manejar actualización de perfil
  const handleUpdateProfile = async () => {
    if (!isProfileDirty) return

    // Validaciones
    if (name.trim().length === 0) {
      return
    }

    if (phone.trim().length > 0) {
      const phoneRegex = /^[\d\s\+\-\(\)]+$/
      if (!phoneRegex.test(phone)) {
        return
      }
    }

    await updateProfileMutation.mutateAsync({
      name: name.trim() || undefined,
      phone: phone.trim() || undefined,
    })

    setIsProfileDirty(false)
  }

  // Manejar cambio de contraseña
  const handleChangePassword = async () => {
    if (!validatePassword()) return

    await changePasswordMutation.mutateAsync({
      currentPassword,
      newPassword,
    })

    // Limpiar formulario después de éxito
    setCurrentPassword("")
    setNewPassword("")
    setConfirmPassword("")
    setPasswordErrors({})
  }

  // Manejar eliminación de cuenta
  const handleDeleteAccount = async () => {
    await deleteAccountMutation.mutateAsync()
  }

  if (isLoadingSession) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6 p-6 max-w-4xl">
      <div className="flex flex-col gap-2">
        <h1 className="text-3xl font-bold text-foreground">Configuración</h1>
        <p className="text-muted-foreground">Administra las preferencias del sistema</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Perfil de Usuario</CardTitle>
          <CardDescription>Actualiza tu información personal</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-2">
            <Label htmlFor="name">Nombre completo</Label>
            <Input
              id="name"
              placeholder="Tu nombre"
              value={name}
              onChange={(e) => handleProfileChange("name", e.target.value)}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="email">Correo electrónico</Label>
            <Input id="email" type="email" value={user?.email || ""} disabled className="bg-muted" />
            <p className="text-xs text-muted-foreground">El correo electrónico no puede ser modificado</p>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="phone">Teléfono</Label>
            <Input
              id="phone"
              type="tel"
              placeholder="+1 234 567 8900"
              value={phone}
              onChange={(e) => handleProfileChange("phone", e.target.value)}
            />
            {phone.trim().length > 0 && !/^[\d\s\+\-\(\)]+$/.test(phone) && (
              <p className="text-xs text-destructive">Formato de teléfono inválido</p>
            )}
          </div>
          <Button onClick={handleUpdateProfile} disabled={!isProfileDirty || updateProfileMutation.isPending}>
            {updateProfileMutation.isPending ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Guardando...
              </>
            ) : (
              "Guardar cambios"
            )}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Notificaciones</CardTitle>
          <CardDescription>Configura cómo quieres recibir notificaciones</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Nuevos pedidos</Label>
              <p className="text-sm text-muted-foreground">Recibe notificaciones de nuevos pedidos</p>
            </div>
            <Switch defaultChecked />
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Tickets de soporte</Label>
              <p className="text-sm text-muted-foreground">Alertas de nuevos tickets</p>
            </div>
            <Switch defaultChecked />
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Nuevos clientes</Label>
              <p className="text-sm text-muted-foreground">Notificación de registros nuevos</p>
            </div>
            <Switch />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Seguridad</CardTitle>
          <CardDescription>Gestiona la seguridad de tu cuenta</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-4">
            <div className="grid gap-2">
              <Label htmlFor="currentPassword">Contraseña actual</Label>
              <Input
                id="currentPassword"
                type="password"
                placeholder="••••••••"
                value={currentPassword}
                onChange={(e) => {
                  setCurrentPassword(e.target.value)
                  if (passwordErrors.currentPassword) {
                    setPasswordErrors({ ...passwordErrors, currentPassword: "" })
                  }
                }}
              />
              {passwordErrors.currentPassword && (
                <p className="text-xs text-destructive">{passwordErrors.currentPassword}</p>
              )}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="newPassword">Nueva contraseña</Label>
              <Input
                id="newPassword"
                type="password"
                placeholder="••••••••"
                value={newPassword}
                onChange={(e) => {
                  setNewPassword(e.target.value)
                  if (passwordErrors.newPassword) {
                    setPasswordErrors({ ...passwordErrors, newPassword: "" })
                  }
                }}
              />
              {passwordErrors.newPassword && (
                <p className="text-xs text-destructive">{passwordErrors.newPassword}</p>
              )}
              <p className="text-xs text-muted-foreground">Mínimo 8 caracteres</p>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="confirmPassword">Confirmar nueva contraseña</Label>
              <Input
                id="confirmPassword"
                type="password"
                placeholder="••••••••"
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value)
                  if (passwordErrors.confirmPassword) {
                    setPasswordErrors({ ...passwordErrors, confirmPassword: "" })
                  }
                }}
              />
              {passwordErrors.confirmPassword && (
                <p className="text-xs text-destructive">{passwordErrors.confirmPassword}</p>
              )}
            </div>
            <Button
              onClick={handleChangePassword}
              disabled={changePasswordMutation.isPending || !currentPassword || !newPassword || !confirmPassword}
              className="w-full"
            >
              {changePasswordMutation.isPending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Cambiando contraseña...
                </>
              ) : (
                "Cambiar contraseña"
              )}
            </Button>
          </div>

          <Separator />

          <div className="space-y-2">
            <p className="text-sm text-muted-foreground">
              La autenticación de dos factores estará disponible próximamente.
            </p>
            <Button variant="outline" className="w-full bg-transparent" disabled>
              Configurar autenticación de dos factores
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card className="border-destructive">
        <CardHeader>
          <CardTitle className="text-destructive">Zona de Peligro</CardTitle>
          <CardDescription>Acciones irreversibles relacionadas con tu cuenta</CardDescription>
        </CardHeader>
        <CardContent>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" className="w-full" disabled={deleteAccountMutation.isPending}>
                {deleteAccountMutation.isPending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Eliminando...
                  </>
                ) : (
                  "Eliminar cuenta"
                )}
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>¿Estás seguro?</AlertDialogTitle>
                <AlertDialogDescription>
                  Esta acción no se puede deshacer. Tu cuenta será eliminada de forma permanente (soft delete) y no
                  podrás acceder al sistema. Esta acción solo está permitida si hay otros usuarios activos en el
                  sistema.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                <AlertDialogAction onClick={handleDeleteAccount} className="bg-destructive text-destructive-foreground">
                  Eliminar cuenta
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </CardContent>
      </Card>
    </div>
  )
}
