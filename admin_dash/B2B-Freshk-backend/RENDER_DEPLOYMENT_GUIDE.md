# 🚀 Render Deployment Guide for FreshK B2B Backend

## 📋 Prerequisites Checklist

- [x] ✅ **Django Application** - Ready for deployment
- [x] ✅ **Neon Database** - PostgreSQL database setup
- [x] ✅ **GitHub Repository** - Code pushed to GitHub
- [ ] 🔄 **Render Account** - Create account at [render.com](https://render.com)
- [ ] 🔄 **Domain/DNS** - (Optional) Custom domain setup

## 🔧 Pre-Deployment Configuration

### 1. **Neon Database Setup**
1. Create a Neon database at [neon.tech](https://neon.tech)
2. Get your connection string (format: `postgresql://username:password@ep-xxxxx.us-east-1.aws.neon.tech/dbname?sslmode=require`)
3. Note down the connection details for environment variables

### 2. **Environment Variables for Render**
Set these in your Render Dashboard under Environment Variables:

```bash
# Required Variables
DATABASE_URL=postgresql://username:password@ep-xxxxx.us-east-1.aws.neon.tech/freshk_db?sslmode=require
SECRET_KEY=auto-generated-by-render
DEBUG=False
RENDER=True

# Server Configuration
PYTHON_VERSION=3.11.0
WEB_CONCURRENCY=4

# CORS Settings (Update with your frontend URLs)
CORS_ALLOWED_ORIGINS=https://your-frontend.com,https://your-admin.com

# Optional: Twilio for SMS (if needed)
TWILIO_ENABLED=False
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=your-twilio-phone
```

## 🚀 Deployment Steps

### Option A: Using render.yaml (Recommended)

1. **Connect GitHub Repository**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml`

2. **Configure Environment Variables**
   - In Render Dashboard, go to your service
   - Navigate to "Environment" tab
   - Add all required environment variables listed above
   - Make sure `DATABASE_URL` points to your Neon database

3. **Deploy**
   - Click "Deploy Latest Commit"
   - Monitor build logs for any issues

### Option B: Manual Deployment

1. **Create Web Service**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New" → "Web Service"
   - Connect your GitHub repository

2. **Configure Service Settings**
   ```yaml
   Name: freshk-backend
   Environment: Python
   Region: Oregon (or your preferred region)
   Branch: main (or your deployment branch)
   Build Command: ./build.sh
   Start Command: gunicorn --bind 0.0.0.0:$PORT freshk.wsgi:application
   ```

3. **Set Environment Variables** (same as Option A)

4. **Deploy**

## 🔍 Post-Deployment Verification

### 1. **Health Check**
Visit your deployed URL + `/api/health/` to verify the service is running:
```
https://your-app-name.onrender.com/api/health/
```

Expected response:
```json
{
  "status": "healthy",
  "service": "freshk-backend"
}
```

### 2. **API Endpoints Test**
- **Swagger Documentation**: `https://your-app-name.onrender.com/api/docs/`
- **Admin Panel**: `https://your-app-name.onrender.com/admin/`
- **JWT Token**: `https://your-app-name.onrender.com/api/token/`

### 3. **Database Verification**
```bash
# Check migrations
python manage.py showmigrations

# Create superuser (if needed)
python manage.py createsuperuser
```

## 🛠️ Troubleshooting Common Issues

### Issue 1: Build Failures
```bash
# Check build logs in Render Dashboard
# Common fixes:
# - Verify requirements.txt has all dependencies
# - Ensure build.sh is executable
# - Check Python version compatibility
```

### Issue 2: Database Connection Issues
```bash
# Verify DATABASE_URL format
# Ensure Neon database allows connections
# Check SSL requirements (should include ?sslmode=require)
```

### Issue 3: Static Files Not Loading
```bash
# Verify WhiteNoise is properly configured
# Check STATIC_ROOT and STATIC_URL settings
# Ensure collectstatic runs successfully in build.sh
```

### Issue 4: CORS Issues
```bash
# Update CORS_ALLOWED_ORIGINS with your frontend URLs
# Verify ALLOWED_HOSTS includes your Render domain
```

## 🔄 Updating Your Application

### For Code Changes:
1. Push changes to your GitHub repository
2. Render will automatically deploy (if auto-deploy is enabled)
3. Or manually trigger deployment from Render Dashboard

### For Environment Variables:
1. Update variables in Render Dashboard
2. Restart the service

### For Database Migrations:
1. Push migration files to repository
2. Redeploy - `build.sh` will automatically run migrations

## 📊 Monitoring & Logs

### Access Logs:
- Go to Render Dashboard → Your Service → Logs
- Monitor for errors and performance issues

### Metrics:
- Check service metrics in Render Dashboard
- Monitor CPU, Memory, and Response times

## 🔒 Security Considerations

### Production Security Settings:
```python
# These are already configured in settings.py
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### Environment Variables Security:
- Never commit sensitive data to repository
- Use Render's environment variable management
- Rotate secrets regularly

## 💡 Performance Optimization

### Database Optimization:
- Use connection pooling (already configured)
- Monitor Neon database performance
- Consider read replicas for scaling

### Static Files:
- WhiteNoise handles compression and caching
- Consider CDN for better global performance

### Scaling:
- Start with Render's Starter plan
- Monitor resource usage
- Scale to Standard/Pro plans as needed

## 📞 Support Resources

- **Render Documentation**: [render.com/docs](https://render.com/docs)
- **Neon Documentation**: [neon.tech/docs](https://neon.tech/docs)
- **Django Deployment**: [docs.djangoproject.com](https://docs.djangoproject.com)

## ✅ Deployment Checklist

- [ ] Neon database created and accessible
- [ ] Environment variables configured in Render
- [ ] Repository connected to Render
- [ ] Build script working correctly
- [ ] Health check endpoint responding
- [ ] Static files loading correctly
- [ ] Database migrations applied
- [ ] CORS configured for frontend
- [ ] Admin panel accessible
- [ ] API endpoints functional
- [ ] Monitoring and logging configured

---

**🎉 Congratulations! Your FreshK B2B Backend is now deployed on Render with Neon database!** 