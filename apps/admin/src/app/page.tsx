import { Button } from '@platform/ui';

export default function Page() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4">
      <h1 className="text-2xl font-semibold">Admin — environment ready</h1>
      <Button>shadcn/ui is wired up</Button>
    </main>
  );
}
