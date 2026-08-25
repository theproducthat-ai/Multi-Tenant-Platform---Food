import { Controller, Get } from '@nestjs/common';
import { healthCheckSchema, type HealthCheck } from '@platform/schemas';

@Controller('health')
export class HealthController {
  @Get()
  check(): HealthCheck {
    return healthCheckSchema.parse({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  }
}
