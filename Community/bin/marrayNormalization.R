# marrayNormalizer.R
# This R script (written by Hongxian He) is called by 
# GUS::Community::Plugin::CreateAndInsertRmarrayResults and it performs 
# loess normalization as implemented in the marray package from 
# www.bioconductor.org.
# R CMD BATCH --slave --no-save --output_file=/tmp/loess.Routput --input_file=/tmp/loess.Rinput --smoothing_param=0.3 --maxiter=3 [--print_tip_loess] --ngr=4 --ngc=4 --nsr=22 --nsc=22 

library(marray)

# parsing command line arguments
argin <- commandArgs()

inputFile <- gsub("--input_file=","",grep("--input_file=",argin,value=T))
cat ("Input file: ", inputFile, "\n")

outputFile <- gsub("--output_file=","",grep("--output_file=",argin,value=T))
cat ("Output file: ", outputFile, "\n")

smoothingParam <- gsub("--smoothing_param=","",grep("--smoothing_param=",argin,value=T)) 
smoothingParam <- as.numeric(smoothingParam)

printTip <- grep("--print_tip_loess",argin)

ngr <- gsub("--ngr=","",grep("--ngr=",argin,value=T))
ngc <- gsub("--ngc=","",grep("--ngc=",argin,value=T))
nsr <- gsub("--nsr=","",grep("--nsr=",argin,value=T))
nsc <- gsub("--nsc=","",grep("--nsc=",argin,value=T))
ngr <- as.numeric(ngr)
ngc <- as.numeric(ngc)
nsr <- as.numeric(nsr)
nsc <- as.numeric(nsc)


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

if (any(printTip)) {
  norm.data <- maNorm(data, norm="printTipLoess", span=smoothingParam)
} else {
  norm.data <- maNorm(data, norm="loess", span=smoothingParam)
}

# write to output
write.table(cbind(element.ids,maM(norm.data)), file=outputFile, col.names=c("row_id","float_value"), row.names=F,sep="\t", quote=F)
# header: row_id float_value

