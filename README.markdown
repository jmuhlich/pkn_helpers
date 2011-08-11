# Prior Knowledge Network (PKN) helpers

Useful scripts for processing Prior Knowledge Networks.  For more information
see [Saez-Rodriguez 2011][jsr2011].

## graphml2dot.pl

Converts Promot/CellNetOptimizer GraphML and Cytoscape XGMML graphs into a
GraphViz .dot format, overlaying edge weights and colors from a separate
text-delimited file.  Retains layout of the graph nodes and edge styles as
specified in the original XML file.

Figure 4 and supplemental figure 7 in [Saez-Rodriguez 2011][jsr2011] were
produced using this script.

## References

1. Saez-Rodriguez J, Alexopoulos L, Zhang M, Morris MK, Lauffenburger DA, and
Sorger PK. [Comparing signaling networks between normal and transformed
hepatocytes using discrete logical models][jsr2011]. Cancer Res 2011; epub
ahead of print.

[jsr2011]: http://dx.crossref.org/10.1158/0008-5472.CAN-10-4453 "Saez-Rodriguez 2011"

