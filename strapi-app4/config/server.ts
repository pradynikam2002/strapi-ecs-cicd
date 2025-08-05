export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS', ['qsw1!23', 'Qwe@456', 'Asd#789', 'Zxc$000']),
  },
  settings: {
    cors: {
      enabled: true,
      origin: ['*'],
    },
  },
  webhooks: {
    allowedHosts: ['*'],
  },
  admin: {
    serveAdminPanel: true,
    auth: {
      secret: env('ADMIN_JWT_SECRET'),
    },
  },
  allowedHosts: [
    'pradylb-2-500662506.us-east-2.elb.amazonaws.com',
    'localhost',
    '127.0.0.1',
  ],
});

