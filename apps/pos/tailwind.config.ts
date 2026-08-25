import type { Config } from 'tailwindcss';
import preset from '@platform/ui/tailwind-preset';

const config: Config = {
  darkMode: ['class'],
  presets: [preset],
  content: ['./src/**/*.{ts,tsx}', '../../packages/ui/src/**/*.{ts,tsx}'],
};

export default config;
