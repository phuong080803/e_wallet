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
    const { challenge_id, otp } = body ?? {}

    if (!challenge_id || !otp) {
      return new Response(JSON.stringify({ error: 'invalid_payload' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }})
    }

    // DEV: Chấp nhận mọi OTP để test end-to-end
    // TODO (Pha B): verify OTP + challenge từ DB

    // Ở client bạn đã gọi transferMoney() sau confirm.
    // Nếu muốn function tự thực thi RPC luôn, bạn cần truyền kèm payload (sender_wallet_id, recipient_wallet_id, amount, notes)
    // hoặc lấy lại từ challenge DB (Pha B).
    // Quick-start: chỉ trả 200 OK để client tiếp tục gọi RPC qua WalletController.

    return new Response(JSON.stringify({ ok: true }), {
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