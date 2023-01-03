library(GetoptLong)

cutoff = 0.05
GetoptLong(
    "number=i{1,}", "Number of items.",
    "cutoff=f", "Cutoff for filtering results.",
    "param=s%", "Parameters specified by name=value pairs.",
    "verbose",  "Print message."
)

print(number)
print(cutoff)
print(param)
print(verbose)

