-- Add custom_notification_message column to routines table
ALTER TABLE routines 
ADD COLUMN IF NOT EXISTS custom_notification_message TEXT;

-- Add custom_notification_message column to daily_tasks table
ALTER TABLE daily_tasks 
ADD COLUMN IF NOT EXISTS custom_notification_message TEXT;

-- Add comments for documentation
COMMENT ON COLUMN routines.custom_notification_message IS 'Custom notification message that user wants to receive instead of default message';
COMMENT ON COLUMN daily_tasks.custom_notification_message IS 'Custom notification message that user wants to receive instead of default message';
