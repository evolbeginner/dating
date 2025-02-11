#! /bin/env julia


############################################
using ArgParse
using Distributions


############################################
alpha = nothing


############################################
opt = ArgParseSettings()

@add_arg_table opt begin
	"-n", "--num"
		help = "number of categories"
		arg_type = Int
		default = 1
	"--alpha", "--dirichlet"
		help = "Params for dirichlet distribution"
		arg_type = String
end


############################################
opts = parse_args(opt)

num = opts["num"]


function main()
	local alpha
	try
		alpha = map(x->parse(Float32, x), split(opts["alpha"], ","))
	catch e
		println(e)
	end

	dirichlet_dist = Dirichlet(alpha)
	rs = rand(dirichlet_dist, num)
	rs2 = rand(dirichlet_dist, num)

	for i in 1:num
		props = rs[:, i]
		rates = rs2[:, i] ./ rs[:, i]
		props = string.(props)
		rates = string.(rates)
		prop_rate = join(map(x->join(x,","), collect(zip(props, rates))), ",")
		println(prop_rate)
	end
end


############################################
main()

