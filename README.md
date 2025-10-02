# 📦 Sistema de Gestión de Inventario SENA

<div align="center">
<img width="649" height="628" alt="sena_logo" src="https://github.com/user-attachments/assets/568f1412-82ec-4196-af51-6ba87d84ce69" />


**Sistema Integral de Gestión de Inventario para Ambientes de Formación**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791?logo=postgresql)](https://www.postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 👨‍💻 Autor

**Duvan Yair Arciniegas Gerena**  
Tecnólogo en Análisis y Desarrollo de Software  
Servicio Nacional de Aprendizaje (SENA)

---

## 📋 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Características Principales](#-características-principales)
- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Roles y Permisos](#-roles-y-permisos)
- [Flujo de Verificación de Inventario](#-flujo-de-verificación-de-inventario)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Módulos del Sistema](#-módulos-del-sistema)
- [API Endpoints](#-api-endpoints)
- [Modelos de Datos](#-modelos-de-datos)
- [Capturas de Pantalla](#-capturas-de-pantalla)
- [Contribución](#-contribución)
- [Licencia](#-licencia)

---

## 🎯 Descripción General

El **Sistema de Gestión de Inventario SENA** es una aplicación multiplataforma desarrollada con Flutter y FastAPI, diseñada específicamente para gestionar el inventario de equipos y herramientas en los ambientes de formación del SENA. El sistema implementa un flujo de verificación diaria en tres etapas (Estudiante → Instructor → Supervisor) que garantiza el control, seguimiento y mantenimiento adecuado de los recursos educativos.

### 🎓 Contexto Educativo

Este proyecto fue desarrollado como parte del programa de **Tecnología en Análisis y Desarrollo de Software** del SENA, con el objetivo de digitalizar y optimizar los procesos de gestión de inventario en los centros de formación, reemplazando los métodos manuales tradicionales por una solución tecnológica moderna, eficiente y escalable.

---

## ✨ Características Principales

### 🔐 Gestión de Usuarios y Autenticación
- ✅ Sistema de autenticación JWT con tokens seguros
- ✅ Registro y login con validación de credenciales
- ✅ Gestión de perfiles de usuario con avatar personalizable
- ✅ Cambio de contraseña y recuperación de cuenta
- ✅ Control de sesiones activas y último acceso

### 📊 Dashboard Personalizado por Rol
- 📈 **Estudiante**: Vista de ambiente asignado, verificaciones pendientes, notificaciones
- 👨‍🏫 **Instructor**: Revisión de verificaciones, gestión de préstamos, horarios
- 👔 **Supervisor**: Aprobación final, estadísticas globales, alertas críticas
- 🏢 **Administrador de Almacén**: Gestión de préstamos, inventario de bodega
- 🌐 **Administrador General**: Vista completa del sistema, reportes, auditoría

### 📦 Gestión de Inventario
- ➕ Agregar, editar y eliminar elementos del inventario
- 🏷️ Categorización por tipo: computadores, proyectores, teclados, mouse, TV, cámaras, micrófonos, tablets
- 📊 Seguimiento de cantidades: disponibles, dañados, faltantes
- 🔢 Soporte para items individuales y grupales (cantidad múltiple)
- 📸 Carga de imágenes de equipos
- 🔍 Códigos internos y números de serie únicos
- 📅 Fechas de compra, garantía y mantenimiento
- 📝 Notas y observaciones por equipo

### ✅ Verificación de Inventario (Flujo de 3 Etapas)

#### **Etapa 1: Estudiante** 🎓
- Escanea QR del ambiente para vincularse
- Realiza verificación diaria del inventario
- Marca estado de cada equipo (bueno, dañado, faltante)
- Agrega notas sobre limpieza y organización
- Confirma verificación con timestamp

#### **Etapa 2: Instructor** 👨‍🏫
- Revisa la verificación del estudiante
- Valida tres aspectos críticos:
  - ✅ **Aula Limpia**: Estado de limpieza del ambiente
  - ✅ **Inventario Completo**: Todos los equipos presentes
  - ✅ **Aula Organizada**: Orden y disposición adecuada
- Agrega comentarios adicionales
- Aprueba o rechaza la verificación

#### **Etapa 3: Supervisor** 👔
- Revisión final de la verificación
- Validación de los checks del instructor
- Aprobación o rechazo definitivo
- Generación de alertas si hay problemas
- Cierre del proceso de verificación

### 🔧 Solicitudes de Mantenimiento
- 📝 Creación de solicitudes con título, descripción y prioridad
- 📷 Adjuntar imágenes del problema
- 🏷️ Categorización: preventivo, correctivo, emergencia
- 📍 Ubicación específica del equipo
- 🔄 Estados: pendiente, en progreso, completado, cancelado
- 💰 Registro de costos de mantenimiento
- 📊 Historial completo de mantenimientos por equipo
- 🔔 Notificaciones automáticas a supervisores

### 📤 Sistema de Préstamos
- 📋 Solicitud de préstamos por instructores
- 🏢 Préstamos entre ambientes del mismo centro
- 📦 Soporte para items registrados y personalizados
- ⏰ Fechas de inicio y fin del préstamo
- 🎯 Niveles de prioridad: baja, media, alta, urgente
- ✅ Aprobación/rechazo por administradores de almacén
- 📄 Generación de actas en PDF
- 🔔 Alertas de préstamos vencidos
- 📊 Historial completo de préstamos

### 📱 Escaneo QR
- 📷 Escaneo de códigos QR para identificar ambientes
- 🔗 Vinculación automática de estudiantes a ambientes
- 🏷️ Generación de códigos QR para equipos y ambientes
- ⚡ Acceso rápido a información del elemento

### 🔔 Sistema de Notificaciones
- 📬 Notificaciones en tiempo real
- 🎨 Categorización por tipo y prioridad
- ✅ Marcado de leídas/no leídas
- 🔴 Badge con contador de notificaciones pendientes
- 📊 Historial completo de notificaciones

### 📈 Reportes y Estadísticas
- 📊 Dashboard con métricas en tiempo real
- 📉 Gráficos de tendencias y análisis
- 📄 Generación de reportes en PDF, Excel y CSV
- 📋 Tipos de reportes:
  - Inventario completo
  - Préstamos activos
  - Solicitudes de mantenimiento
  - Auditoría de acciones
  - Verificaciones por período
- 📅 Filtros por fecha, ambiente y categoría
- 💾 Descarga y almacenamiento de reportes

### 🔍 Auditoría y Trazabilidad
- 📝 Registro automático de todas las acciones
- 👤 Identificación de usuario, rol y timestamp
- 🌐 Captura de IP y detalles de la petición
- 📊 Visualización de logs de auditoría
- 🔎 Búsqueda y filtrado avanzado
- 📄 Exportación de logs para análisis

### 🌍 Gestión de Ambientes
- 🏢 Organización por centros de formación
- 📍 Ambientes con ubicación y descripción
- 🏷️ Identificación de bodegas/almacenes
- 📅 Gestión de horarios por ambiente
- 👥 Asignación de instructores y estudiantes
- 📊 Vista general del ambiente con estadísticas

### ⚙️ Configuración y Personalización
- 🌓 Modo claro/oscuro
- 🌐 Soporte multiidioma (preparado)
- 👤 Personalización de perfil
- 🔔 Configuración de alertas
- 📧 Preferencias de notificaciones

### 💬 Sistema de Feedback
- 📝 Formulario de comentarios y sugerencias
- ⭐ Calificación de la experiencia
- 📊 Recopilación de mejoras
- 🔄 Seguimiento de feedback

---

## 🏗️ Arquitectura del Sistema

### Arquitectura General

\`\`\`
┌─────────────────────────────────────────────────────────────┐
│                    APLICACIÓN FLUTTER                        │
│                  (Multiplataforma: iOS, Android, Web)        │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer                                          │
│  ├── Screens (Pantallas por rol)                            │
│  ├── Widgets (Componentes reutilizables)                    │
│  └── Providers (Estado global con Provider)                 │
├─────────────────────────────────────────────────────────────┤
│  Core Layer                                                  │
│  ├── Services (Lógica de negocio)                           │
│  ├── Theme (Estilos y colores)                              │
│  └── Constants (Configuración)                              │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ├── Models (Modelos de datos)                              │
│  └── API Service (Comunicación HTTP)                        │
└─────────────────────────────────────────────────────────────┘
                            ↕ HTTP/REST
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND FASTAPI                           │
├─────────────────────────────────────────────────────────────┤
│  API Layer                                                   │
│  ├── Routers (Endpoints REST)                               │
│  ├── Schemas (Validación Pydantic)                          │
│  └── Middleware (Auditoría, CORS)                           │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                        │
│  ├── Services (Lógica de negocio)                           │
│  └── Utils (Utilidades y helpers)                           │
├─────────────────────────────────────────────────────────────┤
│  Data Access Layer                                           │
│  ├── Models (SQLAlchemy ORM)                                │
│  └── Database (Conexión PostgreSQL)                         │
└─────────────────────────────────────────────────────────────┘
                            ↕ SQL
┌─────────────────────────────────────────────────────────────┐
│                    BASE DE DATOS                             │
│                    PostgreSQL 14+                            │
│  ├── Tablas de usuarios y autenticación                     │
│  ├── Tablas de inventario y equipos                         │
│  ├── Tablas de verificaciones y checks                      │
│  ├── Tablas de préstamos y mantenimiento                    │
│  ├── Tablas de notificaciones y alertas                     │
│  └── Tablas de auditoría y reportes                         │
└─────────────────────────────────────────────────────────────┘
\`\`\`

### Patrón de Arquitectura

**Frontend (Flutter):**
- **Clean Architecture** con separación de capas
- **Provider** para gestión de estado
- **Repository Pattern** para acceso a datos
- **Service Layer** para lógica de negocio

**Backend (FastAPI):**
- **RESTful API** con endpoints bien definidos
- **SQLAlchemy ORM** para abstracción de base de datos
- **Pydantic** para validación de datos
- **JWT** para autenticación y autorización
- **Middleware** para auditoría automática

---

## 👥 Roles y Permisos

### 🎓 Estudiante (student)
**Permisos:**
- ✅ Escanear QR para vincularse a ambientes
- ✅ Realizar verificaciones diarias de inventario
- ✅ Ver inventario del ambiente asignado
- ✅ Solicitar mantenimiento de equipos
- ✅ Ver notificaciones personales
- ✅ Actualizar perfil personal
- ✅ Enviar feedback

**Restricciones:**
- ❌ No puede aprobar verificaciones
- ❌ No puede gestionar préstamos
- ❌ No puede acceder a otros ambientes
- ❌ No puede generar reportes

### 👨‍🏫 Instructor (instructor)
**Permisos:**
- ✅ Todos los permisos de estudiante
- ✅ Revisar y aprobar verificaciones de estudiantes
- ✅ Solicitar préstamos de equipos
- ✅ Ver historial de préstamos
- ✅ Gestionar horarios de su ambiente
- ✅ Ver estadísticas de su ambiente
- ✅ Generar reportes básicos

**Restricciones:**
- ❌ No puede aprobar préstamos
- ❌ No puede acceder a auditoría completa
- ❌ No puede gestionar usuarios

### 👔 Supervisor (supervisor)
**Permisos:**
- ✅ Todos los permisos de instructor
- ✅ Aprobación final de verificaciones
- ✅ Ver verificaciones de múltiples ambientes
- ✅ Gestionar solicitudes de mantenimiento
- ✅ Ver estadísticas globales
- ✅ Generar reportes avanzados
- ✅ Acceder a alertas del sistema

**Restricciones:**
- ❌ No puede gestionar préstamos de almacén
- ❌ No puede gestionar usuarios
- ❌ No puede acceder a auditoría completa

### 🏢 Administrador de Almacén (admin)
**Permisos:**
- ✅ Gestionar inventario de bodega
- ✅ Aprobar/rechazar préstamos
- ✅ Gestionar devoluciones
- ✅ Ver estadísticas de préstamos
- ✅ Generar actas de préstamo
- ✅ Gestionar items del almacén

**Restricciones:**
- ❌ No puede aprobar verificaciones
- ❌ No puede gestionar usuarios
- ❌ Acceso limitado a otros ambientes

### 🌐 Administrador General (admin_general)
**Permisos:**
- ✅ **Acceso total al sistema**
- ✅ Gestionar todos los usuarios
- ✅ Ver y gestionar todos los ambientes
- ✅ Acceder a auditoría completa
- ✅ Generar todos los tipos de reportes
- ✅ Configurar alertas del sistema
- ✅ Ver estadísticas globales
- ✅ Gestionar centros de formación
- ✅ Configuración avanzada del sistema

---

## 🔄 Flujo de Verificación de Inventario

### Proceso Completo de Verificación Diaria

\`\`\`
┌─────────────────────────────────────────────────────────────┐
│                    INICIO DEL DÍA                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  ETAPA 1: ESTUDIANTE                                         │
│  ─────────────────────────────────────────────────────────  │
│  1. Escanea QR del ambiente                                  │
│  2. Sistema carga inventario del ambiente                    │
│  3. Revisa cada equipo físicamente                           │
│  4. Marca estado: ✅ Bueno | ⚠️ Dañado | ❌ Faltante        │
│  5. Agrega notas sobre limpieza                              │
│  6. Confirma verificación                                    │
│  7. Estado: "student_pending" → "instructor_review"          │
│  8. 🔔 Notificación enviada al instructor                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  ETAPA 2: INSTRUCTOR                                         │
│  ─────────────────────────────────────────────────────────  │
│  1. Recibe notificación de verificación pendiente            │
│  2. Revisa la verificación del estudiante                    │
│  3. Valida físicamente el ambiente                           │
│  4. Marca tres checks obligatorios:                          │
│     ✅ Aula Limpia (is_clean)                                │
│     ✅ Inventario Completo (inventory_complete)              │
│     ✅ Aula Organizada (is_organized)                        │
│  5. Agrega comentarios adicionales                           │
│  6. Confirma revisión                                        │
│  7. Estado: "instructor_review" → "supervisor_review"        │
│  8. 🔔 Notificación enviada al supervisor                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  ETAPA 3: SUPERVISOR                                         │
│  ─────────────────────────────────────────────────────────  │
│  1. Recibe notificación de verificación lista                │
│  2. Revisa checks del instructor                             │
│  3. Valida información completa                              │
│  4. Toma decisión final:                                     │
│     ✅ APROBAR → Estado: "complete"                          │
│     ❌ RECHAZAR → Estado: "rejected"                         │
│     ⚠️ PROBLEMAS → Estado: "issues"                          │
│  5. Agrega comentarios finales                               │
│  6. Confirma aprobación/rechazo                              │
│  7. 🔔 Notificaciones a estudiante e instructor              │
│  8. Si hay problemas: genera alertas automáticas             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  RESULTADO FINAL                                             │
│  ─────────────────────────────────────────────────────────  │
│  ✅ COMPLETADO: Verificación exitosa, ambiente OK            │
│  ⚠️ CON PROBLEMAS: Equipos dañados/faltantes detectados      │
│  ❌ RECHAZADO: Verificación no cumple estándares             │
│                                                              │
│  → Registro en historial                                     │
│  → Actualización de estadísticas                             │
│  → Generación de alertas si es necesario                     │
│  → Creación de solicitudes de mantenimiento automáticas      │
└─────────────────────────────────────────────────────────────┘
\`\`\`

### Estados de Verificación

| Estado | Descripción | Siguiente Acción |
|--------|-------------|------------------|
| `student_pending` | Estudiante debe realizar verificación | Estudiante completa check |
| `instructor_review` | Esperando revisión del instructor | Instructor valida |
| `supervisor_review` | Esperando aprobación del supervisor | Supervisor aprueba/rechaza |
| `complete` | Verificación completada exitosamente | Ninguna (proceso finalizado) |
| `issues` | Problemas detectados en el inventario | Generar mantenimiento |
| `rejected` | Verificación rechazada | Reiniciar proceso |

---

## 🛠️ Tecnologías Utilizadas

### Frontend (Aplicación Móvil/Web)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| ![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter) | 3.0+ | Framework multiplataforma |
| ![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart) | 3.0+ | Lenguaje de programación |
| ![Provider](https://img.shields.io/badge/Provider-6.0+-FF6B6B) | 6.0+ | Gestión de estado |
| ![Go Router](https://img.shields.io/badge/Go_Router-12.0+-00ADD8) | 12.0+ | Navegación y rutas |
| ![Google Fonts](https://img.shields.io/badge/Google_Fonts-6.0+-4285F4?logo=google) | 6.0+ | Tipografías personalizadas |
| ![QR Code Scanner](https://img.shields.io/badge/QR_Scanner-1.0+-000000) | 1.0+ | Escaneo de códigos QR |
| ![JSON Serializable](https://img.shields.io/badge/JSON_Serializable-6.0+-FFA500) | 6.0+ | Serialización de datos |

### Backend (API REST)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| ![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python) | 3.11+ | Lenguaje de programación |
| ![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi) | 0.100+ | Framework web moderno |
| ![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0+-D71F00) | 2.0+ | ORM para base de datos |
| ![Pydantic](https://img.shields.io/badge/Pydantic-2.0+-E92063) | 2.0+ | Validación de datos |
| ![JWT](https://img.shields.io/badge/JWT-2.0+-000000?logo=jsonwebtokens) | 2.0+ | Autenticación segura |
| ![Alembic](https://img.shields.io/badge/Alembic-1.12+-6BA81E) | 1.12+ | Migraciones de BD |
| ![Uvicorn](https://img.shields.io/badge/Uvicorn-0.24+-499848) | 0.24+ | Servidor ASGI |
| ![Bcrypt](https://img.shields.io/badge/Bcrypt-4.0+-338033) | 4.0+ | Hash de contraseñas |

### Base de Datos

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791?logo=postgresql) | 14+ | Base de datos relacional |
| ![UUID](https://img.shields.io/badge/UUID-Extension-4169E1) | - | Identificadores únicos |

### Herramientas de Desarrollo

| Herramienta | Propósito |
|-------------|-----------|
| ![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?logo=docker) | Contenedorización |
| ![Git](https://img.shields.io/badge/Git-2.40+-F05032?logo=git) | Control de versiones |
| ![VS Code](https://img.shields.io/badge/VS_Code-1.80+-007ACC?logo=visualstudiocode) | Editor de código |
| ![Postman](https://img.shields.io/badge/Postman-10.0+-FF6C37?logo=postman) | Testing de API |

### Librerías Adicionales

**Flutter:**
- `http`: Cliente HTTP para peticiones REST
- `shared_preferences`: Almacenamiento local
- `intl`: Internacionalización y formatos
- `image_picker`: Selección de imágenes
- `qr_flutter`: Generación de códigos QR
- `flutter_localizations`: Soporte multiidioma

**Python:**
- `python-jose`: Manejo de JWT
- `passlib`: Hashing de contraseñas
- `python-multipart`: Manejo de archivos
- `reportlab`: Generación de PDFs
- `pandas`: Procesamiento de datos para reportes
- `openpyxl`: Generación de archivos Excel
- `pytz`: Manejo de zonas horarias

---

## 📁 Estructura del Proyecto

### Frontend (Flutter)

\`\`\`
lib/
├── core/                           # Núcleo de la aplicación
│   ├── constants/
│   │   └── api_constants.dart      # URLs y constantes de API
│   ├── services/                   # Servicios de negocio
│   │   ├── api_service.dart        # Cliente HTTP
│   │   ├── auth_service.dart       # Autenticación
│   │   ├── navigation_service.dart # Navegación y rutas
│   │   ├── notification_service.dart # Notificaciones
│   │   ├── storage_service.dart    # Almacenamiento local
│   │   ├── theme_service.dart      # Temas claro/oscuro
│   │   ├── language_service.dart   # Multiidioma
│   │   ├── session_service.dart    # Gestión de sesiones
│   │   ├── role_navigation_service.dart # Navegación por rol
│   │   ├── alert_service.dart      # Alertas del sistema
│   │   ├── maintenance_service.dart # Mantenimiento
│   │   ├── report_service.dart     # Generación de reportes
│   │   ├── audit_service.dart      # Auditoría
│   │   ├── profile_service.dart    # Perfiles de usuario
│   │   └── user_management_service.dart # Gestión de usuarios
│   └── theme/
│       ├── app_colors.dart         # Paleta de colores
│       └── app_theme.dart          # Tema de la app
│
├── data/                           # Capa de datos
│   └── models/                     # Modelos de datos
│       ├── user_model.dart         # Usuario
│       ├── inventory_item_model.dart # Item de inventario
│       ├── inventory_check_model.dart # Verificación
│       ├── inventory_check_item_model.dart # Item de verificación
│       ├── environment_model.dart  # Ambiente
│       ├── loan_model.dart         # Préstamo
│       ├── maintenance_request_model.dart # Mantenimiento
│       ├── notification_model.dart # Notificación
│       ├── alert_model.dart        # Alerta
│       └── alert_settings_model.dart # Configuración de alertas
│
├── presentation/                   # Capa de presentación
│   ├── providers/                  # Gestión de estado
│   │   ├── auth_provider.dart      # Estado de autenticación
│   │   └── loan_provider.dart      # Estado de préstamos
│   │
│   ├── screens/                    # Pantallas de la app
│   │   ├── auth/
│   │   │   ├── login_screen.dart   # Inicio de sesión
│   │   │   └── register_screen.dart # Registro
│   │   ├── dashboard/              # Dashboards por rol
│   │   │   ├── student_dashboard.dart
│   │   │   ├── instructor_dashboard.dart
│   │   │   ├── supervisor_dashboard_screen.dart
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   └── general_admin_dashboard_screen.dart
│   │   ├── inventory/              # Gestión de inventario
│   │   │   ├── AddInventoryItemScreen.dart
│   │   │   ├── edit_inventory_item_screen.dart
│   │   │   ├── inventory_check_screen.dart
│   │   │   ├── inventory_history_screen.dart
│   │   │   └── inventory_alerts_screen.dart
│   │   ├── loan/                   # Gestión de préstamos
│   │   │   ├── loan_request_screen.dart
│   │   │   ├── loan_management_screen.dart
│   │   │   └── loan_history_screen.dart
│   │   ├── maintenance/            # Mantenimiento
│   │   │   └── maintenance_request_screen.dart
│   │   ├── environment/            # Ambientes
│   │   │   ├── environment_overview_screen.dart
│   │   │   └── manage_schedules_screen.dart
│   │   ├── qr/                     # Códigos QR
│   │   │   ├── qr_scan_screen.dart
│   │   │   └── qr_code_generator_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   ├── reports/
│   │   │   └── report_generator_screen.dart
│   │   ├── statistics/
│   │   │   └── statistics_dashboard.dart
│   │   ├── audit/
│   │   │   └── audit_log_screen.dart
│   │   ├── admin/
│   │   │   └── user_management_screen.dart
│   │   ├── training/
│   │   │   └── training_schedule_screen.dart
│   │   ├── feedback/
│   │   │   └── feedback_form_screen.dart
│   │   └── splash/
│   │       └── splash_screen.dart
│   │
│   └── widgets/                    # Componentes reutilizables
│       ├── common/
│       │   ├── sena_app_bar.dart   # AppBar personalizado
│       │   ├── sena_card.dart      # Card personalizado
│       │   ├── status_badge.dart   # Badge de estado
│       │   └── notification_badge.dart # Badge de notificaciones
│       ├── alerts/
│       │   ├── alert_detail_modal.dart
│       │   └── maintenance_alert_detail_modal.dart
│       └── maintenance/
│           └── maintenance_history_modal.dart
│
├── app.dart                        # Configuración de la app
└── main.dart                       # Punto de entrada
\`\`\`

### Backend (FastAPI)

\`\`\`
server/
├── app/
│   ├── __init__.py
│   ├── main.py                     # Aplicación principal
│   ├── config.py                   # Configuración
│   ├── database.py                 # Conexión a BD
│   │
│   ├── middleware/                 # Middleware
│   │   └── audit_middleware.py     # Auditoría automática
│   │
│   ├── models/                     # Modelos SQLAlchemy
│   │   ├── __init__.py
│   │   ├── users.py                # Usuarios
│   │   ├── environments.py         # Ambientes
│   │   ├── centers.py              # Centros de formación
│   │   ├── inventory_items.py      # Items de inventario
│   │   ├── inventory_checks.py     # Verificaciones
│   │   ├── inventory_check_items.py # Items de verificación
│   │   ├── loans.py                # Préstamos
│   │   ├── maintenance_requests.py # Solicitudes de mantenimiento
│   │   ├── maintenance_history.py  # Historial de mantenimiento
│   │   ├── schedules.py            # Horarios
│   │   ├── notifications.py        # Notificaciones
│   │   ├── system_alerts.py        # Alertas del sistema
│   │   ├── alert_settings.py       # Configuración de alertas
│   │   ├── supervisor_reviews.py   # Revisiones de supervisor
│   │   ├── audit_logs.py           # Logs de auditoría
│   │   ├── generated_reports.py    # Reportes generados
│   │   ├── feedback.py             # Feedback de usuarios
│   │   └── user_settings.py        # Configuración de usuarios
│   │
│   ├── schemas/                    # Esquemas Pydantic
│   │   ├── user.py                 # Esquemas de usuario
│   │   ├── inventory_item.py       # Esquemas de inventario
│   │   ├── inventory_check.py      # Esquemas de verificación
│   │   ├── loan.py                 # Esquemas de préstamo
│   │   ├── maintenance_request.py  # Esquemas de mantenimiento
│   │   ├── environment.py          # Esquemas de ambiente
│   │   ├── alert_setting.py        # Esquemas de alertas
│   │   ├── audit_log.py            # Esquemas de auditoría
│   │   └── generated_reports.py    # Esquemas de reportes
│   │
│   ├── routers/                    # Endpoints de la API
│   │   ├── __init__.py
│   │   ├── auth.py                 # Autenticación
│   │   ├── users.py                # Gestión de usuarios
│   │   ├── environments.py         # Ambientes
│   │   ├── inventory.py            # Inventario
│   │   ├── inventory_checks.py     # Verificaciones
│   │   ├── inventory_check_items.py # Items de verificación
│   │   ├── loans.py                # Préstamos
│   │   ├── maintenance_requests.py # Mantenimiento
│   │   ├── maintenance_history.py  # Historial de mantenimiento
│   │   ├── schedules.py            # Horarios
│   │   ├── notifications.py        # Notificaciones
│   │   ├── system_alerts.py        # Alertas
│   │   ├── alert_settings.py       # Configuración de alertas
│   │   ├── supervisor_reviews.py   # Revisiones
│   │   ├── qr.py                   # Códigos QR
│   │   ├── stats.py                # Estadísticas
│   │   ├── reports.py              # Reportes
│   │   ├── audit_logs.py           # Auditoría
│   │   ├── feedback.py             # Feedback
│   │   ├── settings.py             # Configuración
│   │   └── checks.py               # Checks generales
│   │
│   ├── services/                   # Servicios de negocio
│   │   └── auth_service.py         # Lógica de autenticación
│   │
│   └── utils/                      # Utilidades
│       └── security.py             # Funciones de seguridad
│
├── alembic/                        # Migraciones de BD
│   └── versions/
├── alembic.ini                     # Configuración de Alembic
├── Dockerfile                      # Contenedor Docker
└── requirements.txt                # Dependencias Python
\`\`\`

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** 3.0 o superior
- **Dart SDK** 3.0 o superior
- **Python** 3.11 o superior
- **PostgreSQL** 14 o superior
- **Docker** (opcional, para contenedorización)
- **Git** para control de versiones

### 1. Clonar el Repositorio

\`\`\`bash
git clone https://github.com/tu-usuario/gestion-inventario-sena.git
cd gestion-inventario-sena
\`\`\`

### 2. Configuración del Backend

#### 2.1. Crear entorno virtual

\`\`\`bash
cd server
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
\`\`\`

#### 2.2. Instalar dependencias

\`\`\`bash
pip install -r requirements.txt
\`\`\`

#### 2.3. Configurar variables de entorno

Crear archivo `.env` en la carpeta `server/`:

\`\`\`env
# Database
DATABASE_URL=postgresql://usuario:contraseña@localhost:5432/sena_inventory

# Security
SECRET_KEY=tu_clave_secreta_muy_segura_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Server
HOST=0.0.0.0
PORT=8000
\`\`\`

#### 2.4. Crear base de datos

\`\`\`bash
# Conectarse a PostgreSQL
psql -U postgres

# Crear base de datos
CREATE DATABASE sena_inventory;

# Salir
\q
\`\`\`

#### 2.5. Ejecutar migraciones

\`\`\`bash
alembic upgrade head
\`\`\`

#### 2.6. Iniciar servidor

\`\`\`bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
\`\`\`

El servidor estará disponible en: `http://localhost:8000`  
Documentación interactiva: `http://localhost:8000/docs`

### 3. Configuración del Frontend

#### 3.1. Instalar dependencias

\`\`\`bash
cd ..  # Volver a la raíz del proyecto
flutter pub get
\`\`\`

#### 3.2. Configurar URL de la API

Editar `lib/core/constants/api_constants.dart`:

\`\`\`dart
// Para desarrollo local
const String baseUrl = 'http://localhost:8000/api';

// Para producción
// const String baseUrl = 'https://tu-dominio.com/api';
\`\`\`

#### 3.3. Ejecutar la aplicación

\`\`\`bash
# Para Android/iOS
flutter run

# Para Web
flutter run -d chrome

# Para Windows
flutter run -d windows

# Para Linux
flutter run -d linux

# Para macOS
flutter run -d macos
\`\`\`

### 4. Configuración con Docker (Opcional)

#### 4.1. Crear archivo docker-compose.yml

\`\`\`yaml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_USER: sena_user
      POSTGRES_PASSWORD: sena_password
      POSTGRES_DB: sena_inventory
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./server
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://sena_user:sena_password@db:5432/sena_inventory
      SECRET_KEY: tu_clave_secreta
    depends_on:
      - db

volumes:
  postgres_data:
\`\`\`

#### 4.2. Iniciar servicios

\`\`\`bash
docker-compose up -d
\`\`\`

### 5. Datos de Prueba

#### 5.1. Crear usuario administrador

\`\`\`bash
# Desde el directorio server/
python scripts/create_admin.py
\`\`\`

O usar la API directamente:

\`\`\`bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sena.edu.co",
    "password": "Admin123!",
    "first_name": "Administrador",
    "last_name": "General",
    "role": "admin_general"
  }'
\`\`\`

#### 5.2. Usuarios de prueba

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@sena.edu.co | Admin123! | admin_general |
| supervisor@sena.edu.co | Super123! | supervisor |
| instructor@sena.edu.co | Inst123! | instructor |
| estudiante@sena.edu.co | Est123! | student |

---

## 📦 Módulos del Sistema

### 1. 🔐 Módulo de Autenticación

**Funcionalidades:**
- Registro de nuevos usuarios con validación
- Login con email y contraseña
- Generación de tokens JWT
- Refresh de tokens
- Recuperación de contraseña
- Cambio de contraseña
- Gestión de sesiones activas
- Cierre de sesión

**Endpoints:**
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/login` - Inicio de sesión
- `GET /api/auth/me` - Obtener usuario actual
- `PUT /api/auth/me` - Actualizar perfil
- `POST /api/auth/me/change-password` - Cambiar contraseña

### 2. 👥 Módulo de Usuarios

**Funcionalidades:**
- Gestión completa de usuarios (CRUD)
- Asignación de roles
- Vinculación a ambientes
- Activación/desactivación de cuentas
- Búsqueda y filtrado de usuarios
- Historial de actividad

**Endpoints:**
- `GET /api/users` - Listar usuarios
- `GET /api/users/{id}` - Obtener usuario
- `POST /api/users` - Crear usuario
- `PUT /api/users/{id}` - Actualizar usuario
- `DELETE /api/users/{id}` - Eliminar usuario
- `GET /api/users/by-role/{role}` - Usuarios por rol

### 3. 📦 Módulo de Inventario

**Funcionalidades:**
- Gestión de items de inventario
- Categorización de equipos
- Control de cantidades (disponibles, dañados, faltantes)
- Carga de imágenes
- Códigos QR únicos por item
- Historial de cambios
- Alertas de stock bajo
- Búsqueda avanzada

**Endpoints:**
- `GET /api/inventory` - Listar inventario
- `GET /api/inventory/{id}` - Obtener item
- `POST /api/inventory` - Crear item
- `PUT /api/inventory/{id}` - Actualizar item
- `DELETE /api/inventory/{id}` - Eliminar item
- `GET /api/inventory/environment/{id}` - Inventario por ambiente
- `GET /api/inventory/category/{category}` - Inventario por categoría

### 4. ✅ Módulo de Verificaciones

**Funcionalidades:**
- Creación de verificaciones diarias
- Flujo de tres etapas (estudiante → instructor → supervisor)
- Validación de checks obligatorios
- Cálculo automático de totales
- Notificaciones por etapa
- Historial de verificaciones
- Estadísticas de cumplimiento

**Endpoints:**
- `POST /api/inventory-checks` - Crear verificación
- `POST /api/inventory-checks/by-schedule` - Verificación por horario
- `GET /api/inventory-checks` - Listar verificaciones
- `GET /api/inventory-checks/{id}` - Obtener verificación
- `PUT /api/inventory-checks/{id}/confirm` - Confirmar verificación
- `PUT /api/inventory-checks/{id}/supervisor-approve` - Aprobación supervisor
- `GET /api/inventory-checks/schedule-stats` - Estadísticas por horario

### 5. 🔧 Módulo de Mantenimiento

**Funcionalidades:**
- Solicitudes de mantenimiento
- Priorización (baja, media, alta, urgente)
- Categorización (preventivo, correctivo, emergencia)
- Adjuntar imágenes del problema
- Seguimiento de estado
- Historial de mantenimientos
- Costos de mantenimiento
- Notificaciones automáticas

**Endpoints:**
- `GET /api/maintenance-requests` - Listar solicitudes
- `POST /api/maintenance-requests` - Crear solicitud
- `PUT /api/maintenance-requests/{id}` - Actualizar solicitud
- `DELETE /api/maintenance-requests/{id}` - Eliminar solicitud
- `GET /api/maintenance-history` - Historial de mantenimiento
- `POST /api/maintenance-history` - Registrar mantenimiento

### 6. 📤 Módulo de Préstamos

**Funcionalidades:**
- Solicitud de préstamos por instructores
- Préstamos entre ambientes del mismo centro
- Items registrados y personalizados
- Aprobación/rechazo por administradores
- Generación de actas en PDF
- Control de devoluciones
- Alertas de préstamos vencidos
- Estadísticas de préstamos

**Endpoints:**
- `GET /api/loans` - Listar préstamos
- `POST /api/loans` - Crear préstamo
- `GET /api/loans/{id}` - Obtener préstamo
- `PUT /api/loans/{id}` - Actualizar préstamo
- `DELETE /api/loans/{id}` - Eliminar préstamo
- `GET /api/loans/warehouses` - Bodegas disponibles
- `GET /api/loans/stats` - Estadísticas de préstamos

### 7. 🏢 Módulo de Ambientes

**Funcionalidades:**
- Gestión de ambientes de formación
- Organización por centros
- Identificación de bodegas
- Gestión de horarios
- Asignación de instructores
- Códigos QR por ambiente
- Estadísticas por ambiente

**Endpoints:**
- `GET /api/environments` - Listar ambientes
- `GET /api/environments/{id}` - Obtener ambiente
- `POST /api/environments` - Crear ambiente
- `PUT /api/environments/{id}` - Actualizar ambiente
- `DELETE /api/environments/{id}` - Eliminar ambiente
- `GET /api/environments/{id}/inventory` - Inventario del ambiente

### 8. 🔔 Módulo de Notificaciones

**Funcionalidades:**
- Notificaciones en tiempo real
- Categorización por tipo
- Niveles de prioridad
- Marcado de leídas/no leídas
- Historial completo
- Filtrado y búsqueda
- Eliminación masiva

**Endpoints:**
- `GET /api/notifications` - Listar notificaciones
- `GET /api/notifications/{id}` - Obtener notificación
- `PUT /api/notifications/{id}/read` - Marcar como leída
- `PUT /api/notifications/read-all` - Marcar todas como leídas
- `DELETE /api/notifications/{id}` - Eliminar notificación
- `GET /api/notifications/unread-count` - Contador de no leídas

### 9. 📊 Módulo de Estadísticas

**Funcionalidades:**
- Dashboard con métricas en tiempo real
- Estadísticas de inventario
- Estadísticas de verificaciones
- Estadísticas de mantenimiento
- Estadísticas de préstamos
- Tendencias y análisis
- Gráficos interactivos

**Endpoints:**
- `GET /api/stats/dashboard` - Dashboard general
- `GET /api/stats/inventory-checks` - Estadísticas de verificaciones
- `GET /api/stats/environment/{id}` - Estadísticas por ambiente
- `GET /api/stats/trends` - Tendencias temporales
- `GET /api/stats/admin-dashboard` - Dashboard de administrador

### 10. 📄 Módulo de Reportes

**Funcionalidades:**
- Generación de reportes en PDF, Excel y CSV
- Tipos de reportes:
  - Inventario completo
  - Préstamos activos
  - Mantenimiento
  - Auditoría
  - Verificaciones
- Filtros personalizables
- Descarga de reportes
- Historial de reportes generados

**Endpoints:**
- `POST /api/reports/generate` - Generar reporte
- `GET /api/reports` - Listar reportes
- `GET /api/reports/{id}` - Obtener reporte
- `GET /api/reports/{id}/download` - Descargar reporte
- `DELETE /api/reports/{id}` - Eliminar reporte
- `GET /api/reports/stats/summary` - Resumen de reportes

### 11. 🔍 Módulo de Auditoría

**Funcionalidades:**
- Registro automático de todas las acciones
- Captura de usuario, rol, IP y timestamp
- Detalles de peticiones y respuestas
- Búsqueda y filtrado avanzado
- Exportación de logs
- Análisis de actividad

**Endpoints:**
- `GET /api/audit-logs` - Listar logs
- `GET /api/audit-logs/{id}` - Obtener log
- `GET /api/audit-logs/user/{id}` - Logs por usuario
- `GET /api/audit-logs/entity/{type}` - Logs por entidad
- `GET /api/audit-logs/export` - Exportar logs

### 12. 📱 Módulo de Códigos QR

**Funcionalidades:**
- Generación de códigos QR
- Escaneo de códigos QR
- Vinculación de estudiantes a ambientes
- Identificación rápida de equipos
- Información detallada al escanear

**Endpoints:**
- `GET /api/qr/generate` - Generar código QR
- `POST /api/qr/scan` - Procesar escaneo
- `GET /api/qr/environment/{id}` - QR de ambiente
- `GET /api/qr/item/{id}` - QR de item

---

## 🔌 API Endpoints

### Resumen de Endpoints por Módulo

| Módulo | Endpoints | Métodos |
|--------|-----------|---------|
| Autenticación | 5 | POST, GET, PUT |
| Usuarios | 6 | GET, POST, PUT, DELETE |
| Inventario | 7 | GET, POST, PUT, DELETE |
| Verificaciones | 7 | GET, POST, PUT |
| Mantenimiento | 6 | GET, POST, PUT, DELETE |
| Préstamos | 6 | GET, POST, PUT, DELETE |
| Ambientes | 6 | GET, POST, PUT, DELETE |
| Notificaciones | 6 | GET, PUT, DELETE |
| Estadísticas | 5 | GET |
| Reportes | 6 | GET, POST, DELETE |
| Auditoría | 5 | GET |
| Códigos QR | 4 | GET, POST |
| **TOTAL** | **69** | - |

### Documentación Interactiva

El backend de FastAPI incluye documentación interactiva automática:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Autenticación de Endpoints

La mayoría de los endpoints requieren autenticación mediante JWT:

\`\`\`bash
# Ejemplo de petición autenticada
curl -X GET "http://localhost:8000/api/inventory" \
  -H "Authorization: Bearer tu_token_jwt_aqui"
\`\`\`

### Códigos de Respuesta HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK - Petición exitosa |
| 201 | Created - Recurso creado |
| 204 | No Content - Eliminación exitosa |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - No autenticado |
| 403 | Forbidden - Sin permisos |
| 404 | Not Found - Recurso no encontrado |
| 422 | Unprocessable Entity - Validación fallida |
| 500 | Internal Server Error - Error del servidor |

---

## 💾 Modelos de Datos

### Diagrama de Relaciones (Simplificado)

\`\`\`
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   Centers   │──────<│ Environments │>──────│    Users    │
└─────────────┘       └──────────────┘       └─────────────┘
                             │                       │
                             │                       │
                             ↓                       ↓
                      ┌──────────────┐       ┌─────────────┐
                      │ Inventory    │       │  Schedules  │
                      │   Items      │       └─────────────┘
                      └──────────────┘              │
                             │                      │
                             ↓                      ↓
                      ┌──────────────┐       ┌─────────────┐
                      │   Loans      │       │  Inventory  │
                      └──────────────┘       │   Checks    │
                             │               └─────────────┘
                             ↓                      │
                      ┌──────────────┐              ↓
                      │ Maintenance  │       ┌─────────────┐
                      │  Requests    │       │ Supervisor  │
                      └──────────────┘       │  Reviews    │
                             │               └─────────────┘
                             ↓
                      ┌──────────────┐
                      │ Maintenance  │
                      │   History    │
                      └──────────────┘
\`\`\`

### Tablas Principales

#### 1. **users** - Usuarios del Sistema

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| email | String | Correo electrónico (único) |
| password_hash | String | Contraseña hasheada |
| role | String | Rol del usuario |
| first_name | String | Nombre |
| last_name | String | Apellido |
| phone | String | Teléfono |
| program | String | Programa de formación |
| ficha | String | Número de ficha |
| environment_id | UUID | Ambiente asignado |
| avatar_url | String | URL del avatar |
| is_active | Boolean | Usuario activo |
| last_login | Timestamp | Último acceso |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

**Roles posibles:** `student`, `instructor`, `supervisor`, `admin`, `admin_general`

#### 2. **environments** - Ambientes de Formación

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| center_id | UUID | Centro de formación |
| name | String | Nombre del ambiente |
| location | String | Ubicación física |
| description | Text | Descripción |
| capacity | Integer | Capacidad de personas |
| is_warehouse | Boolean | Es bodega/almacén |
| is_active | Boolean | Ambiente activo |
| qr_code | String | Código QR único |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

#### 3. **inventory_items** - Items de Inventario

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| environment_id | UUID | Ambiente al que pertenece |
| name | String | Nombre del equipo |
| serial_number | String | Número de serie |
| internal_code | String | Código interno (único) |
| category | String | Categoría del equipo |
| brand | String | Marca |
| model | String | Modelo |
| status | String | Estado actual |
| purchase_date | Date | Fecha de compra |
| warranty_expiry | Date | Vencimiento de garantía |
| last_maintenance | Date | Último mantenimiento |
| next_maintenance | Date | Próximo mantenimiento |
| image_url | String | URL de la imagen |
| notes | Text | Notas adicionales |
| quantity | Integer | Cantidad total |
| quantity_damaged | Integer | Cantidad dañada |
| quantity_missing | Integer | Cantidad faltante |
| item_type | String | Tipo: individual/group |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

**Categorías:** `computer`, `projector`, `keyboard`, `mouse`, `tv`, `camera`, `microphone`, `tablet`, `other`

**Estados:** `available`, `in_use`, `maintenance`, `damaged`, `lost`, `missing`, `good`

#### 4. **inventory_checks** - Verificaciones de Inventario

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| environment_id | UUID | Ambiente verificado |
| student_id | UUID | Estudiante que verifica |
| instructor_id | UUID | Instructor que revisa |
| supervisor_id | UUID | Supervisor que aprueba |
| schedule_id | UUID | Horario asociado |
| check_date | Date | Fecha de verificación |
| check_time | Time | Hora de verificación |
| status | String | Estado actual |
| total_items | Integer | Total de items |
| items_good | Integer | Items en buen estado |
| items_damaged | Integer | Items dañados |
| items_missing | Integer | Items faltantes |
| is_clean | Boolean | Aula limpia |
| is_organized | Boolean | Aula organizada |
| inventory_complete | Boolean | Inventario completo |
| cleaning_notes | Text | Notas de limpieza |
| comments | Text | Comentarios del estudiante |
| instructor_comments | Text | Comentarios del instructor |
| supervisor_comments | Text | Comentarios del supervisor |
| student_confirmed_at | Timestamp | Confirmación estudiante |
| instructor_confirmed_at | Timestamp | Confirmación instructor |
| supervisor_confirmed_at | Timestamp | Confirmación supervisor |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

**Estados:** `student_pending`, `instructor_review`, `supervisor_review`, `complete`, `issues`, `rejected`

#### 5. **loans** - Préstamos de Equipos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| instructor_id | UUID | Instructor solicitante |
| item_id | UUID | Item prestado (opcional) |
| admin_id | UUID | Admin que aprueba |
| environment_id | UUID | Bodega de origen |
| program | String | Programa que solicita |
| purpose | Text | Propósito del préstamo |
| start_date | Date | Fecha de inicio |
| end_date | Date | Fecha de fin |
| actual_return_date | Date | Fecha real de devolución |
| status | String | Estado del préstamo |
| rejection_reason | Text | Razón de rechazo |
| item_name | String | Nombre del item |
| item_description | Text | Descripción del item |
| is_registered_item | Boolean | Es item registrado |
| quantity_requested | Integer | Cantidad solicitada |
| priority | String | Prioridad |
| acta_pdf_path | String | Ruta del acta PDF |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

**Estados:** `pending`, `approved`, `active`, `returned`, `overdue`, `rejected`

**Prioridades:** `low`, `medium`, `high`, `urgent`

#### 6. **maintenance_requests** - Solicitudes de Mantenimiento

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| item_id | UUID | Item a mantener (opcional) |
| environment_id | UUID | Ambiente |
| user_id | UUID | Usuario solicitante |
| title | String | Título de la solicitud |
| description | Text | Descripción del problema |
| priority | String | Prioridad |
| category | String | Categoría |
| status | String | Estado |
| location | String | Ubicación específica |
| images_urls | JSON | URLs de imágenes |
| quantity_affected | Integer | Cantidad afectada |
| cost | Decimal | Costo del mantenimiento |
| scheduled_date | Date | Fecha programada |
| completed_date | Date | Fecha de completado |
| assigned_to | UUID | Técnico asignado |
| created_at | Timestamp | Fecha de creación |
| updated_at | Timestamp | Última actualización |

**Prioridades:** `low`, `medium`, `high`, `urgent`

**Categorías:** `preventive`, `corrective`, `emergency`

**Estados:** `pending`, `in_progress`, `completed`, `cancelled`, `on_hold`

#### 7. **notifications** - Notificaciones

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| user_id | UUID | Usuario destinatario |
| type | String | Tipo de notificación |
| title | String | Título |
| message | Text | Mensaje |
| is_read | Boolean | Leída |
| priority | String | Prioridad |
| related_entity_id | UUID | Entidad relacionada |
| related_entity_type | String | Tipo de entidad |
| action_url | String | URL de acción |
| created_at | Timestamp | Fecha de creación |

**Tipos:** `verification_pending`, `verification_update`, `maintenance_update`, `loan_approved`, `loan_rejected`, `loan_overdue`, `system`

**Prioridades:** `low`, `medium`, `high`

#### 8. **audit_logs** - Logs de Auditoría

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| user_id | UUID | Usuario que realizó la acción |
| action | String | Acción realizada |
| entity_type | String | Tipo de entidad |
| entity_id | UUID | ID de la entidad |
| old_values | JSON | Valores anteriores |
| new_values | JSON | Valores nuevos |
| ip_address | String | Dirección IP |
| user_agent | String | Navegador/cliente |
| created_at | Timestamp | Fecha de la acción |

---

## 📸 Capturas de Pantalla

### Dashboard de Estudiante
![Student Dashboard](public/placeholder.jpg)
*Vista principal del estudiante con resumen de inventario y acciones disponibles*

### Verificación de Inventario
![Inventory Check](public/placeholder.jpg)
*Pantalla de verificación diaria con lista de equipos*

### Dashboard de Instructor
![Instructor Dashboard](public/placeholder.jpg)
*Panel de control del instructor con verificaciones pendientes*

### Dashboard de Supervisor
![Supervisor Dashboard](public/placeholder.jpg)
*Vista del supervisor con estadísticas y aprobaciones*

### Gestión de Préstamos
![Loan Management](public/placeholder.jpg)
*Sistema de gestión de préstamos con filtros y estados*

### Solicitud de Mantenimiento
![Maintenance Request](public/placeholder.jpg)
*Formulario de solicitud de mantenimiento con adjuntos*

### Generación de Reportes
![Report Generator](public/placeholder.jpg)
*Interfaz de generación de reportes con múltiples formatos*

### Dashboard de Administrador General
![Admin Dashboard](public/placeholder.jpg)
*Vista completa del sistema con métricas globales*

---

## 🤝 Contribución

### Cómo Contribuir

1. **Fork** el repositorio
2. Crea una **rama** para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. Abre un **Pull Request**

### Guías de Estilo

**Flutter/Dart:**
- Seguir las [Effective Dart Guidelines](https://dart.dev/guides/language/effective-dart)
- Usar `flutter format` antes de commit
- Documentar funciones públicas

**Python/FastAPI:**
- Seguir [PEP 8](https://pep8.org/)
- Usar type hints
- Documentar endpoints con docstrings

### Reportar Bugs

Si encuentras un bug, por favor crea un issue con:
- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Screenshots si aplica
- Versión del sistema

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

\`\`\`
MIT License

Copyright (c) 2024 Duvan Yair Arciniegas Gerena

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
\`\`\`

---

## 📞 Contacto

**Duvan Yair Arciniegas Gerena**  
Tecnólogo en Análisis y Desarrollo de Software  
SENA - Servicio Nacional de Aprendizaje

- 📧 Email: duvan.arciniegas@sena.edu.co
- 💼 LinkedIn: [linkedin.com/in/duvan-arciniegas](https://linkedin.com/in/duvan-arciniegas)
- 🐙 GitHub: [github.com/duvan-arciniegas](https://github.com/duvan-arciniegas)

---

## 🙏 Agradecimientos

- **SENA** - Por la formación y el apoyo en el desarrollo de este proyecto
- **Instructores** - Por la guía y retroalimentación constante
- **Comunidad Flutter** - Por las herramientas y recursos
- **Comunidad FastAPI** - Por el excelente framework
- **Compañeros de formación** - Por las pruebas y sugerencias

---

## 🔮 Roadmap

### Versión 2.0 (Planificado)

- [ ] 📱 Notificaciones push en tiempo real
- [ ] 🌐 Soporte completo multiidioma (Español/Inglés)
- [ ] 📊 Dashboard con gráficos interactivos avanzados
- [ ] 🤖 Predicción de mantenimiento con ML
- [ ] 📷 Reconocimiento de equipos por imagen
- [ ] 🔗 Integración con sistemas externos del SENA
- [ ] 📱 App móvil nativa optimizada
- [ ] 🎨 Temas personalizables por centro
- [ ] 📧 Sistema de correos automáticos
- [ ] 🔐 Autenticación biométrica
- [ ] 📱 Modo offline con sincronización
- [ ] 🗺️ Mapas interactivos de ambientes

### Versión 3.0 (Futuro)

- [ ] 🤖 Chatbot de asistencia con IA
- [ ] 📊 Business Intelligence integrado
- [ ] 🔗 API pública para integraciones
- [ ] 📱 Widget para escritorio
- [ ] 🌍 Soporte multi-centro avanzado
- [ ] 📈 Análisis predictivo de inventario
- [ ] 🎓 Sistema de capacitación integrado

---

<div align="center">

**Desarrollado con ❤️ por Duvan Yair Arciniegas Gerena**

**SENA - Servicio Nacional de Aprendizaje**

<img width="649" height="628" alt="sena_logo" src="https://github.com/user-attachments/assets/5f69ea47-ea22-4834-a019-2590d959783e" />


---

⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub

</div>
