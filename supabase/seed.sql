-- ============================================================
-- OptiFlow — Esquema PostgreSQL + Seed para Supabase (case‑safe)
-- ============================================================

-- ── 1. CREAR TABLAS (idempotente) ──

CREATE TABLE IF NOT EXISTS doctores (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('ADMIN', 'JEFE', 'USER')),
  dependencia_local_id UUID,
  activo SMALLINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS empresas (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  lugar TEXT NOT NULL,
  activa SMALLINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS campanas (
  id UUID PRIMARY KEY,
  empresa_id UUID NOT NULL REFERENCES empresas(id),
  nombre_empresa TEXT NOT NULL,
  lugar TEXT NOT NULL,
  fecha_inicio TIMESTAMPTZ NOT NULL,
  fecha_fin TIMESTAMPTZ NOT NULL,
  creado_por UUID NOT NULL REFERENCES doctores(id),
  estado TEXT NOT NULL CHECK (estado IN ('ACTIVA', 'FINALIZADA')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctor_campana (
  id UUID PRIMARY KEY,
  doctor_id UUID NOT NULL REFERENCES doctores(id),
  campana_id UUID NOT NULL REFERENCES campanas(id),
  asignado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dependencias (
  id UUID PRIMARY KEY,
  tipo TEXT NOT NULL CHECK (tipo IN ('LOCAL', 'EMPRESA')),
  campana_id UUID REFERENCES campanas(id),
  doctor_id UUID REFERENCES doctores(id),
  nombre TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS pacientes (
  id UUID PRIMARY KEY,
  nombre_completo TEXT NOT NULL,
  dependencia_id UUID NOT NULL REFERENCES dependencias(id),
  doctor_id UUID NOT NULL REFERENCES doctores(id),
  es_reconsulta SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS historias_clinicas (
  id UUID PRIMARY KEY,
  paciente_id UUID NOT NULL REFERENCES pacientes(id),
  campana_id UUID REFERENCES campanas(id),
  diagnostico_texto TEXT,
  imagen_url TEXT,
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  fecha_atencion TIMESTAMPTZ NOT NULL,
  doctor_id UUID NOT NULL REFERENCES doctores(id),
  historia_anterior_id UUID REFERENCES historias_clinicas(id),
  sincronizado SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sync_log (
  id UUID PRIMARY KEY,
  tabla_afectada TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  operacion TEXT NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
  fecha_local TIMESTAMPTZ NOT NULL,
  sincronizado SMALLINT NOT NULL DEFAULT 0,
  fecha_sync TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS pagos (
  id UUID PRIMARY KEY,
  doctor_id UUID NOT NULL REFERENCES doctores(id),
  proveedor TEXT NOT NULL CHECK (proveedor IN ('STRIPE', 'MERCADOPAGO')),
  referencia_pago TEXT NOT NULL,
  monto DOUBLE PRECISION NOT NULL,
  estado TEXT NOT NULL CHECK (estado IN ('PENDIENTE', 'COMPLETADO', 'FALLIDO')),
  fecha_pago TIMESTAMPTZ NOT NULL
);

-- ── 2. ÍNDICES ──

CREATE INDEX IF NOT EXISTS idx_pacientes_dependencia_id
  ON pacientes (dependencia_id);

CREATE INDEX IF NOT EXISTS idx_historias_clinicas_paciente_id
  ON historias_clinicas (paciente_id);

CREATE INDEX IF NOT EXISTS idx_sync_log_sincronizado
  ON sync_log (sincronizado);

-- ── 3. RLS POLICIES (case‑safe, with DROP IF EXISTS) ──

ALTER TABLE doctores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "doctores_select_own" ON doctores;
CREATE POLICY "doctores_select_own"
  ON doctores FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "doctores_update_own" ON doctores;
CREATE POLICY "doctores_update_own"
  ON doctores FOR UPDATE
  USING (auth.uid() = id);

-- ── 4. (Optional) Seed doctores after creating auth.users ──
-- INSERT INTO doctores (id, nombre, email, password_hash, rol, created_at, updated_at)
-- VALUES
--   ('uuid-from-auth-users-1', 'Admin', 'admin@optiflow.com', 'hashed_password', 'ADMIN', NOW(), NOW())
-- ON CONFLICT (email) DO NOTHING;