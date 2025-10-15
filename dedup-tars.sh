#/bin/bash -e

dir="${1:-.}"

# Ensure directory exists
if [[ ! -d "$dir" ]]; then
    echo "Error: $dir is not a directory" >&2
    exit 1
fi

# Get all packages with more than 1 version
packages=$(find "$dir" -maxdepth 1 -type f -name "*-*" -printf "%P\n" \
             | cut -d'-' -f1 \
             | sort \
             | uniq -d)

for package in $packages; do
    # List all archives for this package, sorted by modification time (newest first)
    # We want to delete all but the most recent, so remove first file from list
    delete=$(ls -t -- "$dir/${package}-"* | tail -n +2)

    for f in $delete; do
        rm -vf -- "$f"
    done
done
