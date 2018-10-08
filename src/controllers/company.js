import { Router } from 'express';
import HttpStatus from 'http-status-codes';
import * as userService from '../services/companyService';
import { findUser, userValidator } from '../validators/userValidator';

const router = Router();

/**
 * GET /api/users
 */
router.get('/', (req, res, next) => {
  userService
    .getAllUsers()
    .then(data => res.json({ data }))
    .catch(err => next(err));
});


/**
 * GET /api/users
 */
router.get('/plandetails', (req, res, next) => {
  userService
    .getPlandetails()
    .then(data => res.json({ data }))
    .catch(err => next(err));
});


/**
 * GET /api/users/:id
 */
router.get('/plandetails/:id', (req, res, next) => {
  console.log('req.params.id===',req.params.id);
  userService
    .getPlandetailById(req.params.id)
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

/**
 * POST /api/users
 */
router.post('/company/signup', (req, res, next) => {
  userService
    .companySignUp(req.body)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * GET /api/users/:id
 */
router.get('/Company/info/:id', (req, res, next) => {
  console.log('req.params.id===',req.params.id);
  userService
    .getCompanyInfoById(req.params.id)
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

router.post('/email/Otp', (req, res, next) => {
  userService
    .emailOtpInitialSetUp(req.body)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * GET /api/users/:id
 */
router.get('/mail', (req, res, next) => {
  userService
    .mailsend()
    .then(data => res.json({ data }))
    .catch(err => next(err));
});


/**
 * PUT /api/users/:id
 */
router.put('/:id', findUser, userValidator, (req, res, next) => {
  userService
    .updateUser(req.params.id, req.body)
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

/**
 * DELETE /api/users/:id
 */
router.delete('/:id', findUser, (req, res, next) => {
  userService
    .deleteUser(req.params.id)
    .then(data => res.status(HttpStatus.NO_CONTENT).json({ data }))
    .catch(err => next(err));
});

export default router;
