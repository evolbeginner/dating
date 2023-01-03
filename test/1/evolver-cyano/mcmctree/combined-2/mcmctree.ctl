          seed = -1
       seqfile = combined.phy
      treefile = species.trees
       outfile = out

         ndata = 1
       seqtype = 0
       usedata = 2 in.BV 1
         clock = 3
       RootAge = <1.0  * safe constraint on root age, used if no fossil for root.

         model = 0    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
         alpha = 0.5
         ncatG = 5

     cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

       BDparas = 1 1 0.1
   kappa_gamma = 6 2      * gamma prior for kappa
   alpha_gamma = 1 1      * gamma prior for alpha

   rgene_gamma = 1 50 1
  sigma2_gamma = 1 10 1

      finetune = 1: 0.1  0.1  0.1  0.01 .5  * auto (0 or 1) : times, musigma2, rates, mixing, paras, FossilErr

         print = 1
        burnin = 5000
      sampfreq = 10
       nsample = 5000

*** Note: Make your window wider (100 columns) before running the program.
