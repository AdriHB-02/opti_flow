-- Run this in Supabase Dashboard → SQL Editor
-- Creates the doctores table matching the local schema

CREATE TABLE IF NOT EXISTS public.doctores (
  id TEXT PRIMARY KEY NOT NULL,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL CHECK(rol IN ('ADMIN', 'JEFE', 'USER')),
  dependencia_local_id TEXT,
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

ALTER TABLE public.doctores ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read their own record
CREATE POLICY "Users can read own record"
  ON public.doctores
  FOR SELECT
  USING (auth.uid() = id);

-- Allow service role to insert
CREATE POLICY "Service role can insert"
  ON public.doctores
  FOR INSERT
  WITH CHECK (true);
