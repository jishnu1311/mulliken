#!/bin/bash
output_file="all_results.txt"

# Initialize the output file
echo "Directory,Fragment1_charge,Fragment2_charge,Fragment3_charge,Fragment1_spin,Fragment2_spin,Fragment3_spin" > "$output_file"

# Loop through each subdirectory
for dir in */; do
    log_file=$(find "$dir" -name "*.log" | head -n 1)
    if [ -z "$log_file" ]; then
        echo "No log file found in $dir"
        continue
    fi
    echo "Processing $log_file..."

    # Create temp directory
    temp_dir="temp_dir"
    if [ ! -d "$temp_dir" ]; then
        mkdir "$temp_dir"
    fi

    # Find the last occurrence of 'Mulliken charges and spin densities:' and get the line number
    last_occurrence_start=$(awk '/Mulliken charges and spin densities:/ {line=NR} END {print line}' "$log_file")

    if [ -z "$last_occurrence_start" ]; then
        echo "Mulliken charges and spin densities not found in $log_file"
        continue
    fi

    # Extract the data after the last occurrence, skipping the first line with '1 2'
    tail -n +$((last_occurrence_start + 1)) "$log_file" | sed '1d' > "$temp_dir/temp_last"

    # Print the first few lines of temp_last for debugging
    echo "Extracted section:"
    head -n 20 "$temp_dir/temp_last"

    echo "Temp file created for $dir"

    # Define atom ranges for each fragment
    fragment_ranges=("1-26" "27-50" "51-78")

    charges=()
    spins=()

    # Loop through each fragment range
    for range in "${fragment_ranges[@]}"; do
        start_atom=$(echo $range | cut -d '-' -f 1)
        end_atom=$(echo $range | cut -d '-' -f 2)

        # Extract fragment data for the range
        fragment_data=$(sed -n "${start_atom},${end_atom}p" "$temp_dir/temp_last")

        # Debugging: Print extracted fragment data
        echo "Fragment data for atoms $start_atom-$end_atom:"
        echo "$fragment_data"

        # Calculate sum of charges and spins
        fragment_charge=$(echo "$fragment_data" | awk '{sum+=$3} END {print sum}')
        fragment_spin=$(echo "$fragment_data" | awk '{sum+=$4} END {print sum}')

        # Debugging: Print charges and spins
        echo "Fragment charge: $fragment_charge"
        echo "Fragment spin: $fragment_spin"

        charges+=("$fragment_charge")
        spins+=("$fragment_spin")
    done

    # Write results to output file
    echo -n "$dir," >> "$output_file"
    for charge in "${charges[@]}"; do
        echo -n "$charge," >> "$output_file"
    done
    for spin in "${spins[@]}"; do
        echo -n "$spin," >> "$output_file"
    done
    echo >> "$output_file"

    # Clean up
    rm -r "$temp_dir"
done

echo "Processing completed. All results saved in $output_file."
