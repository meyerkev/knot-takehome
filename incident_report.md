# Incident Report

## Summary
Intermittent 5xx errors were observed from the HTTP server. Investigation revealed a random 20% chance of returning a 500 status as part of a testing scenario.

## Investigation Steps
1. Reviewed the server logs and noticed 500 responses appearing approximately 20% of the time.
2. Inspected the application source and found a conditional statement using `random.random()` in `app.py` triggering 500 responses.

## Root Cause
The application purposely simulates errors by returning a 500 response when a random number is less than 0.2.

## Mitigation
Remove or modify the error-simulation logic in `app.py` or reduce the error rate. After updating the application, rebuild and redeploy the Docker container.
