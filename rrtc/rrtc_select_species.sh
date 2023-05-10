#! /bin/bash


#####################################################
while read line; do ! grep $line ../scm.trees-* >/dev/null && echo $line; done < species.list;  nw_prune -vf ../scm.trees-* species.list  > scm.pruned.trees; [ -f replace.sed ] && sed -i -f replace.sed scm.pruned.trees; time for i in marginal joint; do Rscript ~/LHW-tools/scm/plotMpState.R -t scm.pruned.trees -o asr.pdf --$i | sponge $i.out; ruby ~/LHW-tools/scm/convert_joint_marginal_out_to_rtc.rb --$i -i $i.out | sponge $i.scm_out; if [ -f back_replace.sed ]; then sed -i -f back_replace.sed $i.out; sed -i -f back_replace.sed $i.scm_out; fi; done
