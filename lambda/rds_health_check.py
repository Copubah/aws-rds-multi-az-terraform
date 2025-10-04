import json
import boto3
import pymysql
import os
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
RDS_ENDPOINT = os.environ['RDS_ENDPOINT']
DB_NAME = os.environ.get('DB_NAME', 'mysql')
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

# Initialize AWS clients
sns_client = boto3.client('sns')
rds_client = boto3.client('rds')

def lambda_handler(event, context):
    """
    Lambda function to check RDS health and send alerts if database is unreachable
    """
    try:
        # Test database connectivity
        connection_result = test_database_connection()
        
        # Get RDS instance status
        rds_status = get_rds_instance_status()
        
        # Prepare response
        response = {
            'statusCode': 200,
            'timestamp': datetime.utcnow().isoformat(),
            'rds_endpoint': RDS_ENDPOINT,
            'connection_test': connection_result,
            'rds_status': rds_status
        }
        
        logger.info(f"Health check completed successfully: {json.dumps(response)}")
        return response
        
    except Exception as e:
        error_message = f"RDS Health Check Failed: {str(e)}"
        logger.error(error_message)
        
        # Send alert via SNS
        send_alert(error_message, str(e))
        
        return {
            'statusCode': 500,
            'error': error_message,
            'timestamp': datetime.utcnow().isoformat()
        }

def test_database_connection():
    """
    Test database connectivity by executing a simple query
    """
    try:
        # Connect to database
        connection = pymysql.connect(
            host=RDS_ENDPOINT,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            connect_timeout=10,
            read_timeout=10,
            write_timeout=10
        )
        
        with connection.cursor() as cursor:
            # Execute simple health check query
            cursor.execute("SELECT 1 as health_check, NOW() as current_time")
            result = cursor.fetchone()
            
            # Test write capability (if database exists)
            try:
                cursor.execute("SELECT COUNT(*) FROM information_schema.tables")
                table_count = cursor.fetchone()[0]
                logger.info(f"Database has {table_count} tables")
            except Exception as e:
                logger.warning(f"Could not count tables: {e}")
        
        connection.close()
        
        logger.info("Database connection test successful")
        return {
            'status': 'healthy',
            'result': result,
            'message': 'Database connection successful'
        }
        
    except pymysql.Error as e:
        error_msg = f"Database connection failed: {e}"
        logger.error(error_msg)
        raise Exception(error_msg)
    except Exception as e:
        error_msg = f"Unexpected error during database test: {e}"
        logger.error(error_msg)
        raise Exception(error_msg)

def get_rds_instance_status():
    """
    Get RDS instance status from AWS API
    """
    try:
        # Extract instance identifier from endpoint
        instance_id = RDS_ENDPOINT.split('.')[0]
        
        response = rds_client.describe_db_instances(
            DBInstanceIdentifier=instance_id
        )
        
        if response['DBInstances']:
            instance = response['DBInstances'][0]
            status_info = {
                'db_instance_status': instance.get('DBInstanceStatus'),
                'multi_az': instance.get('MultiAZ'),
                'availability_zone': instance.get('AvailabilityZone'),
                'secondary_availability_zone': instance.get('SecondaryAvailabilityZone'),
                'engine': instance.get('Engine'),
                'engine_version': instance.get('EngineVersion')
            }
            
            logger.info(f"RDS instance status: {status_info}")
            return status_info
        else:
            raise Exception("RDS instance not found")
            
    except Exception as e:
        error_msg = f"Failed to get RDS status: {e}"
        logger.error(error_msg)
        return {'error': error_msg}

def send_alert(subject, message):
    """
    Send alert notification via SNS
    """
    try:
        detailed_message = f"""
RDS Health Check Alert

Timestamp: {datetime.utcnow().isoformat()}
RDS Endpoint: {RDS_ENDPOINT}
Database: {DB_NAME}

Error Details:
{message}

Please check the RDS instance status and connectivity.
        """
        
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f" RDS Health Check Alert - {RDS_ENDPOINT}",
            Message=detailed_message
        )
        
        logger.info(f"Alert sent successfully. MessageId: {response['MessageId']}")
        
    except Exception as e:
        logger.error(f"Failed to send SNS alert: {e}")
        # Don't raise exception here to avoid masking the original error
