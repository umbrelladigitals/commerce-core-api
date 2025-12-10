#!/bin/bash

# Commerce Core API - Quick Start Script
# Bu script projeyi hızlıca başlatmak için gerekli adımları içerir

echo "🚀 Commerce Core API - Starting..."
echo ""

# Check if Redis is running
if ! pgrep -x "redis-server" > /dev/null
then
    echo "⚠️  Redis is not running! (Continuing anyway...)"
    # echo "   Please start Redis in a separate terminal:"
    # echo "   $ redis-server"
    # echo ""
    # exit 1
fi

echo "✅ Redis is running"

# Check if PostgreSQL is running
if ! pgrep -x "postgres" > /dev/null
then
    echo "⚠️  PostgreSQL might not be running!"
    echo "   If you encounter database errors, please start PostgreSQL"
    echo ""
fi

# Check if database exists
if ! rails runner 'ActiveRecord::Base.connection' 2>/dev/null
then
    echo "📦 Setting up database..."
    rails db:create db:migrate db:seed
    echo "✅ Database setup complete"
else
    echo "✅ Database is ready"
fi

echo ""
echo "📚 Available endpoints:"
echo "   - API Docs:  http://localhost:3000/api-docs"
echo "   - Sidekiq:   http://localhost:3000/sidekiq"
echo "   - Health:    http://localhost:3000/up"
echo ""
echo "🔑 Sample credentials (from seeds):"
echo "   Email:    test@example.com"
echo "   Password: password123"
echo ""
echo "💡 Quick test commands:"
echo "   # Signup"
echo "   curl -X POST http://localhost:3000/signup -H 'Content-Type: application/json' -d '{\"user\":{\"email\":\"new@example.com\",\"password\":\"password123\",\"password_confirmation\":\"password123\"}}'"
echo ""
echo "   # Login"
echo "   curl -X POST http://localhost:3000/login -H 'Content-Type: application/json' -d '{\"user\":{\"email\":\"test@example.com\",\"password\":\"password123\"}}'"
echo ""
echo "   # List products"
echo "   curl http://localhost:3000/api/v1/catalog/products"
echo ""
echo "🎯 Starting Rails server..."
echo "   Press Ctrl+C to stop"
echo ""

rails server
