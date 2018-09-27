
# MarketWatch API
---
## Features:
1. ES6/ES7
2. BookShelf ORM
3. PostgreSQL
4. "Swagger-UI" & "Swagger-JSDoc"
5. "ESlint" - For Linting
6. Validation with "JOI"
7. Logging using "winston"
8. "dotenv" for App environment Configuration
9. "Mocha", "Supertest" and "Chai" for testing
10. "jsonwebtoken" - Authentication Tokens
11. "nodemon" - Autorestart on changes
12. "debug" for debugging
13. "bluebird" for handling promises
14. "helmet" for security
15. "cors" for CORS Support
16. "http-status" to set HTTP status codes.
---

---
## Prerequisites

* [Node.js](https://nodejs.org) - 8.9.0 or above
* [NPM](https://docs.npmjs.com/getting-started/installing-node) - 3.10.8 or above
---

---
## Setup

Copy the directory to destination

Make a copy of `.env.example` as `.env` and update your application details and database credentials. Now, run the migrations and seed the database.

    $ npm run migrate
    $ npm run seed

Finally, start the application.

    $ npm run start:dev (For development)
    $ npm run start (For production)

Navigate to http://localhost:8848/api-docs/ to verify installation.

## Creating new Migrations and Seeds

These are the commands to create a new migration and corresponding seed file.

    $ npm run make:migration <name>
    $ npm run make:seeder <name>

Example,

    $ npm run make:migration create_tags_table
    $ npm run make:seeder 02_insert_tags


Navigate to http://localhost:8848/api-docs/ to verify application is running from docker.


## Tests

To run the tests you need to create a separate test database. Don't forget to update your `.env` file to include the name of the test database and run the migrations.

    $ NODE_ENV=test yarn migrate
    $ npm run test

Run tests with coverage.

    $ npm run test:coverage

