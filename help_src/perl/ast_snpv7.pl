#! perl  
####################################################################
# v.7		6/30/17	Sasha - integration of UMI and SNP analysis
#					   yaml config updated to v.6.0
#					   TryRevComp removed
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
$ExpectedConfigVersion = "6.0";
$ConfigVersion=$config->{version};
unless($ExpectedConfigVersion eq $ConfigVersion) {die "$0: YAML config file version $ConfigVersion. Expecting $ExpectedConfigVersion\n"};

$DEBUG = $config->{diagnostics}->{DEBUG};
if ($config->{diagnostics}->{OnlyOutputDiagnostics} eq "yes") {$OnlyOutputDiagnostics=1}
else {$OnlyOutputDiagnostics=0};

$MAPQmin=$config->{step2}->{minimal_MAPQ}; # min quality -- global
$LongReadSplitPattern=$config->{step2}->{LongReadSplitPattern};
$ShortReadSplitPattern=$config->{step2}->{ShortReadSplitPattern};

### TODO: the following will not be needed ~~~~~~~~~~~~~~~~~
$globalTLENmin=$config->{step2}->{insert_len_min};
$globalTLENmax=$config->{step2}->{insert_len_max};
$amplicon_size_tolerance=$config->{step2}->{amplicon_size_tolerance};
$SNPnoUMIpattern=$config->{step2}->{SNPnoUMIpattern};
$T2_small=$config->{step2}->{T2_small};
if ($config->{diagnostics}->{TryRevComp} eq "yes") {$TryRevcomp=1}
else {$TryRevcomp=0};

$flankLeft	= $config->{genes}->{$gene_name}->{SNPFlank_left};
#### This is temporary: !!!!!!!!!!!!!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		$snp = $flankLeft;
		#~ $snp_revcomp = revcomp($snp);
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## access gene-specific YAML content #####################################
###SNP: TAAAACAAAAT[N]TAGACTTACT
$SNP	=$config->{genes}->{$gene_name}->{SNP};
#~ $SNP="TTGGTTTAAAACAAAAT[A/T]TAGACTTACTTGTCTA";
	if($SNP =~ m/(\w+)\[\w+\/\w+\](\w+)/gi)
		{$SNPleftFlank=$1; $SNPrightFlank=$2;}
	else {die "\nError in $0:\n problem with SNP parsing >$SNP<\n"};
	
	#~ die "\n$SNP\n$SNPleftFlank $SNPrightFlank\n";

## The following doesn't matter for the short read (R1)
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
$read_pairs=
#~ $TLEN_out_of_bounds=
$MAPQ_low=
$T2_not_found=
$bc_mismatch=
$accum=
$extraUMIaccum=
$QNAME_mismatch=
#~ $TLEN_same_sign=
$unknown_bc=
$flank_not_found=0;

while(<S>){
	if(/^@/){next};
	($r2{QNAME}, $r2{FLAG}, $r2{RNAME}, $r2{POS}, $r2{MAPQ}, $r2{CIGAR}, $r2{RNEXT}, $r2{PNEXT}, $r2{TLEN}, $r2{SEQ}, $r2{QUAL}) = split;
	$_=<S>;	
	($r1{QNAME}, $r1{FLAG}, $r1{RNAME}, $r1{POS}, $r1{MAPQ}, $r1{CIGAR}, $r1{RNEXT}, $r1{PNEXT}, $r1{TLEN}, $r1{SEQ}, $r1{QUAL}) = split;
	
## IDs should be identical for R1 and R2
	if($r1{QNAME} ne $r2{QNAME}) {$QNAME_mismatch++; $_=<S>; next}; 
	##  very crappy.  TODO: change R1/R2 matching correction so that it doesn't skip data

	$read_pairs++;


### ~~~ DEAL with short R1
	if	(($r1{FLAG}+0) & $SUPPLEMENTARY){  ## no, this one is short
		if (($r2{FLAG}+0) & $REVERSE) {$r2{SEQ} = revcomp($r2{SEQ});}  ### ????? why?
	elsif (($r2{FLAG}+0) & $SUPPLEMENTARY){  ## this is the short read added in asymmetric process
		## the long read is mapped in revcomp orientation?  revcomp it back
		if (($r1{FLAG}+0) & $REVERSE) {$r1{SEQ} = revcomp($r1{SEQ});}
		}	 
	}
	else{ print STDERR "$0: No Supp flag set:\n$r1{FLAG}   $r2{FLAG}\n"};
	
	if(($r2{MAPQ} < $MAPQmin) ){$MAPQ_low++; next};  ### TODO: this depends on knowing that r2 is before r1

### now see what the barcodes, UMIs, and SNPs are #########################
### TODO: the following will not be needed ~~~~~~~~~~~~~~~~~	

## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 #~ LongReadSplitPattern: A7 A6 A18 A*
  #~ ShortReadSplitPattern: A7 A6 A18 A18 A16 A*
 
   ## short read (with UMI)
	($r1{spacer}, $r1{bc}, $r1{tail}, $r1{tailB}, $r1{UMI}, $r1{rest}) = unpack($ShortReadSplitPattern, $r1{SEQ});
   
   ## long read
	($r2{spacer}, $r2{bc}, $r2{tail}, $r2{rest}) = unpack($LongReadSplitPattern,  $r2{SEQ});
   
## Identify what the barcode set is
	my $theBarCodePair=&getBarcode($r1{bc}, $r2{bc});
	if($theBarCodePair eq "none"){$T2_not_found++; next};
	unless(exists($expected_barcodes{$theBarCodePair})){$unknown_bc++; next};

	$all_processed++; ### This is counting all assessed read pairs, NOT including those with "undeclared" barcodes

## Skip if UMI already encountered (for given barcode and gene)	
	if(exists($data{$theBarCodePair}{$r1{UMI}}))
		{$data{$theBarCodePair}{extraUMIs}++;
		next;
		}
		else {$data{$theBarCodePair}{$r1{UMI}}=1;  
		};

### now do the "genotyping" (only if unique UMI) ###############################

	
	#~ if(	$r2{rest}=~m/$snp(.)/gi){$gt=uc($1)}
	if(	$r2{rest}=~m/$SNPleftFlank(.)$SNPrightFlank/gi)
		{$gt=uc($1)}
	else	{$gt="X"};	
	
	given ($gt) {
		when ("A") {$data{$theBarCodePair}{A}++}
		when ("C") {$data{$theBarCodePair}{C}++}
		when ("G") {$data{$theBarCodePair}{G}++}
		when ("T") {$data{$theBarCodePair}{T}++}
		when ("N") {$data{$theBarCodePair}{N}++}
		when ("X") {$data{$theBarCodePair}{X}++; $flank_not_found++}  ### NO SNP flank found
		default {next};
	};
}
# we are done reading data and counting, now let's print some output


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
			if (exists($data{$samples_barcodes[$i][1]}{X})){$tmp=sprintf ("\t\{$data{$samples_barcodes[$i][1]}{X}\}");$output_line.=$tmp} else {$output_line.="\t{0}"};
			if (exists($data{$samples_barcodes[$i][1]}{extraUMIs})){$tmp=sprintf ("\t<$data{$samples_barcodes[$i][1]}{extraUMIs}>");$output_line.=$tmp} else {$output_line.="\t<0>"};
			
		};       
		$accum +=	$data{$samples_barcodes[$i][1]}{A}+
					$data{$samples_barcodes[$i][1]}{T}+
					$data{$samples_barcodes[$i][1]}{C}+
					$data{$samples_barcodes[$i][1]}{G};
					
		$extraUMIaccum += 	$data{$samples_barcodes[$i][1]}{extraUMIs};		
	       }
	else { ### no data found
		unless ($OnlyOutputDiagnostics){$output_line.="\t0\t0\t0\t0\t0\t{NA}\t<NA>";}
		$bc_mismatch++;}

	### now print the assembled line
	print "$output_line\n";
	}
}	
##################
#~ if($TryRevcomp){
#~ print "trying RevComp SNP $gene_name [x]$snp_revcomp\n";
#~ } ## end of TryRevcomp branch


