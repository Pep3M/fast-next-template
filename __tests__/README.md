# Tests Suite - Phone Services CRM

Suite completa de tests usando **bun:test** para garantizar velocidad y estabilidad.

## 📁 Estructura

```
__tests__/
├── setup.ts                    # Configuración global de tests
├── mocks/                      # Mocks para dependencias externas
│   └── soap-responses.ts       # Respuestas SOAP simuladas
├── unit/                       # Tests unitarios
│   └── services/               # Tests de servicios
│       ├── session-manager.test.ts
│       ├── recharge-services.test.ts
│       └── cubacel-service.test.ts
├── integration/                # Tests de integración
│   └── api/                    # Tests de endpoints API
│       └── cubacel.test.ts
└── utils/                      # Tests de utilidades
    └── validators.test.ts
```

## 🚀 Comandos

### Ejecutar todos los tests
```bash
bun test
```

### Watch mode (re-ejecuta en cambios)
```bash
bun run test:watch
```

### Con cobertura de código
```bash
bun run test:coverage
```

### Ejecutar un archivo específico
```bash
bun test __tests__/unit/services/session-manager.test.ts
```

### Ejecutar tests que coincidan con un patrón
```bash
bun test --test-name-pattern "session"
```

## 📊 Cobertura

El proyecto está configurado con un umbral mínimo de **60% de cobertura**. Los reportes se generan en:
- `coverage/` - Reporte HTML (abre `coverage/index.html` en el navegador)
- Terminal - Reporte de texto

## 🧪 Áreas Cubiertas

### 1. Servicios de Cubacel (Unit Tests)

#### SessionManager
- ✅ Obtención de ticket de sesión
- ✅ Reutilización de tickets válidos
- ✅ Invalidación de tickets
- ✅ Manejo de errores de autenticación
- ✅ Manejo de errores de red
- ✅ Respuestas SOAP malformadas

#### RechargeServices
- ✅ Consulta de balance
- ✅ Verificación de números telefónicos
- ✅ Procesamiento de recargas exitosas
- ✅ Manejo de errores en recargas
- ✅ Validación de formatos

#### CubacelService
- ✅ Inicialización correcta de categorías
- ✅ Invalidación de sesión
- ✅ Verificación de validez de sesión
- ✅ Compartición de sesión entre servicios

### 2. Integración (Integration Tests)

#### API de Cubacel
- ✅ Flujo completo de recarga
- ✅ Expiración y renovación automática de sesión
- ✅ Manejo de peticiones concurrentes

### 3. Utilidades (Utils Tests)

#### Validadores
- ✅ Validación de números telefónicos cubanos
- ✅ Validación de montos de recarga
- ✅ Generación de IDs de transacción
- ✅ Formateo de monedas

## 🎯 Próximos Tests a Implementar

### Servicios Turísticos
- [ ] Tests para `TouristServices`
  - `saleBatchPackage()`
  - `suppleCustInfo()`
  - `getSuppleInfo()`

### API Routes
- [ ] Tests para endpoints de autenticación
- [ ] Tests para endpoints de usuario
- [ ] Tests para endpoints de balance

### Base Service
- [ ] Tests para retry automático
- [ ] Tests para manejo de errores SOAP

### Componentes React (opcional)
- [ ] Tests de componentes del dashboard
- [ ] Tests de formularios
- [ ] Tests de navegación

## 🔧 Configuración

La configuración de tests está en `bunfig.toml`:

```toml
[test]
preload = ["__tests__/setup.ts"]      # Carga setup antes de tests
root = "./__tests__"                   # Directorio raíz de tests
timeout = 10000                        # 10 segundos por test
coverage = true                        # Habilitar cobertura
coverageThreshold = 60                 # 60% mínimo
```

## 💡 Buenas Prácticas

### 1. Usar Mocks para Dependencias Externas
```typescript
import { createFetchMock } from '../../mocks/soap-responses';

global.fetch = createFetchMock(responseMap) as typeof fetch;
```

### 2. Limpiar Estado Entre Tests
```typescript
beforeEach(() => {
  sessionManager = new SessionManager();
  originalFetch = global.fetch;
});
```

### 3. Tests Descriptivos
```typescript
test('should reuse valid ticket', async () => {
  // Arrange
  // Act
  // Assert
});
```

### 4. Agrupar Tests Relacionados
```typescript
describe('RechargeServices', () => {
  describe('getBalance', () => {
    test('should get account balance successfully', async () => {
      // ...
    });
  });
});
```

## 🐛 Debugging Tests

### Ver output detallado
```bash
bun test --verbose
```

### Ejecutar solo un test
```bash
bun test --test-name-pattern "should get a new session ticket"
```

### Detener en el primer fallo
```bash
bun test --bail
```

## 📚 Recursos

- [Bun Test Documentation](https://bun.sh/docs/cli/test)
- [Bun Test API](https://bun.sh/docs/test/writing)
- Documentación API Cubacel: `docs/modelo_conexion.md`

## ⚡ Performance

Bun:test es extremadamente rápido:
- ⚡ ~100ms para suite completa (sin llamadas reales)
- 🔄 Watch mode con hot reload
- 📦 Zero config - funciona out of the box
- 🎯 Ejecución paralela por defecto

## 🤝 Contribuir

Al agregar nuevas funcionalidades:

1. Escribe el test primero (TDD)
2. Implementa la funcionalidad
3. Asegúrate de que todos los tests pasen
4. Verifica la cobertura: `bun run test:coverage`
5. Commit con tests incluidos

## ⚠️ Importante

- Los tests NO requieren servicios externos en ejecución
- Todos los servicios SOAP están mockeados
- La base de datos no es necesaria para tests unitarios
- Los tests de integración pueden requerir .env configurado
