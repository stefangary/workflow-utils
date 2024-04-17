# Load credentials
eval $(ssh ${resource_ssh_usercontainer_options} usercontainer ${pw_job_dir}/workflow-utils/bucket_token_generator.py --bucket_id ${dcs_bucket_id} --token_format text)

# Check if dcs_model_file is empty
if [ -z "${BUCKET_NAME}" ]; then
    echo "Error: BUCKET_NAME variable is empty"
    exit 1
fi

