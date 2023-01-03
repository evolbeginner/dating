#! /bin/bash

euk_tree=`sed '$!d' $2 | sed 's/;//g'`


if grep 'Dictyostelium_discoideum.\+Andalucia_godoyi' $1 > /dev/null; then
	sed "s/((((Dictyostelium_discoideum.\+Andalucia_godoyi))/$euk_tree/" $1 | sed "s/''/'/g"
	#sed "s/((((Dictyostelium_discoideum.\+Andalucia_godoyi)[^)]\+))/$euk_tree/" $1 | sed "s/''/'/g"
elif grep 'Andalucia_godoyi.\+Acanthamoeba_castellanii' $1 >/dev/null; then
	sed "s/((Andalucia_godoyi.\+Acanthamoeba_castellanii)[^)]\+)[^)]\+))/$euk_tree/" $1 | sed "s/''/'/g"
fi


#sed 's/((Andalucia_godoyi.\+Acanthamoeba_castellanii)))/((Andalucia_godoyi,((((((Arabidopsis_thaliana,Oryza_sativa)"G(170.687459888945,74.0218991014647)",Physcomitrella_patens)"G(918.580568348798,187.750186008621)",Ostreococcus_tauri)"G(337.824771700888,31.6930320659684)",((Chondrus_crispus,Porphyra_umbilicalis)"G(113.876521531579,17.2404419368863)",Cyanidioschyzon_merolae)"G(422.048085030082,41.1757724851824)")"G(344.493910754472,26.3443747454719)",Cyanophora_paradoxa)"G(327.071456115657,24.311228024595)",((Phytophthora_infestans,Thalassiosira_pseudonana)"G(107.533473985893,11.0966544251946)",((Oxytricha_trifallax,Paramecium_tetraurelia)"G(62.3330011274483,8.78108079641399)",Symbiodinium_minutum)"G(199.497414909559,15.9526682087559)")"G(289.018489044457,21.1026215433411)")"G(304.992362251703,21.5827962481462)")"G(295.923274930584,20.1447399503231)",(((Salpingoeca_rosetta,(Amphimedon_queenslandica,((Branchiostoma_floridae,(Gallus_gallus,Homo_sapiens)"G(5953.34354816246,1836.58433769547)")"G(545.271982445685,91.4592138863544)",Drosophila_melanogaster)"G(478.393039862636,67.4316257044744)")"G(753.803035615723,87.737606018639)")"G(393.879826946225,36.3113287834988)",(((Pleurotus_ostreatus,Ustilago_maydis)"G(78.6448075524275,13.4691725819143)",Candida_albicans)"G(118.265380642538,14.5745736900252)",Spizellomyces_punctatus)"G(165.158692650556,16.9660719907505)")"G(331.335212095939,25.8537771298509)",((Dictyostelium_discoideum,Polysphondylium_pallidum)"G(27.5715393577388,5.44990518376328)",Acanthamoeba_castellanii)"G(256.558945921877,19.8337085139821)")"G(291.083546694862,20.0391015564124)")"G(301.325671539462,20.1090138741138)"/' $1