if($DEBUG){
	################################################
	if($all_genotyped == 0){$all_genotyped=-1};
	if($read_pairs == 0){$read_pairs=-1};
	
	print "#\n#	~~~~~~~~~ Debug info. To disable this output, set diagnostics:DEBUG to 0\n";
	print "#	From	$infile\n#	$read_pairs	read pairs\n";
			$sb=$#samples_barcodes+1;	
	print "#	$sb	barcodes declared; of these, $bc_mismatch had no reads found\n";

	print "#	~~~~~~~~~ Filtered out:\n";
	print "#	$QNAME_mismatch	unpaired reads\n";
	print "#	$MAPQ_low	MAPQ<$MAPQmin\n";
	#~ print  "#	$TLEN_same_sign\treads aligned same direction\n";
	print "#	$T2_not_found	T2_not_found\n";
				$tmp=sprintf("%.1f", 100*$unknown_bc/$read_pairs); 
	print "#	$unknown_bc	reads with undeclared barcodes ($tmp% of $read_pairs)\n";			
	
	print "#	~~~~~~~~~ Processed:\n";
	if($all_processed == 0) {$all_processed=-1};
	if($accum == 0) {$accum=-1};
	
	
			$tmp=sprintf("%.1f", 100*$all_processed/$read_pairs);	
	print "#	$all_processed	Read pairs that passed all the above filters ($tmp% of $read_pairs)\n";
	
			$sb1=$sb-$bc_mismatch; 		
			$tmp=sprintf("%.1f", 100*$accum/$all_processed); 
	print "#	$accum	<<<<< Total unique genotype calls ($tmp% of $all_processed) among $sb1 of declared barcodes with reads\n";
	
			$tmp=sprintf("%.1f", 100*$flank_not_found/$accum);
	print "#	{$flank_not_found}	SNP flank not found ($tmp% of $accum)	~~~ $SNP\n";

			$tmp=sprintf("%.1f", 100*$extraUMIaccum/$all_processed);
	print "#	<$extraUMIaccum>	extra UMIs ($tmp% of $all_processed)\n";
	
	print "\n";

	#~ if($TryRevcomp){
		#~ if($all_genotypedRC == 0){$all_genotypedRC=-1};
		#~ if($read_pairsRC == 0){$read_pairsRC=-1};

		#~ print "~~~~~~~ RevComp for SNP flank\n";	
		#~ $tmp=sprintf("%.1f", 100*$all_genotypedRC/$read_pairs);	
		#~ print "$all_genotypedRC	Read pairs that passed all the above filters ($tmp% of total)\n";
		
		#~ $tmp=sprintf("%.1f", 100*$accumRC/$all_genotypedRC); 
		#~ print  "$accumRC	Total unique genotype calls ($tmp% of passed) for declared barcodes with reads\n";
	#~ }
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
