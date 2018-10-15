import { Router } from 'express';
import swaggerSpec from './utils/swagger';
import usersController from './controllers/users';
import companyController from './controllers/company';
import subController from './controllers/subController';
import jwt from 'jsonwebtoken';

/**
 * Contains all API routes for the application.
 */
let router = Router();

/**
 * GET /api/swagger.json
 */
router.get('/swagger.json', (req, res) => {
  res.json(swaggerSpec);
});

/**
 * @swagger
 * definitions:
 *   App:
 *     title: App
 *     type: object
 *     properties:
 *       app:
 *         type: string
 *       apiVersion:
 *         type: string
 */

/**
 * @swagger
 * /:
 *   get:
 *     summary: Get API version
 *     description: App version
 *     produces:
 *       - application/json
 *     tags:
 *       - Base
 *     responses:
 *       200:
 *         description: Application and API version
 *         schema:
 *           title: Users
 *           type: object
 *           $ref: '#/definitions/App'
 */
router.get('/', (req, res) => {
  res.json({
    app: req.app.locals.title,
    apiVersion: req.app.locals.version
  });
});

router.use('/user',  usersController);
router.use('/resource', subController);
router.use('/v1', tokenVerify, companyController);

// app.use(function (request, res, next) {
// 	if (request.url.indexOf('login') > -1) {
// 		next();
// 	} else {
// 		verifyAccessToken(request, res, next);
// 	}
// });

/**
   * VERIFY JWT TOKEN.
   *
   * @param  {string}  token
   * @return {Promise}
   */

function tokenVerify(req, res, next) {
  console.log(req.headers);
  
  let token = req && req.headers && req.headers['x-auth-token'];
  return new Promise(function (resolve, reject) {
    if (token) {
      jwt.verify(token, process.env.JWT_SECRET, function (err, decoded) {
        if (err) {
          res.status(401).send({ statusCode: 401, message: 'Failed to authenticate token.' });
        } else {
          console.log('decoded==',decoded);
          
          req.userData = decoded;
          next();
        }
      })
    } else {
      res.status(404).send({ statusCode: 404, message: 'No token found.' });
    }
  })
}


export default router;
