## 1

The file DBI31.xlsx is a master plate for the shRNA constructs, and already has a modification: the gene symbol has been added a number (_#) to distinguish different constructs that are targeting the same gene.

Then you have the barcode list:

DBI31.xlsx

## 2

With all that plus the assay map/timeline (2017814_Screen timeline.xlsx): 

20160928_Barcode_list_seq.ods

You can generate the YAML file, together with the target gene details (still need to find those).

## 3

So you run the counts pipeline, and import the output to an excel file and calculate the bias as in some of the sheets of the 20180327_HATTAT_s2_analysis.xlsx file:

20180327_HATTAT_s2_analysis.xlsx 

## 4

Meanwhile, there is the following:

The file 20161108_Pilot_shRNA_plate_DBI31_mod.xlsx is a modified version of the DBI31.xlsx, that has the visual classification of the wells (NC==No Cells, VL==Very Low, etc). This is added to the final .csv file, that is going to be used to generate the ridge plots

20161108_Pilot_shRNA_plate_DBI31_mod.xlsx

## 5

With all the pervious, you should be able to construct the .csv used for the ridge plots:

20180306_DBI31_...csv