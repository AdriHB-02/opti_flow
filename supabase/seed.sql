-- ============================================================
-- OptiFlow — Esquema PostgreSQL + Seed para Supabase (case‑safe)
-- ============================================================

-- ── 1. CREAR TABLAS (idempotente) ──

CREATE TABLE IF NOT EXISTS doctores (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL DEFAULT '',
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

-- ── 3. RLS POLICIES ──

-- doctores: cada usuario solo ve/edita su propio registro
ALTER TABLE doctores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "doctores_select_own" ON doctores;
CREATE POLICY "doctores_select_own"
  ON doctores FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "doctores_update_own" ON doctores;
CREATE POLICY "doctores_update_own"
  ON doctores FOR UPDATE
  USING (auth.uid() = id);

-- empresas: admins pueden ver todas; jefes y users solo activas
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "empresas_select_all" ON empresas;
CREATE POLICY "empresas_select_all"
  ON empresas FOR SELECT
  USING (true);

-- campanas: el creador y los doctores asignados pueden ver
ALTER TABLE campanas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "campanas_select_related" ON campanas;
CREATE POLICY "campanas_select_related"
  ON campanas FOR SELECT
  USING (
    auth.uid() = creado_por
    OR auth.uid() IN (
      SELECT doctor_id FROM doctor_campana WHERE campana_id = id
    )
  );

DROP POLICY IF EXISTS "campanas_insert_admin_jefe" ON campanas;
CREATE POLICY "campanas_insert_admin_jefe"
  ON campanas FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM doctores
      WHERE id = auth.uid() AND rol IN ('ADMIN', 'JEFE')
    )
  );

-- doctor_campana: admins y jefes asignan
ALTER TABLE doctor_campana ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "doctor_campana_select_related" ON doctor_campana;
CREATE POLICY "doctor_campana_select_related"
  ON doctor_campana FOR SELECT
  USING (doctor_id = auth.uid());

DROP POLICY IF EXISTS "doctor_campana_insert_admin_jefe" ON doctor_campana;
CREATE POLICY "doctor_campana_insert_admin_jefe"
  ON doctor_campana FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM doctores
      WHERE id = auth.uid() AND rol IN ('ADMIN', 'JEFE')
    )
  );

-- dependencias: visibles por usuarios del contexto
ALTER TABLE dependencias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dependencias_select_related" ON dependencias;
CREATE POLICY "dependencias_select_related"
  ON dependencias FOR SELECT
  USING (true);

-- pacientes: el doctor que los registró o doctores de su dependencia
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pacientes_select_own" ON pacientes;
CREATE POLICY "pacientes_select_own"
  ON pacientes FOR SELECT
  USING (doctor_id = auth.uid());

DROP POLICY IF EXISTS "pacientes_insert_own" ON pacientes;
CREATE POLICY "pacientes_insert_own"
  ON pacientes FOR INSERT
  WITH CHECK (doctor_id = auth.uid());

-- historias_clinicas: el doctor que atendió o doctores asignados a la campaña
ALTER TABLE historias_clinicas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "historias_clinicas_select_related" ON historias_clinicas;
CREATE POLICY "historias_clinicas_select_related"
  ON historias_clinicas FOR SELECT
  USING (doctor_id = auth.uid());

DROP POLICY IF EXISTS "historias_clinicas_insert_own" ON historias_clinicas;
CREATE POLICY "historias_clinicas_insert_own"
  ON historias_clinicas FOR INSERT
  WITH CHECK (doctor_id = auth.uid());

-- sync_log: cada usuario ve sus propios logs
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sync_log_select_own" ON sync_log;
CREATE POLICY "sync_log_select_own"
  ON sync_log FOR SELECT
  USING (true);

-- pagos: el doctor dueño del pago
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pagos_select_own" ON pagos;
CREATE POLICY "pagos_select_own"
  ON pagos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM doctores
      WHERE id = auth.uid() AND rol IN ('ADMIN', 'JEFE')
    )
    OR doctor_id = auth.uid()
  );

-- ── 4. Seed ejecutado via Edge Function (supabase/functions/seed) ──
-- Ejecutar en producción:
--   supabase functions deploy seed --no-verify-jwt
--   curl -X POST https://<project>.supabase.co/functions/v1/seed
