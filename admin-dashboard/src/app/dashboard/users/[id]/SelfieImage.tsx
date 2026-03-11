'use client';

export default function SelfieImage({ src }: { src: string }) {
  return (
    <div className="mt-4">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt="Selfie"
        className="max-h-48 rounded-lg border border-slate-200 object-cover"
        onError={(e) => {
          (e.target as HTMLImageElement).style.display = 'none';
        }}
      />
    </div>
  );
}
