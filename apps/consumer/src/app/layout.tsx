import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Consumer',
  description: 'Consumer channel — platform environment setup verification.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
