import { Router } from 'express';
import HttpStatus from 'http-status-codes';
import * as authService from '../services/authService';
import { findUser, userValidator } from '../validators/userValidator';

const router = Router();

/**
 * GET /api/resource/plandetails
 */
router.get('/plandetails', (req, res, next) => {
    authService
    .getPlandetails()
    .then(data => res.json({ data }))
    .catch(err => next(err));
});


/**
 * GET /api/resource/plandetails:id
 */
router.get('/plandetails/:id', (req, res, next) => {
  console.log('req.params.id===',req.params.id);
  authService
    .getPlandetailById(req.params.id)
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

/**
 * POST /api/resource/company/signup
 */
router.post('/company/signup', (req, res, next) => {
    authService
    .companySignUp(req.body)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * GET /api/users/:id
 */
router.get('/Company/info/:id', (req, res, next) => {
  console.log('req.params.id===',req.params.id);
  authService
    .getCompanyInfoById(req.params.id)
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

/**
 * POST /api/users
 */
router.post('/authenticate', (req, res, next) => {
    authService
      .authenticateUser(req.body)
      .then(data => res.status(data.status).send(data))
      .catch(err => res.status(err.status).send(err));
  });
export default router;