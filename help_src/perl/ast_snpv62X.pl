#! perl  
####################################################################
# v.6.2  	1/4/17	Sasha - more diagnostics in DEBUG
# v.6  	12/30/16	Sasha - deal with the short R1 read (barcode only; not alignable to genome)
# v.5.1	12/26/16	Sasha - unified YAML5.0 with UMI branch
# v.5.0	12/3/16	Sasha - new output format, per line
# v.0.10	9/30/16	Sasha - YAML4.5; additional spacer
# v.0.9	8/26/16	Sasha - multiple updates to YAML (v.4.0)
# v.0.8	8/16/16	Sasha - use revcomp (YAML v.3.1)
# v.0.7	8/2/16	Sasha - SNP counting
# v.0.6	6/24/16	Sasha - clean up code; output libraries in sorted order
# v.0.5	3/24/16	Sasha - use YAML
# v.0.4	3/10/16	Sasha - cleaned up code a bit
# v.0.3	3/7/2016	Sasha - arbitrary barcode pairs
# v.0.2	3/6/2016	Sasha - make more parameters
# v.0.1 	3/4/2016	Sasha - initial version
####################################################################
#### input: SAM file for specific gene region/target
#### IMPORTANT: sorted by the read# (so that the R1 and R2 reads are next to each other)
#### output: table of SNPs per 
####################################################################

use YAML::XS 'LoadFile';
use feature ":5.10";
no warnings 'experimental';

my $REVERSE = 0x10;        ## in FLAG, 5th bit is set if revcomp
my $SUPPLEMENTARY = 0x800;	## in FLAG, this is set for added short read in as2.pl

### load params from command line ###############################
$yaml=shift; ### yaml file
unless ($yaml ne ''){die "$0: <yaml_file> is needed\n"};  ## TODO: better error checking for YAML loading
my $config = LoadFile($yaml);
## TODO: check success of yaml loading

my $infile =shift;  ## sorted SAM file for this gene
my $gene_name=shift;
my $timestamp=shift;

# access general yaml content ###########################################
$ExpectedConfigVersion = "5.0";
$ConfigVersion=$config->{version};
unless($ExpectedConfigVersion eq $ConfigVersion) {die "$0: YAML config file version $ConfigVersion. Expecting $ExpectedConfigVersion\n"};

$DEBUG = $config->{diagnostics}->{DEBUG};
if ($config->{diagnostics}->{OnlyOutputDiagnostics} eq "yes") {$OnlyOutputDiagnostics=1}
else {$OnlyOutputDiagnostics=0};
if ($config->{diagnostics}->{TryRevComp} eq "yes") {$TryRevcomp=1}
else {$TryRevcomp=0};


$globalTLENmin=$config->{step2}->{insert_len_min};
$globalTLENmax=$config->{step2}->{insert_len_max};
#~ $grabPattern = $config->{step2}->{grabPattern};
#~ $umiPattern=$config->{step2}->{umiPattern};
#~ $T2 = $config->{step2}->{T2}; 
#~ $sam=$config->{output}->{sam}; ## for name only

$MAPQmin=$config->{step2}->{minimal_MAPQ}; # min quality -- global
$amplicon_size_tolerance=$config->{step2}->{amplicon_size_tolerance};
$SNPnoUMIpattern=$config->{step2}->{SNPnoUMIpattern};
$T2_small=$config->{step2}->{T2_small};


## access gene-specific YAML content #####################################
$flankLeft	=	$config->{genes}->{$gene_name}->{SNPFlank_left};
#~ $flankRight=	$config->{genes}->{$gene_name}->{SNPFlank_right};

#### This is temporary: !!!!!!!!!!!!!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		$snp = $flankLeft;
		$snp_revcomp = revcomp($snp);

## The following doesn't matter for the short R1
$size=$config->{genes}->{$gene_name}->{amplicon_size};
$TLENmin=$size - $amplicon_size_tolerance; 
   if($TLENmin < $globalTLENmin){$TLENmin=$globalTLENmin};
