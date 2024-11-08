#!/bin/bash

# This script is designed to monitor and manage job resubmissions in a Slurm workload manager environment. 
# It checks if two input files, partitions_csv (a CSV file listing partition names) and node_info_json 
# (a JSON file with compute node statuses), exist. If either file is missing, it outputs an error message 
# to both stdout and stderr, then exits.
# 
# If the files exist, the script identifies jobs running on failed nodes by reading the node_info_json file. 
# For each failed job, it determines the next available partition from partitions_csv and resubmits the job 
# to that partition, putting it on hold, requeuing it, updating the partition, and then releasing it. This 
# helps ensure that jobs are automatically rescheduled on healthy nodes without manual intervention.


echod() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}


get_next_partition() {
    # Usage: ./next_element.sh  <partition> <partitions_csv>
    # Assign arguments to variables
    local partition="$1"
    local partitions_csv="$2"

    # Ensure the file ends with a newline
    if [ -n "$(tail -c 1 "${partitions_csv}")" ]; then
        echo "" >> "${partitions_csv}"
    fi

    # Read through each line of the CSV file
    while IFS=',' read -ra row; do
        # Loop through each element in the row
        for i in "${!row[@]}"; do
            if [[ "${row[$i]}" == "${partition}" ]]; then
                # Get the next element or wrap around if it's the last element
                next_index=$(( (i + 1) % ${#row[@]} ))
                echo "${row[$next_index]}"
            fi
        done
    done < "${partitions_csv}"
}


resubmit_job_to_new_partition() {
    local job_id=$1
    local partition=$2
    echod "Resubmitting job ${job_id} to partition ${partition}"
    scontrol hold ${job_id}
    scontrol requeue ${job_id}
    scontrol update JobId=${job_id} Partition=${partition}
    scontrol release ${job_id}
}

resubmit_failed_jobs_to_next_partitions() {
    local partitions_csv="$1"
    local node_info_json="$2"
    # Loop over all jobs and get their compute node and partition
    squeue --format="%.18i %.10R %.10P" | tail -n +2 | while read job_id compute_node partition; do
        
        # Check the node status in node_info.json
        status=$(jq -r --arg hostname "$compute_node" '.[] | select(.hostname == $hostname) | .status' ${node_info_json})
        
        # If the status is "failed", cancel the job
        if [ "$status" == "failed" ]; then
            echod "Job ID: $job_id | Compute Node: $compute_node | Partition: $partition | Status: failed"
            next_partition=$(get_next_partition ${partition} ${partitions_csv})
            resubmit_job_to_new_partition ${job_id} ${next_partition}
        fi
    done
}


partitions_csv=$1
node_info_json=$2

if [[ ! -f "$partitions_csv" ]]; then
    echod "Error: partitions_csv file '$partitions_csv' does not exist." | tee /dev/stderr
    exit 1
fi

if [[ ! -f "$node_info_json" ]]; then
    echod "Error: node_info_json file '$node_info_json' does not exist." | tee /dev/stderr
    exit 1
fi

resubmit_failed_jobs_to_next_partitions ${partitions_csv} ${node_info_json}

