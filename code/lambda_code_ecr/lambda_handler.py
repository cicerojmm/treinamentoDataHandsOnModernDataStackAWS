import json
import duckdb
import os
import logging
import tempfile

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

def lambda_handler(event, context):   
    try:        
        # Create a temporary directory for DuckDB home
        temp_dir = tempfile.mkdtemp()
        logger.info(f"Created temporary directory for DuckDB home: {temp_dir}")
        
        # Initialize DuckDB with explicit home directory
        conn = duckdb.connect(':memory:')
        conn.execute(f"SET home_directory='{temp_dir}'")
        logger.info("DuckDB connection initialized successfully with custom home directory")
        
        # Install and load required extensions
        extensions = ['aws', 'httpfs', 'iceberg', 'parquet', 'avro']
        for ext in extensions:
            conn.execute(f"INSTALL {ext};")
            conn.execute(f"LOAD {ext};")
            logger.info(f"Installed and loaded {ext} extension")

        # Force install iceberg from core_nightly
        conn.execute("FORCE INSTALL iceberg FROM core_nightly;")
        conn.execute("LOAD iceberg;")
        logger.info("Forced installation and loaded iceberg from core_nightly")

        # Set up AWS credentials
        conn.execute("CALL load_aws_credentials();")
        conn.execute("""
        CREATE SECRET (
            TYPE s3,
            PROVIDER credential_chain
        );
        """)
        logger.info("Set up AWS credentials")


        print(event)

        # Check if the request is coming from Function URL (HTTP API)
        if 'queryStringParameters' in event:
            # Handle HTTP request from Function URL
            logger.info("Processing HTTP request from Function URL")
            query_params = event.get('queryStringParameters', {}) or {}
            
            # Extract parameters from query string
            catalog_arn = query_params.get('catalog_arn')
            query = query_params.get('query')
            
            # Validate required parameters
            if not catalog_arn or not query:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'error': 'Missing required parameters',
                        'required': ['catalog_arn', 'query']
                    })
                }
        else:
            # Handle direct Lambda invocation
            logger.info("Processing direct Lambda invocation")
            # Validate input parameters
            required_params = ['query', 'catalog_arn']
            if not all(param in event for param in required_params):
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Missing required parameters',
                        'required': required_params
                    })
                }
            
            catalog_arn = event['catalog_arn']
            query = event['query']

        # Use default values or get from event
        # catalog_arn =  "arn:aws:s3tables:us-east-1:010840394859:bucket/datahandson-mds-s3tables"
        # query = "SELECT * FROM s3_tables_db.movielens_curated.movie_ratings limit 10;"
        
        logger.info(f"Using catalog ARN: {catalog_arn}")
        logger.info(f"Executing query: {query}")

        # Attach S3 Tables catalog using ARN
        try:
            conn.execute(f"""
            ATTACH '{catalog_arn}' 
            AS s3_tables_db (
                TYPE iceberg,
                ENDPOINT_TYPE s3_tables
            );
            """)
            logger.info(f"Successfully attached S3 Tables catalog: {catalog_arn}")
        except Exception as e:
            logger.error(f"Catalog attachment failed: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Catalog connection failed',
                    'details': str(e)
                })
            }

        # Execute query with enhanced error handling
        try:
            result = conn.execute(query).fetchall()
            columns = [desc[0] for desc in conn.description]

            formatted = [dict(zip(columns, row)) for row in result]
            logger.info(f"Query executed successfully. Returned {len(formatted)} rows.")
            response_body = json.dumps({
                'data': formatted,
                'metadata': {
                    'row_count': len(formatted),
                    'column_names': columns
                }
            }, default=str)
            
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': response_body
            }

        except Exception as query_error:
            logger.error(f"Query execution failed: {str(query_error)}")
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Query execution error',
                    'details': str(query_error),
                    'suggestions': [
                        "Verify table exists in the attached database",
                        "Check your S3 Tables ARN format",
                        "Validate AWS permissions for the bucket"
                    ]
                })
            }

    except Exception as e:
        logger.error(f"Global error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Unexpected runtime error', 'details': str(e)})
        }
    finally:
        if 'conn' in locals():
            conn.close()