$TLENmax=$size + $amplicon_size_tolerance;
   if($TLENmax > $globalTLENmax){$TLENmax=$globalTLENmax};
   

# load samples_barcodes ###############################################
for (sort keys %{$config->{samples_barcodes}}) {
	$descr=$_; $bc=$config->{samples_barcodes}->{$_};
	push (@samples_barcodes,[$descr, $bc]);
	$expected_barcodes{$bc}++; ## for counting unexpected bcodes
}

#### Now deal with the SAM file  #########################################
open(S,"<$infile") or die("$0: cannot open $infile\n");
### init counters
$read_pairs=$QNAME_mismatch=$TLEN_out_of_bounds=$MAPQ_low=$T2_not_found=$bc_mismatch=$accum=$QNAME_mismatch=$TLEN_same_sign=$unknown_bc=$flank_not_found=0;

while(<S>){
	if(/^@/){next};
	($r2{QNAME}, $r2{FLAG}, $r2{RNAME}, $r2{POS}, $r2{MAPQ}, $r2{CIGAR}, $r2{RNEXT}, $r2{PNEXT}, $r2{TLEN}, $r2{SEQ}, $r2{QUAL}) = split;
	$_=<S>;	
	($r1{QNAME}, $r1{FLAG}, $r1{RNAME}, $r1{POS}, $r1{MAPQ}, $r1{CIGAR}, $r1{RNEXT}, $r1{PNEXT}, $r1{TLEN}, $r1{SEQ}, $r1{QUAL}) = split;
	
	$read_pairs++;

# TODO: deal with CIGAR here for add'l filtering?
# CIGAR string should contain S and M fields, but no I or D

## IDs should be identical for R1 and R2
# 	if($r1{QNAME} ne $r2{QNAME}) {$QNAME_mismatch++; $_=<S>; next}; ## <-- very crappy.  TODO: change R1/R2 matching correction so that it doesn't skip data
# 
# ### ~~~ DEAL with short R1
	# 	if 	(($r2{FLAG}+0) & $SUPPLEMENTARY){  ## this is the short read added in asymmetric process
	# 		## the long read is mapped in revcomp orientation?  revcomp it back
	# 	    if (($r1{FLAG}+0) & $REVERSE) {$r1{SEQ} = revcomp($r1{SEQ});}
	# 	}
	# 	elsif	(($r1{FLAG}+0) & $SUPPLEMENTARY){  ## no, this one is short
	# 	    if (($r2{FLAG}+0) & $REVERSE) {$r2{SEQ} = revcomp($r2{SEQ});}  
	# 	 
	# 	}
	# 	else{ print STDERR "$0: No Supp flag set:\n$r1{FLAG}   $r2{FLAG}\n"};
	# 
	if (($r1{FLAG}+0) & $REVERSE) {$r1{SEQ} = revcomp($r1{SEQ});}
	if (($r2{FLAG}+0) & $REVERSE) {$r2{SEQ} = revcomp($r2{SEQ});}
	
	#~ if(($r1{MAPQ} < $MAPQmin) or ($r2{MAPQ} < $MAPQmin) ){$MAPQ_low++; next};
	if(($r2{MAPQ} < $MAPQmin) ){$MAPQ_low++; next};  ### TODO: this depends on knowing that r2 is before r1



	### now see what the barcodes and SNPs are #########################

	
	($r1{spacer}, $r1{bc}, $r1{tail}, $r1{rest}) = unpack($SNPnoUMIpattern, $r1{SEQ});
	($r2{spacer}, $r2{bc}, $r2{tail}, $r2{rest}) = unpack($SNPnoUMIpattern,  $r2{SEQ});
	
	## Identify what the barcode set is
	my $theBarCodePair=&getBarcode($r1{bc}, $r2{bc});
	if($theBarCodePair eq "none"){$T2_not_found++; next};
	unless(exists($expected_barcodes{$theBarCodePair})){$unknown_bc++; next};

	$all_processed++; ### This is counting all assessed read pairs, NOT including those with "wrong" barcodes
	### now do the "genotyping" ###############################
	
	if(	$r2{rest}=~m/$snp(.)/gi){$gt=uc($1)}
	elsif($r1{rest}=~m/$snp(.)/gi){$gt=uc($1)}
	else						{$gt="X"};	
	
	given ($gt) {
	    when ("A") {$data{$theBarCodePair}{A}++}
	    when ("C") {$data{$theBarCodePair}{C}++}
	    when ("G") {$data{$theBarCodePair}{G}++}
	    when ("T") {$data{$theBarCodePair}{T}++}
	    when ("N") {$data{$theBarCodePair}{N}++}
	    when ("X") {$data{$theBarCodePair}{X}++; $flank_not_found++}  ### NO SNP flank found
	    #~ next }
	    default {next};
	};

	if($TryRevcomp){
	    if($r1{rest}=~m/(.)$snp_revcomp/gi){$gt=$1}
	    elsif($r2{rest}=~m/(.)$snp_revcomp/gi){$gt=$1}
	    else{$gt="x"};	
	    unless($gt eq "x"){{$dataRC{$theBarCodePair}{match}++}};
	
	    $gt=uc($gt); 
	    $all_genotypedRC++; ### This is counting all assessed read pairs, including those with "wrong" barcodes
	    given ($gt) {
		when ("A") {$dataRC{$theBarCodePair}{A}++}
		when ("C") {$dataRC{$theBarCodePair}{C}++}
		when ("G") {$dataRC{$theBarCodePair}{G}++}
		when ("T") {$dataRC{$theBarCodePair}{T}++}
		when ("N") {$dataRC{$theBarCodePair}{N}++}
		when ("X") {$dataRC{$theBarCodePair}{X}++}  ### NO SNP flank found
		#~ next }
		default {next};
	    };
	}
}

