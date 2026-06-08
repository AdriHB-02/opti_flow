import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get("SUPABASE_URL")!
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

Deno.serve(async (_req: Request) => {
  try {
    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    const now = new Date().toISOString()

    const seedDoctors = [
      { nombre: "Admin OptiFlow", email: "admin@optiflow.com", password: "Admin123!", rol: "ADMIN" },
      { nombre: "Dr. Jefe", email: "jefe@optiflow.com", password: "Jefe123!", rol: "JEFE" },
      { nombre: "Dr. Usuario", email: "doctor@optiflow.com", password: "Doctor123!", rol: "USER" },
    ]

    const results: string[] = []

    for (const doc of seedDoctors) {
      const existing = await adminClient
        .from("doctores")
        .select("id")
        .eq("email", doc.email)
        .maybeSingle()

      if (existing) {
        results.push(`Ya existe: ${doc.email}`)
        continue
      }

      const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
        email: doc.email,
        password: doc.password,
        email_confirm: true,
      })

      if (authError) {
        results.push(`Error creando auth user ${doc.email}: ${authError.message}`)
        continue
      }

      const userId = authData.user.id

      const { error: insertError } = await adminClient.from("doctores").insert({
        id: userId,
        nombre: doc.nombre,
        email: doc.email,
        rol: doc.rol,
        activo: 1,
        created_at: now,
        updated_at: now,
      })

      if (insertError) {
        results.push(`Error insertando ${doc.email}: ${insertError.message}`)
        continue
      }

      results.push(`✅ Creado: ${doc.email} (${doc.rol})`)
    }

    return new Response(JSON.stringify({ ok: true, results }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
