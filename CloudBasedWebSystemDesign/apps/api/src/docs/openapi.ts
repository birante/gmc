/**
 * OpenAPI 3.1 contract served at /api/openapi.json and rendered at /api/docs.
 * Kept next to the code and verified by an integration test so it cannot drift silently.
 */
const bearer = [{ bearerAuth: [] }];
const id = { name: 'id', in: 'path', required: true, schema: { type: 'string' } };
const clinicQuery = { name: 'clinicId', in: 'query', required: false, schema: { type: 'string' }, description: 'Admins only: filter by clinic' };
const json = (schema: object) => ({ 'application/json': { schema } });
const ref = (name: string) => ({ $ref: `#/components/schemas/${name}` });
const ok = (description: string, schema?: object) => ({
  description,
  ...(schema ? { content: json({ type: 'object', properties: { data: schema } }) } : {}),
});
const errors = {
  400: { description: 'Validation error', content: json(ref('Error')) },
  401: { description: 'Missing or invalid token', content: json(ref('Error')) },
  403: { description: 'Forbidden for this role or clinic', content: json(ref('Error')) },
};

export const openApiDocument = {
  openapi: '3.1.0',
  info: {
    title: 'VaxTrack API',
    version: '1.0.0',
    description:
      'REST API for vaccination scheduling, reminders and coverage monitoring in primary health clinics. ' +
      'Authenticate with POST /api/auth/login and send the token as `Authorization: Bearer <token>`.',
  },
  servers: [{ url: '/' }],
  tags: [
    { name: 'System' }, { name: 'Auth' }, { name: 'Patients' }, { name: 'Immunizations' },
    { name: 'Dashboard' }, { name: 'Reminders' }, { name: 'Public' }, { name: 'Admin' },
  ],
  components: {
    securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          error: {
            type: 'object',
            properties: { code: { type: 'string' }, message: { type: 'string' }, details: {} },
            required: ['code', 'message'],
          },
        },
      },
      DoseStatus: { type: 'string', enum: ['ADMINISTERED', 'OVERDUE', 'DUE', 'UPCOMING'] },
      Clinic: {
        type: 'object',
        properties: { id: { type: 'string' }, code: { type: 'string' }, name: { type: 'string' }, region: { type: 'string' }, district: { type: 'string' } },
      },
      User: {
        type: 'object',
        properties: {
          id: { type: 'string' }, email: { type: 'string', format: 'email' }, name: { type: 'string' },
          role: { type: 'string', enum: ['ADMIN', 'CLINICIAN'] }, active: { type: 'boolean' }, clinicId: { type: ['string', 'null'] },
        },
      },
      PatientInput: {
        type: 'object',
        required: ['firstName', 'lastName', 'sex', 'dateOfBirth', 'guardianName', 'guardianPhone'],
        properties: {
          firstName: { type: 'string' }, lastName: { type: 'string' }, sex: { type: 'string', enum: ['F', 'M'] },
          dateOfBirth: { type: 'string', format: 'date' }, guardianName: { type: 'string' },
          guardianPhone: { type: 'string', example: '+221770001234' }, address: { type: 'string' },
          clinicId: { type: 'string', description: 'Required for admins; clinicians always use their own clinic' },
        },
      },
      Dose: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          vaccine: { type: 'object', properties: { code: { type: 'string' }, name: { type: 'string' } } },
          scheduledDate: { type: 'string', format: 'date' },
          administeredDate: { type: ['string', 'null'], format: 'date' },
          status: ref('DoseStatus'),
        },
      },
      PatientDetail: {
        type: 'object',
        properties: {
          id: { type: 'string' }, referenceCode: { type: 'string' }, firstName: { type: 'string' }, lastName: { type: 'string' },
          dateOfBirth: { type: 'string', format: 'date' }, age: { type: 'string' },
          summary: { type: 'object', properties: { total: { type: 'integer' }, administered: { type: 'integer' }, overdue: { type: 'integer' }, due: { type: 'integer' } } },
          immunizations: { type: 'array', items: ref('Dose') },
        },
      },
    },
  },
  paths: {
    '/health': { get: { tags: ['System'], summary: 'Liveness/readiness probe (checks the database)', responses: { 200: { description: 'Healthy' }, 503: { description: 'Database unreachable' } } } },
    '/api/auth/login': {
      post: {
        tags: ['Auth'], summary: 'Exchange credentials for a JWT',
        requestBody: { required: true, content: json({ type: 'object', required: ['email', 'password'], properties: { email: { type: 'string' }, password: { type: 'string' } } }) },
        responses: { 200: ok('Token and profile', { type: 'object', properties: { token: { type: 'string' }, user: ref('User') } }), 401: errors[401], 429: { description: 'Rate limited' } },
      },
    },
    '/api/auth/me': { get: { tags: ['Auth'], security: bearer, summary: 'Current user profile', responses: { 200: ok('Profile', ref('User')), 401: errors[401] } } },
    '/api/patients': {
      get: {
        tags: ['Patients'], security: bearer, summary: 'List/search patients (scoped to the clinician\'s clinic)',
        parameters: [
          { name: 'search', in: 'query', schema: { type: 'string' } }, clinicQuery,
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'pageSize', in: 'query', schema: { type: 'integer', default: 20, maximum: 100 } },
        ],
        responses: { 200: { description: 'Paginated list' }, 401: errors[401] },
      },
      post: {
        tags: ['Patients'], security: bearer, summary: 'Register a patient and generate their schedule',
        requestBody: { required: true, content: json(ref('PatientInput')) },
        responses: { 201: ok('Created', ref('PatientDetail')), ...errors },
      },
    },
    '/api/patients/{id}': {
      get: { tags: ['Patients'], security: bearer, parameters: [id], summary: 'Patient with full schedule and computed statuses', responses: { 200: ok('Patient', ref('PatientDetail')), 404: { description: 'Not found' }, ...errors } },
      patch: { tags: ['Patients'], security: bearer, parameters: [id], summary: 'Update demographics (re-plans pending doses if DOB changes)', requestBody: { content: json(ref('PatientInput')) }, responses: { 200: ok('Updated', ref('PatientDetail')), ...errors } },
      delete: { tags: ['Patients'], security: bearer, parameters: [id], summary: 'Delete a patient (admin)', responses: { 204: { description: 'Deleted' }, ...errors } },
    },
    '/api/immunizations/worklist': {
      get: {
        tags: ['Immunizations'], security: bearer, summary: 'Doses due this week or overdue',
        parameters: [{ name: 'status', in: 'query', schema: { type: 'string', enum: ['DUE', 'OVERDUE'] } }, clinicQuery],
        responses: { 200: { description: 'Worklist' }, ...errors },
      },
    },
    '/api/immunizations/{id}/administer': {
      post: {
        tags: ['Immunizations'], security: bearer, parameters: [id], summary: 'Record that a dose was given',
        requestBody: { content: json({ type: 'object', properties: { administeredDate: { type: 'string', format: 'date' }, lotNumber: { type: 'string' }, notes: { type: 'string' } } }) },
        responses: { 200: ok('Recorded', ref('Dose')), 409: { description: 'Already recorded' }, ...errors },
      },
    },
    '/api/immunizations/{id}/revert': { post: { tags: ['Immunizations'], security: bearer, parameters: [id], summary: 'Undo a dose recorded by mistake', responses: { 200: ok('Reverted', ref('Dose')), ...errors } } },
    '/api/dashboard/stats': { get: { tags: ['Dashboard'], security: bearer, parameters: [clinicQuery], summary: 'Coverage per dose, dropout, due/overdue counts, monthly trend', responses: { 200: { description: 'Statistics' }, ...errors } } },
    '/api/reminders/preview': { get: { tags: ['Reminders'], security: bearer, parameters: [clinicQuery], summary: 'SMS reminders that would be sent now', responses: { 200: { description: 'Messages' }, ...errors } } },
    '/api/reminders/send': { post: { tags: ['Reminders'], security: bearer, parameters: [clinicQuery], summary: 'Send reminders through the configured SMS provider', responses: { 200: { description: 'Result' }, ...errors } } },
    '/api/public/lookup': {
      post: {
        tags: ['Public'], summary: 'Caregiver lookup by card number + last 4 digits of phone (no auth, rate limited)',
        requestBody: { required: true, content: json({ type: 'object', required: ['referenceCode', 'phoneLast4'], properties: { referenceCode: { type: 'string', example: 'VX-DEMO-2026' }, phoneLast4: { type: 'string', example: '4567' } } }) },
        responses: { 200: { description: 'Minimal schedule view' }, 404: { description: 'No matching card' }, 429: { description: 'Rate limited' } },
      },
    },
    '/api/vaccines': { get: { tags: ['Admin'], security: bearer, summary: 'Immunisation schedule (reference data)', responses: { 200: { description: 'Doses' } } } },
    '/api/clinics': {
      get: { tags: ['Admin'], security: bearer, summary: 'List clinics', responses: { 200: { description: 'Clinics' } } },
      post: { tags: ['Admin'], security: bearer, summary: 'Create clinic (admin)', requestBody: { content: json(ref('Clinic')) }, responses: { 201: { description: 'Created' }, ...errors } },
    },
    '/api/clinics/{id}': { patch: { tags: ['Admin'], security: bearer, parameters: [id], summary: 'Update clinic (admin)', responses: { 200: { description: 'Updated' }, ...errors } } },
    '/api/users': {
      get: { tags: ['Admin'], security: bearer, summary: 'List users (admin)', responses: { 200: { description: 'Users' }, ...errors } },
      post: { tags: ['Admin'], security: bearer, summary: 'Create user (admin)', responses: { 201: ok('Created', ref('User')), ...errors } },
    },
    '/api/users/{id}': { patch: { tags: ['Admin'], security: bearer, parameters: [id], summary: 'Update user / deactivate / reset password (admin)', responses: { 200: ok('Updated', ref('User')), ...errors } } },
  },
} as const;
