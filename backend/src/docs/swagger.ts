export const swaggerDocument = {
  openapi: '3.0.3',
  info: {
    title: 'FinishX API',
    version: '1.0.0',
    description:
      'Production REST API for FinishX — A Commitment & Accountability Platform.\n\nPhilosophy: **One Journey. Full Focus.** Finish Anything.',
    contact: {
      name: 'FinishX Engineering',
      email: 'engineering@finishx.app',
    },
  },
  servers: [
    {
      url: 'https://finishx-api.onrender.com/api/v1',
      description: 'Production Render Service',
    },
    {
      url: 'http://localhost:10000/api/v1',
      description: 'Local Development Server',
    },
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter your Bearer access token issued by /auth/login or /auth/register',
      },
    },
    schemas: {
      StandardResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: true },
          message: { type: 'string', example: 'Operation completed successfully' },
          data: { type: 'object' },
        },
      },
      ErrorResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          error: {
            type: 'object',
            properties: {
              code: { type: 'string', example: 'VALIDATION_ERROR' },
              message: { type: 'string', example: 'Invalid request data' },
              details: { type: 'object' },
            },
          },
        },
      },
      RegisterRequest: {
        type: 'object',
        required: ['email', 'password', 'fullName'],
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', minLength: 8, example: 'SuperSecureP@ss1' },
          fullName: { type: 'string', example: 'Riley Adams' },
          timezone: { type: 'string', example: 'America/New_York' },
        },
      },
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', example: 'SuperSecureP@ss1' },
        },
      },
      RefreshTokenRequest: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string', example: 'eyJhbGciOi...' },
        },
      },
      CreateJourneyRequest: {
        type: 'object',
        required: ['title', 'category', 'startDate', 'targetDate'],
        properties: {
          title: { type: 'string', example: 'Become a Data Scientist' },
          description: { type: 'string', example: 'Complete IBM Data Science Professional Certificate' },
          category: {
            type: 'string',
            enum: ['LEARNING_SKILL', 'CAREER_EXAM', 'HEALTH_FITNESS', 'CREATIVE_WRITING', 'BUSINESS_STARTUP', 'OTHER'],
            example: 'LEARNING_SKILL',
          },
          resourceTitle: { type: 'string', example: 'Coursera - IBM DS' },
          resourceType: {
            type: 'string',
            enum: ['ONLINE_COURSE', 'BOOK', 'CERTIFICATION_MATERIAL', 'BOOTCAMP', 'PROJECT_SPEC', 'COACH_MENTOR', 'OTHER'],
            example: 'ONLINE_COURSE',
          },
          startDate: { type: 'string', format: 'date', example: '2026-07-01' },
          targetDate: { type: 'string', format: 'date', example: '2026-12-31' },
          forceQueue: { type: 'boolean', default: false },
          schedule: {
            type: 'object',
            properties: {
              sessionDurationMinutes: { type: 'integer', example: 60 },
              preferredTime: { type: 'string', example: '18:00' },
              days: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    dayOfWeek: { type: 'integer', example: 1, description: '1 = Mon ... 7 = Sun' },
                    startTime: { type: 'string', example: '18:00' },
                    durationMinutes: { type: 'integer', example: 60 },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
  paths: {
    '/health/live': {
      get: {
        summary: 'Liveness Probe',
        description: 'Returns 200 OK if service process is alive.',
        responses: {
          200: { description: 'Service is alive' },
        },
      },
    },
    '/health/ready': {
      get: {
        summary: 'Readiness Probe',
        description: 'Verifies database connectivity with PostgreSQL on Neon.',
        responses: {
          200: { description: 'Service and database are ready' },
          503: { description: 'Database unavailable' },
        },
      },
    },
    '/auth/register': {
      post: {
        summary: 'Register new account',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/RegisterRequest' } } },
        },
        responses: {
          201: { description: 'User registered and tokens issued' },
          409: { description: 'Email already exists' },
        },
      },
    },
    '/auth/login': {
      post: {
        summary: 'Log in with credentials',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/LoginRequest' } } },
        },
        responses: {
          200: { description: 'Logged in successfully' },
          401: { description: 'Invalid email or password' },
        },
      },
    },
    '/auth/refresh': {
      post: {
        summary: 'Rotate refresh token and issue new token pair',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/RefreshTokenRequest' } } },
        },
        responses: {
          200: { description: 'New token pair issued' },
          401: { description: 'Invalid or revoked refresh token' },
        },
      },
    },
    '/auth/me': {
      get: {
        summary: 'Get current user profile',
        security: [{ BearerAuth: [] }],
        responses: {
          200: { description: 'Current user profile' },
          401: { description: 'Unauthorized' },
        },
      },
    },
    '/dashboard': {
      get: {
        summary: 'Consolidated Dashboard for Mobile Home',
        description: 'Returns active journey, upcoming commitment countdown, weekly stats, group preview, and check-in status.',
        security: [{ BearerAuth: [] }],
        responses: {
          200: { description: 'Consolidated dashboard data' },
        },
      },
    },
    '/journeys/active': {
      get: {
        summary: 'Get current active journey (One Journey. Full Focus)',
        security: [{ BearerAuth: [] }],
        responses: {
          200: { description: 'Active journey details or null if no active journey' },
        },
      },
    },
    '/journeys': {
      post: {
        summary: 'Create a new journey (enforces single active journey rule)',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { $ref: '#/components/schemas/CreateJourneyRequest' } } },
        },
        responses: {
          201: { description: 'Journey created' },
          409: { description: 'Active journey already exists; queue required' },
        },
      },
    },
    '/sync/events': {
      post: {
        summary: 'Synchronize offline client events (idempotent)',
        security: [{ BearerAuth: [] }],
        responses: {
          200: { description: 'Events processed and recorded' },
        },
      },
    },
  },
};
