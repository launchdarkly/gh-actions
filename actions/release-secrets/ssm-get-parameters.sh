set -e

# Parse parameter pairs from format: "/ssm/path = ENV_NAME, /ssm/path2 = ENV_NAME2"
# Fetch values from AWS SSM, mask them in logs, and export as environment variables.

# Use sed to remove potential whitespace around the '=' in the pairs.
# Then split the string based on ',' to get an array of pairs.
IFS=',' read -ra pairs <<< $(echo "${SSM_PARAMETER_PAIRS}" | sed 's/[[:space:]]*=[[:space:]]*/=/g')

# Collect all SSM paths and their corresponding env var names.
ssm_paths=()
env_names=()
for pair in "${pairs[@]}"; do
  IFS='=' read -r ssm_path env_name <<< "${pair}"
  ssm_path=$(echo "${ssm_path}" | xargs)
  env_name=$(echo "${env_name}" | xargs)
  ssm_paths+=("${ssm_path}")
  env_names+=("${env_name}")
done

# Process in chunks of 10 (AWS SSM GetParameters API limit).
chunk_size=10
total=${#ssm_paths[@]}

for ((i=0; i<total; i+=chunk_size)); do
  chunk=("${ssm_paths[@]:i:chunk_size}")

  # Build the --names argument.
  result=$(aws ssm get-parameters --names "${chunk[@]}" --with-decryption --output json)

  # Parse each parameter from the JSON response.
  param_count=$(echo "${result}" | jq '.Parameters | length')
  for ((j=0; j<param_count; j++)); do
    name=$(echo "${result}" | jq -r ".Parameters[${j}].Name")
    value=$(echo "${result}" | jq -r ".Parameters[${j}].Value")

    # Find the corresponding env var name for this SSM path.
    for ((k=0; k<total; k++)); do
      if [ "${ssm_paths[k]}" = "${name}" ]; then
        target_env="${env_names[k]}"
        break
      fi
    done

    # Mask the value in logs.
    echo "::add-mask::${value}"

    # Export as environment variable for subsequent steps.
    echo "${target_env}=${value}" >> "${GITHUB_ENV}"
    echo "Env variable ${target_env} set with value from ssm parameterName ${name}"
  done
done
