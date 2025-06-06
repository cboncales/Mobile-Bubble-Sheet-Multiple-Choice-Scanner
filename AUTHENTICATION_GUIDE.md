# SmartCheckr Authentication System

## Overview

The SmartCheckr app now includes a complete authentication system designed specifically for instructors and teachers. The system uses Supabase Auth with BLoC state management for a secure and scalable solution.

## Features

- ✅ **Instructor Registration** - Create new instructor accounts
- ✅ **Login/Logout** - Secure email/password authentication
- ✅ **Route Guards** - Automatic navigation based on auth state
- ✅ **User Context** - Tests are user-specific (user_id filtering)
- ✅ **User Profile** - Display user info in app header
- ✅ **State Management** - BLoC pattern for auth state
- ✅ **Security** - Supabase Auth with JWT tokens

## Architecture

### Authentication Flow

```
App Start → Check Auth Status → Authenticated? → Home Screen
                                      ↓ No
                              Login Screen → Register Screen
```

### State Management Structure

```
AuthBloc (BLoC Pattern)
├── Events
│   ├── CheckAuthStatus
│   ├── LoginRequested
│   ├── RegisterRequested
│   └── LogoutRequested
├── States
│   ├── AuthInitial
│   ├── AuthLoading
│   ├── AuthAuthenticated
│   ├── AuthUnauthenticated
│   └── AuthError
└── AuthService (Supabase Integration)
```

## Key Components

### 1. Authentication BLoC (`lib/bloc/auth_bloc.dart`)

Manages authentication state with events and states for login, register, logout, and auth status checking.

### 2. Authentication Service (`lib/services/auth_service.dart`)

Handles all Supabase authentication operations:

- Sign in/up
- User management
- Password reset
- Auth state listening

### 3. Login Screen (`lib/screens/login_screen.dart`)

Professional login interface with:

- Email/password validation
- Loading states
- Error handling
- Navigation to registration

### 4. Register Screen (`lib/screens/register_screen.dart`)

Registration form for new instructors:

- Full name, email, password
- Password confirmation
- Terms acceptance
- Input validation

### 5. Route Guard (`lib/main.dart` - AuthWrapper)

Automatically redirects users based on authentication status:

- Authenticated → Home Screen
- Unauthenticated → Login Screen
- Loading → Spinner

### 6. User Context Integration

- All tests are filtered by `user_id`
- User profile shown in app header
- Logout functionality in main navigation

## Database Schema

The authentication system works with your existing Supabase schema:

### Users Table (Supabase Auth)

```sql
-- Automatically managed by Supabase Auth
id (uuid, primary key)
email (text)
user_metadata (jsonb) -- Contains display_name, role
created_at (timestamp)
```

### Tests Table (Your existing table)

```sql
id (uuid, primary key)
user_id (uuid, foreign key to auth.users)  -- Links tests to users
title (text)
total_items (integer)
answer_key (jsonb)
created_at (timestamp)
```

### Sheets Table (Your existing table)

```sql
id (uuid, primary key)
test_id (uuid, foreign key to Tests.id)
image (text)
student_id (text)
student_name (text)
score (integer)
created_at (timestamp)
```

## Security Features

1. **JWT Tokens** - Automatic token management via Supabase
2. **User Isolation** - Tests are filtered by user_id
3. **Protected Routes** - AuthWrapper guards the entire app
4. **Secure Storage** - Credentials stored in .env file
5. **Input Validation** - Form validation on all auth forms
6. **Error Handling** - Comprehensive error messages

## Usage Instructions

### For Instructors

1. **First Time Setup**

   - Open the app
   - Tap "Register Here"
   - Fill in your details (name, email, password)
   - Tap "Create Account"

2. **Daily Usage**

   - Open the app
   - Enter your email and password
   - Tap "Sign In"
   - Access all your tests and scan answer sheets

3. **Logout**
   - Tap the profile icon in the top-right corner
   - Select "Sign Out" from the dropdown
   - Confirm logout

### For Developers

1. **Environment Setup**
   Ensure your `.env` file contains:

   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

2. **Running the App**

   ```bash
   cd smartcheckr
   flutter pub get
   flutter run
   ```

3. **Testing Authentication**
   - Create test accounts
   - Verify user isolation (tests should be user-specific)
   - Test logout/login flow

## Row Level Security (RLS)

For production, enable RLS on your Supabase tables:

### Tests Table Policy

```sql
-- Users can only access their own tests
CREATE POLICY "Users can access own tests" ON "Tests"
FOR ALL USING (auth.uid() = user_id);
```

### Sheets Table Policy

```sql
-- Users can only access sheets for their tests
CREATE POLICY "Users can access own sheets" ON "Sheets"
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM "Tests"
    WHERE "Tests".id = "Sheets".test_id
    AND "Tests".user_id = auth.uid()
  )
);
```

## Troubleshooting

### Common Issues

1. **Login/Register Not Working**

   - Check Supabase URL and keys in .env
   - Verify network connectivity
   - Check Supabase Auth settings

2. **Tests Not Loading**

   - Ensure user is authenticated
   - Check user_id filtering in queries
   - Verify database permissions

3. **Route Guard Issues**
   - Check AuthWrapper implementation
   - Verify BLoC state transitions
   - Look for console errors

### Error Messages

- `User not authenticated` - User needs to log in
- `Failed to save test` - Check database permissions
- `Login failed` - Invalid credentials or network issue
- `Registration failed` - Email might already exist

## Security Best Practices

1. **Environment Variables** - Never commit .env files
2. **Input Validation** - Always validate user inputs
3. **Error Handling** - Don't expose sensitive error details
4. **RLS Policies** - Enable Row Level Security in production
5. **HTTPS Only** - Ensure secure connections in production

## Future Enhancements

- [ ] Password reset functionality
- [ ] Email verification
- [ ] Multi-factor authentication
- [ ] Admin role management
- [ ] Bulk user management
- [ ] Advanced user preferences

## Support

For technical support or questions about the authentication system:

1. Check this documentation first
2. Review Supabase Auth documentation
3. Check Flutter BLoC documentation
4. Look at the code comments for implementation details

---

**Note**: This authentication system is designed specifically for educational institutions where instructors need to manage and grade tests securely. All user data is isolated and protected according to educational data privacy standards.
