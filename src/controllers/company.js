import { Router } from 'express';
import * as companyService from '../services/companyService';

const router = Router();

/**
 * GET /api/users/:id
 */
router.get('/company/info/:id', (req, res, next) => {
  console.log('req.params.id===',req.params.id);
  companyService
    .getCompanyInfoById(req.params.id)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * GET /groups/list
 */
router.post('/groups/list', (req, res, next) => {
  console.log('req.params.id===',req.query,req.body);
  companyService
    .getGroupList(req.userData,req.query,req.body)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * POST /group
 */
router.post('/group', (req, res, next) => {
  companyService
  .saveGroup(req.body)
  .then(data => res.status(data.status).send(data))
  .catch(err => res.status(err.status).send(err));
});

router.post('/email/Otp', (req, res, next) => {
  companyService
    .emailOtpInitialSetUp(req.body)
    .then(data => res.status(data.status).send(data))
    .catch(err => res.status(err.status).send(err));
});

/**
 * GET /api/users/:id
 */
router.get('/mail', (req, res, next) => {
  companyService
    .mailsend()
    .then(data => res.json({ data }))
    .catch(err => next(err));
});

export default router;
