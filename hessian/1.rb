#! /bin/env ruby

require_relative 'runHessianSim'


outdir = '1/age-10/root/dating/LG+C20+G+bs_inBV.pbs'
extract_hessian(File.join(outdir,'combined','in.BV'), File.join(outdir,'combined','hessian'))

