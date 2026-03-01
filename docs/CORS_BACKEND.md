# Backend CORS Configuration for Flutter Web (dugsi.so)

The Flutter web app at **https://dugsi.so** (and **https://www.dugsi.so**) calls the API at **https://api.dugsi.so**. Browsers block these requests unless the backend sends correct CORS headers.

## Problem

- Browser sends **OPTIONS** preflight to `https://api.dugsi.so/api/auth/login` (and other endpoints).
- If the response does not include `Access-Control-Allow-Origin: https://dugsi.so` (or the requesting origin), the browser blocks the request.
- Console shows: *"No Access-Control-Allow-Origin header"* / *"preflight request doesn't pass access control check"*.

## Required: Express CORS (Node/Express backend)

Configure CORS **before** all API routes (before `app.use('/api', routes)`).

### 1. Install

```bash
npm install cors
```

### 2. Configure and apply

```javascript
const cors = require("cors");

const allowedOrigins = [
  "https://dugsi.so",
  "https://www.dugsi.so",
  "http://localhost:3000",
  "http://localhost:5173",
  "http://localhost:8080",
];

const corsOptions = {
  origin: function (origin, callback) {
    if (!origin) return callback(null, true); // e.g. curl / Postman
    if (allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error("CORS blocked: " + origin));
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};

app.use(cors(corsOptions));
app.options("*", cors(corsOptions));
```

Place this **before** any `app.use('/api', ...)` or route handlers.

### 3. Verify after deploy

In browser DevTools (Network tab) on https://dugsi.so:

1. **OPTIONS** `https://api.dugsi.so/api/auth/login` → status **200** or **204**, response headers must include:
   - `Access-Control-Allow-Origin: https://dugsi.so`
   - `Access-Control-Allow-Methods: ...` (include GET, POST, OPTIONS, etc.)
   - `Access-Control-Allow-Headers: Content-Type, Authorization`
2. **POST** `https://api.dugsi.so/api/auth/login` → then runs and returns **200** with token.

## If using Apache / Phusion Passenger

- Ensure Apache is **not** stripping or blocking **OPTIONS** requests.
- Prefer fixing CORS in the Express app (above). Only add server-level CORS headers if the app is not reachable for OPTIONS (e.g. reverse proxy blocking OPTIONS).

## Summary

| Item | Value |
|------|--------|
| Allowed origins | `https://dugsi.so`, `https://www.dugsi.so`, localhost variants |
| Methods | GET, POST, PUT, PATCH, DELETE, OPTIONS |
| Headers | Content-Type, Authorization |
| credentials | true |
| Preflight | `app.options('*', cors(corsOptions))` |

After applying and restarting the backend, the Flutter web app should be able to log in without CORS errors.
