// Deno-friendly импорты
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

serve(async (req) => {
  try {
    // Параметры из тела запроса (опц.)
    const { master_id, days = 14 } = await req.json().catch(() => ({}));

    // Секреты из настроек функции
    const url = Deno.env.get("SUPABASE_URL")!;
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Клиент c service role
    const supa = createClient(url, key, { auth: { persistSession: false } });

    // 1) Шаблоны смен мастера
    const { data: templates, error: tErr } = await supa
      .from("shifts_templates")
      .select("dow, start_time, end_time")
      .eq("master_id", master_id);

    if (tErr) throw tErr;

    // 2) Исключения/выходные за горизонт
    const { data: exceptions, error: eErr } = await supa
      .from("shifts_exceptions")
      .select("date, is_day_off, start_time, end_time")
      .eq("master_id", master_id);

    if (eErr) throw eErr;

    // TODO: здесь генерируешь слоты из templates+exceptions на ближайшие days
    // Возвращаем заглушку, чтобы убедиться что деплой/вызов ок
    return new Response(
      JSON.stringify({ ok: true, got: { templates, exceptions, days } }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});