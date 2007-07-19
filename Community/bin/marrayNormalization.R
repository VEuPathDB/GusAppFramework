# marrayNormalizer.R
# This R script (written by Hongxian He) is called by 
# GUS::Community::Plugin::CreateAndInsertRmarrayResults and it performs 
# loess normalization as implemented in the marray package from 
# www.bioconductor.org.
# echo 'inputFile="loess.Rinput";outputFile="loess.Routput";smoothingParam=0.3;ngr=4;ngc=4;nsr=22;nsc=22;printTip=T' | cat - $thisScript | R --slave --no-save";  

library(marray)

data <- read.table(inputFile, header=T)
# header: element_id Rf Rb Gf Gb

element.ids <- data[,1]

n.spots <- ngr*ngc*nsr*nsc
if (dim(data)[[1]] != n.spots) { 
   cat("Error: the dimension of data does not match array layout!\n")
   quit
}

layout<-new('marrayLayout', maNgr=ngr, maNgc=ngc, maNsr=nsr, maNsc=nsc, maNspots=n.spots)

mat <- as.matrix(data[,2:5])
row.names(mat) <- data[,1]
data<-new("marrayRaw",maRf=as.matrix(mat[,1]), maRb=as.matrix(mat[,2]), maGf=as.matrix(mat[,3]), maGb=as.matrix(mat[,4]), maLayout=layout)

if (printTip) {
  norm.data <- maNorm(data, norm="printTipLoess", span=smoothingParam)
} else {
  norm.data <- maNorm(data, norm="loess", span=smoothingParam)
}

# write to output
write.table(cbind(element.ids,maM(norm.data)), file=outputFile, col.names=c("row_id","float_value"), row.names=F,sep="\t", quote=F)
# header: row_id float_value

