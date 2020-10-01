require 'aws-sdk'

def get_aws_connection
  if ENV.fetch('AWS_ACCESS_KEY_ID') && ENV.fetch('AWS_SECRET_ACCESS_KEY')
    # Get an instance of the S3 interface.
    Aws::S3::Client.new(region: 'us-east-1')
  end
end

def list_buckets
  resp = get_aws_connection.list_buckets()
  resp.data.buckets
end
  
def create_bucket(bucket_name)
  if list_buckets.select { |b| b.name == bucket_name }.length == 0
    logger.info 'creating bucket'
    s3.create_bucket(bucket: bucket_name)
  end
end

def upload_file_to_bucket(file_name, bucket_name)
  logger.info "Uploading file #{file_name} to bucket #{bucket_name}..."
  key = File.basename(file_name)

  # Upload a file.
  s3.put_object(
    :bucket => bucket_name,
    :key    => key,
    :body   => IO.read(file_name)
  )
end