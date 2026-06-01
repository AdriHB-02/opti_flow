# OptiFlow App

Aplicación móvil Flutter para digitalizar y gestionar campañas de salud visual.

## Requisitos

- Flutter SDK >=3.10.7
- Dispositivo/emulador Android (API 26+) o iOS (12+)

## Instalación y ejecución

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd opti_flow

# 2. Crear archivo de entorno (completar con tus claves)
cp .env.template .env

# 3. Instalar dependencias
flutter pub get

# 4. Ejecutar en modo desarrollo
flutter run

# 5. (Opcional) Build de producción Android
flutter build apk --release

# 6. (Opcional) Build de producción iOS
flutter build ios --release
```

## Comandos útiles

| Comando | Descripción |
|---------|-------------|
| `flutter run` | Ejecutar en modo desarrollo |
| `flutter test` | Ejecutar tests unitarios |
| `flutter analyze` | Análisis estático de código |
| `flutter pub get` | Instalar/actualizar dependencias |
| `flutter clean` | Limpiar builds anteriores |

## Variables de entorno

Configurar en `.env` (ver `.env.template`):

| Variable | Descripción |
|----------|-------------|
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Anon key pública de Supabase |
| `AWS_BUCKET` | Nombre del bucket S3 para imágenes |
| `MAPS_API_KEY` | API Key de Google Maps |
