#! /bin/bash

bash ~/lab-tools/dating/hessian/output_all_combs.sh | while IFS=  read -r line; do
	echo -e "$line"
	bash ~/project/Rhizobiales/scripts/dating/hessian/do_internal_calib_in_batch.sh --cpu 30 "$line"
done
