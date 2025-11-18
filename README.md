## Gallery App Notes

- The frontend now talks to the backend directly via API Gateway. Set `VITE_API_URL` (or `.env`) to `https://f468xcr3y9.execute-api.us-east-1.amazonaws.com` when building or running locally.
- CloudFront serves only the static site from S3; `/api/*` requests should not be proxied through the CDN anymore.
- After updating `VITE_API_URL`, rebuild (`npm run build`) and redeploy so the changes propagate to production.

