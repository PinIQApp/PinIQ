# Load Testing

Use this folder for lightweight pre-launch smoke load tests against staging.

## Basic `hey` examples

Login:

```bash
hey -n 100 -c 10 -m POST -H "Content-Type: application/json" \
  -d '{"email":"coach@example.com","password":"Password123"}' \
  http://localhost:8000/api/v1/auth/login
```

Store view:

```bash
hey -n 100 -c 10 -H "Authorization: Bearer <token>" \
  http://localhost:8000/api/v1/store/team/1
```

Messaging inbox:

```bash
hey -n 100 -c 10 -H "Authorization: Bearer <token>" \
  http://localhost:8000/api/v1/messages/user/1
```

## What to watch

- median and p95 latency
- error rate
- DB saturation
- duplicate side effects on retried requests