################################################
# output results -- all on one line per barcode; the following fields:
#~ 1  	timestamp
#~ 2 	gene_id
#~ 3	sample_id
#~ 4	count_a
#~ 5	count_t
#~ 6	count_g
#~ 7	count_c
#~ 8	count_n
#~  9	count_no_flank
#~ 10	log
################################################
{my $i;
 $bc_mismatch=0;
 # loop through and print output
 for($i=0; $i<=($#samples_barcodes); $i++){
     $output_line="$timestamp\t$gene_name\t$samples_barcodes[$i][0]";

     if (exists($data{$samples_barcodes[$i][1]})){
	 ## count
	 unless ($OnlyOutputDiagnostics){
	     if (exists($data{$samples_barcodes[$i][1]}{A})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{A}");$output_line.=$tmp} else {$output_line.="\t0"};
	     if (exists($data{$samples_barcodes[$i][1]}{T})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{T}");$output_line.=$tmp} else {$output_line.="\t0"};
	     if (exists($data{$samples_barcodes[$i][1]}{G})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{G}");$output_line.=$tmp} else {$output_line.="\t0"};
	     if (exists($data{$samples_barcodes[$i][1]}{C})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{C}");$output_line.=$tmp} else {$output_line.="\t0"};
	     if (exists($data{$samples_barcodes[$i][1]}{N})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{N}");$output_line.=$tmp} else {$output_line.="\t0"};
	     if (exists($data{$samples_barcodes[$i][1]}{X})){$tmp=sprintf ("\t$data{$samples_barcodes[$i][1]}{X}");$output_line.=$tmp} else {$output_line.="\t0"};
	 };       
	 $accum +=	$data{$samples_barcodes[$i][1]}{A}+
	     $data{$samples_barcodes[$i][1]}{T}+
	     $data{$samples_barcodes[$i][1]}{C}+
	     $data{$samples_barcodes[$i][1]}{G};
     }
     else { ### no data found
	 unless ($OnlyOutputDiagnostics){$output_line.="\t0\t0\t0\t0\t0\t0";}
	 $bc_mismatch++;}

     ### now print the assembled line
     print "$output_line\n";
 }
}	
##################
if($TryRevcomp){
print "trying RevComp SNP $gene_name [x]$snp_revcomp\n";
} ## end of TryRevcomp branch


if($DEBUG){
	
	if($all_genotyped == 0){$all_genotyped=-1};
	if($read_pairs == 0){$read_pairs=-1};
 
	print "From $infile\n$read_pairs\tread pairs\n";
			$sb=$#samples_barcodes+1;	
	print "$sb barcodes declared; of these, $bc_mismatch had no reads found\n";
	print "~~~~~~~~~ Filtered out:\n";
	
	print  "$QNAME_mismatch\tunpaired reads\n$MAPQ_low\tMAPQ<$MAPQmin\n$TLEN_out_of_bounds\tinsert length out of bounds ($TLENmin..$TLENmax)\n";
	print  "$TLEN_same_sign\treads aligned same direction\n$T2_not_found\tT2_not_found\n";
				$tmp=sprintf("%.1f", 100*$unknown_bc/$read_pairs); 
	print "$unknown_bc	reads with unexpected barcodes ($tmp% of all)\n";			
	
	
	print "~~~~~~~~~ Processed:\n";

			$tmp=sprintf("%.1f", 100*$all_processed/$read_pairs);	
	print "$all_processed	Read pairs that passed all the above filters ($tmp% of total)\n";
			if($all_processed == 0) {$all_processed=-1};
			$sb1=$sb-$bc_mismatch; 		$tmp=sprintf("%.1f", 100*$accum/$all_processed); 
	print  "$accum	Total genotype calls ($tmp% of passed) among $sb1 of declared barcodes with reads\n"; 
			$tmp=sprintf("%.1f", 100*$flank_not_found/$all_processed);
	print "$flank_not_found	SNP flank not found ($tmp% of passed)\n\n";

	if($TryRevcomp){
		if($all_genotypedRC == 0){$all_genotypedRC=-1};
		if($read_pairsRC == 0){$read_pairsRC=-1};

		print "~~~~~~~ RevComp for SNP flank\n";	
		$tmp=sprintf("%.1f", 100*$all_genotypedRC/$read_pairs);	
		print "$all_genotypedRC	Read pairs that passed all the above filters ($tmp% of total)\n";
		
		$tmp=sprintf("%.1f", 100*$accumRC/$all_genotypedRC); 
		print  "$accumRC	Total genotype calls ($tmp% of passed) for declared barcodes with reads\n\n";
	}
}

###############################################################
###############################################################
###############################################################

sub revcomp {      #from http://www.perlmonks.org/?node_id=197793
  my $dna = shift; 
  my $revcomp = reverse($dna);
  $revcomp =~ tr/ACGTacgt/TGCAtgca/;
  return $revcomp;
}

sub getBarcode{  ## TODO: refactor. This sub uses global variables
	my($seq1, $seq2)=@_;
	
	my $answer="none";
## Which tail is T1/T2? ###################################################
			### match to tail T2	
	if($r2{tail} =~ m/$T2_small/) {
		$answer = "$seq2"."_"."$seq1" ;}
	elsif ($r1{tail} =~ m/$T2_small/) {
		$answer = "$seq1"."_"."$seq2" ;}
	#~ die ("\nBREAK\nr1 tail = $r1{tail}\nr2 tail = $r2{tail}\n");
	return $answer;	
}

__END__
################################################
# how many reads were rejected because they didn't have expected barcodes?
my $unexpected_bc_reads=0;
#~ if($DEBUG){
	foreach my $barcode (keys %data){
		unless(exists($expected_barcodes{$barcode})){
			foreach my $gt (keys %{$data{$barcode}}){
				$unexpected_bc_reads+=($data{$barcode}{$gt});
			};
		}
	}	
#~ }


################################################	
