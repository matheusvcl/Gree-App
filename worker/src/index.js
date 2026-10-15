// Gree Family — registro mínimo da família (membros, locais, aparelhos)
// KV: GREE_FAMILY. O código da família é a chave e o segredo (uso pessoal).
export default {
  async fetch(req, env) {
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    };
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

    const url = new URL(req.url);
    const m = url.pathname.match(/^\/family\/([A-Za-z0-9]{6})$/);
    if (!m) return new Response('{"error":"not found"}', { status: 404, headers: { ...cors, 'content-type': 'application/json' } });

    const key = 'family:' + m[1].toUpperCase();

    if (req.method === 'GET') {
      const v = await env.GREE_FAMILY.get(key);
      return new Response(v ?? '{}', {
        status: v ? 200 : 404,
        headers: { ...cors, 'content-type': 'application/json' },
      });
    }

    if (req.method === 'POST') {
      const body = await req.text();
      if (body.length > 200000) return new Response('{"error":"too big"}', { status: 413, headers: { ...cors, 'content-type': 'application/json' } });
      await env.GREE_FAMILY.put(key, body);
      return new Response('{"ok":true}', { headers: { ...cors, 'content-type': 'application/json' } });
    }

    return new Response('{"error":"method"}', { status: 405, headers: { ...cors, 'content-type': 'application/json' } });
  },
};
