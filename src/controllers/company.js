import { Router } from 'express';

const router = Router();

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

export default router;
