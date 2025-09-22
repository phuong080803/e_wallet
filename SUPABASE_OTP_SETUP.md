# Supabase Native OTP Setup Guide

## Overview
This guide explains how to configure Supabase's built-in OTP functionality for the e-wallet app.

## Supabase Dashboard Configuration

### 1. Enable Email OTP
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Settings**
3. Scroll down to **Auth Providers**
4. Enable **Email** provider if not already enabled
5. Configure **Email Templates** (optional but recommended)

### 2. Configure Email Templates (Recommended)
1. Go to **Authentication** > **Email Templates**
2. Select **Magic Link** template
3. Customize the email template with your branding:

```html
<h2>Your OTP Code</h2>
<p>Use this code to verify your transaction:</p>
<h3 style="color: #667eea; font-size: 32px; letter-spacing: 5px;">{{ .Token }}</h3>
<p>This code expires in 60 minutes.</p>
<p><strong>Security Note:</strong> Do not share this code with anyone.</p>
```

### 3. SMTP Configuration (Production)
For production use, configure custom SMTP:
1. Go to **Settings** > **Auth**
2. Scroll to **SMTP Settings**
3. Configure your email provider (Gmail, SendGrid, etc.)

## App Configuration

### 1. Dependencies
Ensure you have the latest Supabase Flutter package:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

### 2. Usage in App
The OTP controller is already configured to use Supabase's native methods:

- `signInWithOtp()` - Sends OTP to user's email
- `verifyOTP()` - Verifies the entered OTP code

### 3. Security Features
- OTP codes expire automatically (default: 60 minutes)
- One-time use only
- Rate limiting built-in
- Secure email delivery

## Testing

### Development Mode
- Supabase provides test OTP codes in development
- Check your project logs for OTP codes during testing

### Production Mode
- Real emails will be sent to users
- Configure proper SMTP for reliable delivery

## Benefits of Native OTP

1. **No Custom Database Tables** - No need for otp_verifications table
2. **No Edge Functions** - No custom email sending functions needed
3. **Built-in Security** - Rate limiting, expiration, one-time use
4. **Professional Emails** - Customizable templates
5. **Automatic Cleanup** - No manual OTP cleanup required
6. **Scalable** - Handles high volume automatically

## Migration Notes

The app has been updated to use Supabase's native OTP instead of custom implementation:
- Removed custom OTP database table
- Removed custom Edge Function
- Simplified OTP controller
- Better security and reliability
