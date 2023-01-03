/TREE\([ ]\|\)1/!d

s/.\+TREE\([ ]\|\)1 = //

s/\[&R\]//

s/\[&branch_rates_range=[^]]\+\]//g

s/\[&index=[0-9]\+\]//g

s/&index=[0-9]\+,posterior=[^,]\+,//g

s/age_95%_HPD/\&95%HPD/g

s/\[&95%HPD={//g; s/}\]//g; s/\([0-9]\),\([0-9]\)/\1-\2/g

#s/\[age_95%_HPD={//g

#s/\}\]//g
