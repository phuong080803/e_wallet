# E-Wallet Transaction System Optimization - Deployment Guide

## Overview
This guide walks you through deploying the optimized transaction system with balance tracking and user-centric transaction records.

## Pre-Deployment Checklist

### 1. Backup Current Data
```sql
-- Create backup of existing transactions
CREATE TABLE transactions_backup AS SELECT * FROM transactions;

-- Verify backup
SELECT COUNT(*) FROM transactions_backup;
```

### 2. Test Environment Setup
- Deploy to staging/test environment first
- Verify all functionality works as expected
- Run end-to-end tests

## Deployment Steps

### Step 1: Deploy Database Schema
Execute the `optimized_transaction_schema.sql` script in your Supabase SQL editor:

1. Open Supabase Dashboard → SQL Editor
2. Paste the contents of `optimized_transaction_schema.sql`
3. Execute the script
4. Verify tables and indexes are created correctly

### Step 2: Update Application Dependencies
Ensure your `pubspec.yaml` includes required packages:
```yaml
dependencies:
  uuid: ^4.1.0  # For generating transaction group IDs
  intl: ^0.18.1  # For number formatting
```

### Step 3: Verify Code Changes
The following files have been updated and should be deployed:

#### Controllers:
- `lib/controllers/wallet_controller.dart` - Updated `transferMoney()` method
- `lib/controllers/transaction_controller.dart` - New transaction management

#### Models:
- `lib/models/database_models.dart` - Updated `Transaction` model

#### UI Screens:
- `lib/pages/screens/wallet/transaction_history_screen.dart` - New transaction history UI
- `lib/pages/screens/wallet/transfer_success_screen.dart` - New success screen
- `lib/pages/screens/wallet/transfer_money_screen.dart` - Updated transfer flow

### Step 4: Navigation Updates
Ensure your app's navigation includes the new transaction history screen. Add to your main navigation or wallet section:

```dart
// Example navigation to transaction history
Get.to(() => TransactionHistoryScreen());
```

## Post-Deployment Verification

### 1. Database Verification
```sql
-- Check new schema is active
\d transactions

-- Verify view exists
SELECT * FROM transaction_history LIMIT 5;

-- Check indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'transactions';
```

### 2. Application Testing

#### Test Transfer Flow:
1. Open transfer money screen
2. Enter recipient wallet ID (10 digits)
3. Verify recipient lookup works automatically
4. Enter amount and notes
5. Complete OTP verification
6. Verify transfer success screen appears
7. Check transaction appears in history with correct balance tracking

#### Test Transaction History:
1. Open transaction history screen
2. Verify filter tabs work (All, Incoming, Outgoing)
3. Check transaction details show:
   - Correct debit/credit indicators
   - Balance before/after amounts
   - Transaction descriptions and notes
   - Proper color coding and icons

### 3. Performance Testing
- Test with multiple transactions
- Verify loading times are acceptable
- Check pull-to-refresh functionality

## Migration Notes

### Data Migration (if needed)
If you have existing transaction data to migrate, uncomment and customize the migration section in the SQL script:

```sql
-- Calculate balance_before and balance_after based on your business logic
-- This is a complex operation that may require custom logic
```

### Balance Calculation
For existing users, you may need to:
1. Calculate current wallet balances
2. Retroactively calculate balance snapshots for historical transactions
3. Update the `wallets` table with correct current balances

## Rollback Plan

If issues occur during deployment:

### 1. Database Rollback
```sql
-- Drop new schema
DROP TABLE IF EXISTS transactions CASCADE;
DROP VIEW IF EXISTS transaction_history CASCADE;

-- Restore from backup
CREATE TABLE transactions AS SELECT * FROM transactions_backup;

-- Recreate original indexes
CREATE INDEX idx_transactions_nguoi_gui_id ON transactions(nguoi_gui_id);
CREATE INDEX idx_transactions_nguoi_nhan_id ON transactions(nguoi_nhan_id);
CREATE INDEX idx_transactions_ngay_tao ON transactions(ngay_tao);
```

### 2. Code Rollback
- Revert to previous version of updated files
- Ensure old transaction model is used
- Update wallet controller to use old schema

## Monitoring and Maintenance

### Key Metrics to Monitor:
- Transaction success/failure rates
- Database query performance
- User experience with new UI
- Balance accuracy

### Regular Maintenance:
- Monitor transaction table size and performance
- Archive old transactions if needed
- Update indexes based on query patterns
- Review and optimize transaction history queries

## Troubleshooting

### Common Issues:

#### 1. Schema Mismatch Errors
- Verify all code uses new English column names
- Check transaction model matches database schema

#### 2. Balance Calculation Errors
- Verify wallet controller records correct balance snapshots
- Check transaction amounts are properly signed (positive/negative)

#### 3. UI Display Issues
- Verify transaction controller formatting methods
- Check GetX reactive variables are properly updated

#### 4. Performance Issues
- Review database indexes
- Consider pagination for large transaction histories
- Optimize transaction history queries

## Support

For issues during deployment:
1. Check Supabase logs for database errors
2. Review Flutter debug console for application errors
3. Verify all dependencies are properly installed
4. Test individual components in isolation

## Success Criteria

Deployment is successful when:
- ✅ All transfers complete successfully with balance tracking
- ✅ Transaction history displays correctly with debit/credit indicators
- ✅ Balance snapshots are accurate before and after transactions
- ✅ UI is responsive and user-friendly
- ✅ No database errors or performance issues
- ✅ All existing functionality continues to work
