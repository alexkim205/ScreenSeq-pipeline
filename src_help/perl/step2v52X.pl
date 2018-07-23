#						sped up sort
# v.5.1	12/19/16	Sasha	merged UMI and SNP branches
# v.5.0	12/3/16	Sasha	updated to invoke new output & dump YAML file
# v.0.5	8/26/16	Sasha	updated to deal with (YAML 4.0)
# v.0.4	8/1/16	Sasha	more yaml changes; yaml QC
# v.0.3	6/24/16	Sasha 	change yaml syntax: UMI to yes/no; add SNP definitions  
# v.0.2	6/24/16	Sasha 	report UMI or not 

use YAML::XS 'LoadFile';
use feature 'say';


$yaml=shift; ### yaml file
unless ($yaml ne ''){die "Usage: $0 <yaml_file>\n"};
my $config = LoadFile($yaml);

# check yaml version ###########################################
$ExpectedConfigVersion = "5.0";
$ConfigVersion=$config->{version};
unless($ExpectedConfigVersion eq $ConfigVersion) {die "$0: YAML config file version $ConfigVersion. Expecting $ExpectedConfigVersion\n"};

# access yaml content
$dir=$config->{alignment}->{SAM_location};
$sam=$config->{alignment}->{SAM_name_base};
$BAM="$dir"."/"."$sam".".sorted.bam";

$DEBUG = $config->{diagnostics}->{DEBUG};
$leave_sam=$config->{diagnostics}->{leave_SAM};
$use_existing_SAM=$config->{diagnostics}->{use_existing_sorted_SAM};
if(exists($config->{diagnostics}->{SAMsubsampleFraction})){
    $SAMsubsampleFraction=$config->{diagnostics}->{SAMsubsampleFraction}
} else {$SAMsubsampleFraction=0};


$OUT=$config->{output}->{result};
#~ $MINflankLength=$config->{step2}->{MINflankLength};

$scripts=$config->{scripts}->{location};
$SNP_SCRIPT=$config->{scripts}->{SNP_script};
$UMI_SCRIPT=$config->{scripts}->{UMI_script};


### SNP or UMI?
$isUMIexpt=$config->{experiment}->{UMI};
$isSNPexpt=$config->{experiment}->{SNP};
# check that only one is selected
if  	(($isUMIexpt eq 'yes')&&($isSNPexpt eq 'no')) {$SCRIPT=$UMI_SCRIPT }
elsif	(($isSNPexpt eq 'yes')&&($isUMIexpt eq 'no')) {$SCRIPT=$SNP_SCRIPT} 
else {die ("$0 -- please define if SNP or UMI should be counted\n")};
### check that configuration is loaded
unless (	defined($sam) &&
		defined($dir) &&
		defined($scripts) &&
		defined($isUMIexpt) &&
		defined($isSNPexpt)
    ) {die "ERROR: some variables not defined in YAML file $yaml\npossible syntax issue\n"};

#############################################################################

# now copy the yaml file to $OUT
unless(defined($config->{output}->{output_yaml}) &&
       ($config->{output}->{output_yaml}) eq 'no')
{&dump_yaml_file($yaml, $OUT);}

### header
say "Results will be in $OUT";
my $timestamp = getLoggingTime();
$timestamp .= " $SCRIPT $yaml";
`echo "## $timestamp" >> $OUT`;

#### do the work
for (sort keys %{$config->{genes}}) {
    $gname=$_; 
    $pos=$config->{genes}->{$_}->{position};
		
    if($DEBUG){print STDERR "$gname\t"};
    if($DEBUG){print STDERR "SAM: slice ... "};
			
    #~ if($SAMsubsampleFraction){
    #~ $ans=`samtools view -s 0.$SAMsubsampleFraction $BAM $pos -o $gname.sam`unless ($use_existing_SAM);    
    #~ } else{
    #~ $ans=`samtools view $BAM $pos -o $gname.sam` unless ($use_existing_SAM);
    #~ };
    if($SAMsubsampleFraction){
	$ans=`samtools view -u -s 0.$SAMsubsampleFraction $BAM $pos -b -o $gname.bam` unless ($use_existing_SAM);    
    } else{
	$ans=`samtools view -u $BAM $pos -b -o $gname.bam`  unless ($use_existing_SAM);
    };		
		
    ##### samtools view -b $BAM $pos  -o $gname.bam
    ##### samtools sort  $gname.bam -o $gname.srt1.sam -n 
    #~ $ans=`samtools view -h $BAM $pos -o $gname.sam`;  ## for samtools sort
		
    if($DEBUG){print STDERR "sort ... "};
    $ans=`samtools sort -n  $gname.bam -o $gname.srt1.sam` unless ($use_existing_SAM);  
    #~ $ans=`sort -k1,2 $gname.sam > $gname.srt1.sam` unless ($use_existing_SAM);  ## <<< this is VERY slow
		
    if($DEBUG){print STDERR "counting ... "};
		    
    ### now output 1st field as timestamp
    #~ `printf "field1 = $timestamp\t" >> $OUT`;		 
    $ans=`perl $scripts/$SCRIPT $yaml $gname.srt1.sam $gname $timestamp >> $OUT`;
    if($DEBUG){print STDERR "\n"};
		
    ## TODO check return status
		
    unless ($use_existing_SAM) {$ans=`rm $gname.bam` ;  };
    unless ($leave_sam) {$ans=`rm $gname.srt1.sam`} ;
}
`echo "" >> $OUT`;


################################
sub dump_yaml_file{
    my ($yaml, $OUT)=@_;
    open (Y,"$yaml") or die ("Cannot open $yaml\n");
    open (O,">>$OUT")  or die ("Cannot open $OUT to write header\n");

    print O "## Results are after YAML file copy :\n";
    print O "##########################################################\n";
    print O "## The following is a commented out copy of YAML file used to produce this results file: $yaml\n";
    print O "## Commented lines in the original YAML file are skipped below\n";
    print O "## To avoid printing out this file as a header, uncomment \"output_yaml: no\" in the config\n";
    print O "## start of YAML file ########################################################\n";
	
    while(<Y>){
	if(/$\#/){next;}
	else {print O "#$_"}
    }
    print O "## end of YAML file ########################################################\n";
    print O "## what follows is the actual output\n";
    print O "#timestamp	gene_id	sample_id	count_a	count_t	count_g	count_c	count_n	count_no_flank	log \n"; ### TODO: this line only applies to SNP branch
	
    close(Y);
    close(O);
    return 0;
};

sub getLoggingTime { ## from http://stackoverflow.com/questions/12644322/how-to-write-the-current-timestamp-in-a-file-perl
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $nice_timestamp = sprintf ( "%04d_%02d_%02d_%02d:%02d:%02d",
                                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $nice_timestamp;
}
