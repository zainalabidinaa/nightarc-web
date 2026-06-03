export const config = { runtime: 'edge' };

export default async function handler(req: Request) {
  const url = new URL(req.url).searchParams.get('url');
  if (!url) return new Response('Missing url param', { status: 400 });

  const res = await fetch(url);
  if (!res.ok) return new Response('Upstream error', { status: res.status });

  const data = await res.text();
  return new Response(data, {
    headers: {
      'Content-Type': 'text/vtt; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'public, s-maxage=3600',
    },
  });
}
