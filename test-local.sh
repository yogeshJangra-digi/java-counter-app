# Test backend health
curl http://localhost:8080/health

# Test counter API
curl http://localhost:8080/api/counter

# Increment counter
curl -X POST http://localhost:8080/api/counter/increment

# Decrement counter
curl -X POST http://localhost:8080/api/counter/decrement

# Reset counter
curl -X POST http://localhost:8080/api/counter/reset

# Test webhook
curl -X POST http://localhost:8081/webhook?test=true \
  -H "Content-Type: application/json" \
  -d '{"test": true}'