import type { Metadata } from 'next';
import '@platform/ui/theme.css';
import './globals.css';

export const metadata: Metadata = {
  title: 'Admin',
  description: 'Admin channel — platform environment setup verification.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
