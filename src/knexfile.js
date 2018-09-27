require('babel-register');
require('dotenv').config({ path: __dirname + '/../.env' });

/**
 * Database configuration.
 */
module.exports = {  
  "host": process.env.DB_HOST,
  "port": process.env.DB_PORT,
  "database": process.env.NODE_ENV === 'test' ? process.env.TEST_DB_NAME : process.env.DB_NAME,
  "user":  process.env.DB_USER,
  "password":  process.env.DB_PASSWORD,
  "max": "10",
  "idleTimeoutMillis": "30000"
};
