#! /bin/env perl


#####################################################################
use strict;
use v5.10;
use Getopt::Long;


#####################################################################
my $convert = '';
my $treefile = '';

my $tree = '';


#####################################################################
GetOptions( "convert=i" => \$convert,   # numeric
            "tree=s" => \$treefile
    )
or die("Error in command line arguments\n");


#####################################################################
sub convert_1{
    my ($str) = @_;
    $str =~ s/["']/\&/g;
    $str =~ s/[(]/!/g;
    $str =~ s/[)]/@/g;
    $str =~ s/[,]/COMMA/g;
    return($str)
}

sub convert_2{
    my ($str) = @_;
    $str =~ s/[&]/"/g;
    $str =~ s/[!]/\(/g;
    $str =~ s/[@]/\)/g;
    $str =~ s/COMMA/,/g;
    return($str)
}


#####################################################################
my $tree;
if($treefile eq "-"){
    while(<>){$tree = $_}
}else{
    open(my $fh, '<', $treefile) or die("Can't open \"$treefile\": $!\n");
    while(<$fh>){$tree = $_}
    close $fh;
}


#####################################################################
given($convert){
    when(1){
        $tree =~ s/( ["'] [^"']+ ["'] )/convert_1($1)/xge ;
    }
    when(2){
        $tree =~ s/( [&] [^&]+ [&] )/convert_2($1)/xge ;
    }
}

print($tree);


