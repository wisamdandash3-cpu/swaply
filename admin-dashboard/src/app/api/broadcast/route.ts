import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const admin = createAdminClient();
    const { data, error } = await admin
      .from('broadcast_messages')
      .select('id, content, image_url, video_url, created_at')
      .order('created_at', { ascending: false });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ messages: data ?? [] });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const contentType = request.headers.get('content-type') || '';
    let content = '';
    let imageUrl: string | null = null;
    let videoUrl: string | null = null;

    if (contentType.includes('multipart/form-data')) {
      const formData = await request.formData();
      content = (formData.get('content') as string)?.trim() ?? '';
      const imageFile = formData.get('image') as File | null;
      const videoFile = formData.get('video') as File | null;
      const admin = createAdminClient();
      const bucket = 'broadcast-media';
      if (imageFile && imageFile.size > 0) {
        const ext = imageFile.name.split('.').pop() || 'jpg';
        const path = `broadcast/${Date.now()}_image.${ext}`;
        const buf = await imageFile.arrayBuffer();
        const { error: upErr } = await admin.storage.from(bucket).upload(path, buf, {
          contentType: imageFile.type,
          upsert: true,
        });
        if (!upErr) {
          const { data: urlData } = admin.storage.from(bucket).getPublicUrl(path);
          imageUrl = urlData.publicUrl;
        }
      }
      if (videoFile && videoFile.size > 0) {
        const ext = videoFile.name.split('.').pop() || 'mp4';
        const path = `broadcast/${Date.now()}_video.${ext}`;
        const buf = await videoFile.arrayBuffer();
        const { error: upErr } = await admin.storage.from(bucket).upload(path, buf, {
          contentType: videoFile.type,
          upsert: true,
        });
        if (!upErr) {
          const { data: urlData } = admin.storage.from(bucket).getPublicUrl(path);
          videoUrl = urlData.publicUrl;
        }
      }
      if (!content && !imageUrl && !videoUrl) {
        return NextResponse.json({ error: 'المحتوى أو صورة أو فيديو مطلوب' }, { status: 400 });
      }
      const { data, error } = await admin
        .from('broadcast_messages')
        .insert({ content: content || ' ', image_url: imageUrl, video_url: videoUrl })
        .select('id, created_at')
        .single();
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
      return NextResponse.json({ ok: true, id: data?.id, created_at: data?.created_at });
    }

    const body = await request.json();
    content = typeof body.content === 'string' ? body.content.trim() : '';
    if (!content) {
      return NextResponse.json({ error: 'المحتوى مطلوب' }, { status: 400 });
    }
    const admin = createAdminClient();
    const { data, error } = await admin
      .from('broadcast_messages')
      .insert({ content })
      .select('id, created_at')
      .single();
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true, id: data?.id, created_at: data?.created_at });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
