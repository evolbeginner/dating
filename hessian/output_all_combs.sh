#!/bin/bash

# Define the parameter values
#n_values=(0 2)
n_values=(1)
#p_values=(0.2 0.5)
p_values=(0.2)
s_values=(0 0.2 -0.2 0.5 -0.5)
options=('--only_min' '--only_max' '')
#options=('--only_min')

# Initialize an array to hold the combinations
combinations=()

# Generate combinations
for n in "${n_values[@]}"; do
    for p in "${p_values[@]}"; do
        for s in "${s_values[@]}"; do
            # Check if abs(s) is equal to abs(p)
            if [[ $s == 0 || $(echo "scale=2; ${s#-} == ${p#-}" | bc) -eq 1 ]]; then
                for option in "${options[@]}"; do
		    if [ "$s" != 0 ]; then [ "$option" != '' ] && continue; fi
                    # Create the command string
                    command="-n $n -p $p -s $s $option"
                    combinations+=("$command")
                done
            fi
        done
    done
done

# Print all combinations
for combo in "${combinations[@]}"; do
    echo "$combo"
done


