// Deno/TypeScript Edge Function
// Quick-start: tạo challenge_id giả lập và trả về 200 + CORS

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*', // đổi thành origin app của bạn khi lên PROD
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }})
    }

    const body = await req.json()
    const { sender_wallet_id, recipient_wallet_id, amount, notes } = body ?? {}

    if (!sender_wallet_id || !recipient_wallet_id || !amount) {
      return new Response(JSON.stringify({ error: 'invalid_payload' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }})
    }

    // DEV: Tạo challenge_id đơn giản
    const challenge_id = crypto.randomUUID()

    // TODO (Pha B): Lưu challenge vào table transfer_challenges và gửi OTP email

    return new Response(JSON.stringify({ challenge_id }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})