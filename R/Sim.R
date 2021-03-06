
# simulateDE --------------------------------------------------------------

#' @name simulateDE
#' @aliases simulateDE
#' @title Simulate Differential Expression
#' @description simulateDE is the main function to simulate differential expression for RNA-seq experiments.
#' The simulation parameters are specified with \code{\link{SimSetup}}.
#' The user needs to specify furthermore
#' the number of samples per group, preprocessing, normalisation and differential testing method.
#' There is also the option to consider spike-ins. \cr
#' The return object contains DE test results from all simulations as well as descriptive statistics.
#' The error matrix calculations will be conducted with \code{\link{evaluateDE}}.\cr
#' @usage simulateDE(n1=c(20,50,100), n2=c(30,60,120),
#' sim.settings,
#' DEmethod,
#' normalisation,
#' Preclust=FALSE,
#' Preprocess = NULL,
#' spikeIns=FALSE,
#' NCores=NULL,
#' verbose=TRUE)
#' @param n1,n2 Integer vectors specifying the number of biological replicates in each group. Default values are n1=c(20,50,100) and n2=c(30,60,120).
#' @param sim.settings This object specifies the simulation setup. This must be the return object from \code{\link{SimSetup}}.
#' @param DEmethod A character vector specifying the DE detection method to be used.
#' Available options are: limma-trend, limma-voom, edgeR-LRT, edgeR-QL, DESeq2,
#' ROTS, baySeq, NOISeq, EBSeq, MAST, scde, BPSC, scDD, monocle.
#' @param normalisation Normalisation method to use.
#' Available options are:
#' @param Preclust Whether to run a  hierarchical clustering prior to normalisation. Default is \code{FALSE}. This is implemented for scran and SCnorm.
#' For details, see \code{\link[scran]{quickCluster}}.
#' @param Preprocess A character vector specifying the gene filtering method to be used
#' prior to normalisation. Default is \code{NULL}, i.e. no filtering.
#' Availabe options are: scImpute, DrImpute, CountFilter, FreqFilter.
#' @param spikeIns Logical value to indicate whether to simulate spike-ins. Default is \code{FALSE}.
#' @param NCores integer positive number of cores for parallel processing, default is \code{NULL}, ie 1 core.
#' @param verbose Logical value to indicate whether to show progress report of simulations. Default is \code{TRUE}.
#' @return A list with the following fields.
#' \item{pvalue, fdr}{3D array (ngenes * N * nsims) for p-values and FDR from each simulation.
#' Note that FDR values will be empty and the calculation will be done by \code{\link{evaluateDE}} whenever applicable.}
#' \item{mu,disp,dropout}{3D (ngenes * N * nsims) array for mean, dispersion and dropout of library size factor normalized read counts.}
#' \item{elfc,rlfc}{3D array (ngenes * N * nsims) for log2 fold changes (LFC):
#' elfc is for the DE tool estimated LFC; rlfc is for the LFC estimated from the normalised read counts.}
#' \item{sf.values,gsf.values}{3D array (ngenes * N * nsims) for size factor estimates.
#' Global estimates per sample in sf.values; Gene- and sample-wise estimates in gsf.values only for SCnorm normalisation.}
#' \item{sim.settings}{The input sim.settings to which the specifications of \code{simulateDE} is added.}
#' \item{time.taken}{The time taken for each simulation, given for preprocessing, normalisation, clustering, differential expression testing and moment estimation.}
#' @seealso \code{\link{estimateParam}},  \code{\link{insilicoNBParam}} for negative binomial parameter specifications;\cr
#'  \code{\link{DESetup}}, \code{\link{SimSetup}} for simulation setup
#' @details
#' Preprocessing procedure prior to normalisation:
#' \describe{
#' \item{scImpute}{employs scImpute method of imputing dropouts as implemented in \code{\link[scImpute]{scImpute}}.}
#' \item{DrImpute}{employs DrImpute method of imputing dropouts as implemented in \code{\link[DrImpute]{DrImpute}}.}
#' \item{CountFilter}{removes genes that have a mean expression below 0.2.}
#' \item{FreqFilter}{removes genes that have more than 80% dropouts.}
#' }
#' Normalisation applied to read count matrix:
#' \describe{
#' \item{TMM, UQ}{employ the edgeR style normalization of weighted trimmed mean of M-values and upperquartile
#' as implemented in \code{\link[edgeR]{calcNormFactors}}, respectively.}
#' \item{MR, PosCounts}{employ the DESeq2 style normalization of median ratio method and a modified geometric mean method
#' as implemented in \code{\link[DESeq2]{estimateSizeFactors}}, respectively.}
#' \item{scran, SCnorm}{apply the deconvolution and quantile regression normalization methods developed for sparse RNA-seq data
#' as implemented in \code{\link[scran]{computeSumFactors}} and \code{\link[SCnorm]{SCnorm}}, respectively.
#' For \code{SCnorm}, the user can also supply \code{spikeData}.}
#' \item{Linnorm}{apply the normalization method for sparse RNA-seq data
#' as implemented in \code{\link[Linnorm]{Linnorm.Norm}}.
#' For \code{Linnorm}, the user can also supply \code{spikeData}.}
#' \item{RUV}{removes unwanted variation. There are two approaches implemented:
#' (1) utilizing negative control genes, i.e. spike-ins stored in \code{spikeData} (\code{\link[RUVSeq]{RUVg}}).
#' (2) utilizing replicate samples, i.e. samples for which the covariates of interest are considered constant.
#' This annotation is stored in \code{batchData} (\code{\link[RUVSeq]{RUVs}}).}
#' \item{BASiCS}{removes technical variation by utilizing negative control genes, i.e. spike-ins stored in \code{spikeData},
#' as implemented in \code{\link[BASiCS]{DenoisedCounts}}.
#' Furthermore, the molecule counts of spike-ins added to the cell lysate need to be supplied in \code{spikeInfo}.}
#' \item{Census}{converts relative measures of TPM/FPKM values into mRNAs per cell (RPC) without the need of spike-in standards.
#' Census at least needs \code{Lengths} for single-end data and preferably \code{MeanFragLengths} for paired-end data.
#' Do not use this algorithm for UMI data!}
#' }
#' Differential testing
#' \describe{
#' \item{limma-trend, limma-voom}{apply differential testing as implemented in \code{\link[limma]{lmFit}}
#' followed by \code{\link[limma]{eBayes}} on counts transformed by \code{\link[limma]{voom}} or by applying mean-variance trend on log2 CPM values in \code{\link[limma]{eBayes}}.}
#' \item{edgeR-LRT, edgeR-QL}{apply differential testing as implemented in \code{\link[edgeR]{glmFit}}, \code{\link[edgeR]{glmLRT}} and\code{\link[edgeR]{glmQLFit}}, \code{\link[edgeR]{glmQLFTest}}, respectively.}
#' \item{DESeq2}{applies differential testing as implemented in \code{\link[DESeq2]{DESeq}}.}
#' \item{ROTS}{applies differential testing as implemented in \code{\link[ROTS]{ROTS}} with 100 permutations on transformed counts (\code{\link[limma]{voom}}).}
#' \item{baySeq}{applies differential testing as implemented in \code{\link[baySeq]{getLikelihoods}} based on negative binomial prior estimates (\code{\link[baySeq]{getPriors.NB}}).}
#' \item{NOISeq}{applies differential testing as implemented in \code{\link[NOISeq]{noiseqbio}} based on CPM values.}
#' \item{EBSeq}{applies differential testing as implemented in \code{\link[EBSeq]{EBTest}}.}
#' \item{MAST}{applies differential testing as implemented in \code{\link[MAST]{zlm}} for zero-inflated model fitting followed by \code{\link[MAST]{lrTest}} on log2 CPM values.}
#' \item{scde}{applies differential testing as implemented in \code{\link[scde]{scde.expression.difference}}.}
#' \item{BPSC}{applies differential testing as implemented in \code{\link[BPSC]{BPglm}} on CPM values.}
#' \item{scDD}{applies differential testing as implemented in \code{\link[scDD]{scDD}} on CPM values.}
#' }
#' @examples
#' \dontrun{
#' # download count table
#' githubURL <- "https://github.com/bvieth/powsimRData/raw/master/data-raw/kolodziejczk_cnts.rda"
#' download.file(url = githubURL, destfile= "kolodziejczk_cnts.rda", method = "wget")
#' load('kolodziejczk_cnts.rda')
#' kolodziejczk_cnts <- kolodziejczk_cnts[, grep('standard', colnames(kolodziejczk_cnts))]
#' ## estimate NB parameters:
#' TwoiLIF.params =
#' ## define DE settings:
#' desettings <- DESetup(ngenes=10000,
#' nsims=25, p.DE=0.2,
#' LFC=function(x) sample(c(-1,1), size=x,replace=TRUE)*rgamma(x, 3, 3))
#' ## define simulation settings for Kolodziejczk:
#' simsettings <- SimSetup(desetup=desettings, params=TwoiLIF.params, size.factors='given')
#' ## run simulations:
#' ## if parallel computation unavailable, consider ROTS as DEmethod
#' }
#' @author Beate Vieth
#' @rdname simulateDE
#' @importFrom stats setNames
#' @export
simulateDE <- function(n1=c(20,50,100), n2=c(30,60,120),
                       sim.settings,
                       DEmethod,
                       normalisation,
                       Preclust=FALSE,
                       Preprocess = NULL,
                       spikeIns=FALSE,
                       NCores=NULL,
                       verbose=TRUE) {
  if (!length(n1) == length(n2)) { stop("n1 and n2 must have the same length!") }
  if(isTRUE(spikeIns) && is.null(sim.settings$spike)) {
    stop(message(paste0("For the simulation of  spike-ins, fitting information is needed but there is no 'spike' object in 'sim.settings'.  Please consult the function estimateSpike for spike fitting and SimSetup for creating simulation setup object!")))
  }

  if(!is.null(NCores) && DEmethod %in% c("edgeR-LRT","edgeR-QLRT", 'limma-voom', "limma-trend", "NOISeq", "EBSeq", "ROTS")) {
    message(paste0(DEmethod, " has no parallel computation option!"))
  }

  if(sim.settings$RNAseq == "singlecell" && DEmethod %in% c("edgeR-LRT", "edgeR-QL", "limma-voom", "limma-trend", "DESeq2", "baySeq", "NOISeq", "EBSeq")) {
    message(paste0(DEmethod, " is developed for bulk RNA-seq experiments."))
  }

  if(sim.settings$RNAseq == "bulk" && DEmethod %in% c("MAST", 'BPSC')) {
    message(paste0(DEmethod, " is developed for single cell RNA-seq experiments."))
  }

  if(sim.settings$RNAseq == "bulk" && DEmethod %in% c('scde', 'scDD', 'monocle')) {
    stop(message(paste0(DEmethod, " is only developed and implemented for single cell RNA-seq experiments.")))
  }

  # define the maximal count matrix for simulations
  max.n = max(n1,n2)
  min.n = min(n1, n2)

  # append additional settings of simulateDE to sim.settings
  sim.settings$n1 = n1
  sim.settings$n2 = n2
  sim.settings$normalisation = normalisation
  sim.settings$DEmethod = DEmethod
  sim.settings$spikeIns = spikeIns
  sim.settings$NCores = NCores
  sim.settings$Preclust = Preclust
  sim.settings$Preprocess = Preprocess
  if(isTRUE(Preclust)) {PreclustNumber <- min.n}
  if(!isTRUE(Preclust)) {PreclustNumber <- NULL}
  sim.settings$PreclustNumber = PreclustNumber

  if (verbose) { message(paste0("Preparing output arrays.")) }

  my.names = paste0(n1,"vs",n2)

  #set up output arrays
  pvalues = fdrs = elfcs = rlfcs = mus = disps = dropouts = array(NA,dim=c(sim.settings$ngenes,length(n1), sim.settings$nsims))
  time.taken = array(NA,dim = c(4,length(n1), sim.settings$nsims),
                     dimnames = list(c('Preprocess', "Normalisation", "DE", "Moments"),
                                     NULL, NULL))
  true.sf = stats::setNames(replicate(length(n1),NULL),my.names)
  est.sf = stats::setNames(replicate(length(n1),NULL),my.names)
  true.sf <- lapply(1:length(true.sf), function(x) {
    true.sf[[x]] = matrix(NA, nrow = sim.settings$nsims, ncol = n1[x] + n2[x])
  })
  est.sf <- lapply(1:length(est.sf), function(x) {
    est.sf[[x]] = matrix(NA, nrow = sim.settings$nsims, ncol = n1[x] + n2[x])
  })

  if(sim.settings$normalisation=="SCnorm") {
    est.gsf = stats::setNames(replicate(length(n1),NULL),my.names)
    est.gsf <- lapply(1:length(est.gsf), function(x) {
      est.gsf[[x]] = array(NA,dim=c(sim.settings$nsims, sim.settings$ngenes, n1[x] + n2[x]))
    })
  }
  if(!sim.settings$normalisation=="SCnorm") {
    est.gsf = NULL
  }

  true.designs = stats::setNames(replicate(length(n1),NULL),my.names)
  true.designs <- lapply(1:length(true.designs), function(x) {
    true.designs[[x]] = matrix(NA, nrow = sim.settings$nsims, ncol = n1[x] + n2[x])
  })

  ## start simulation
  for (i in 1:sim.settings$nsims) {
    if (verbose) { message(paste0("Simulation number ", i, "\n")) }
    ## update the simulation options by extracting the ith set and change sim.seed
    tmp.simOpts = sim.settings
    tmp.simOpts$DEid = tmp.simOpts$DEid[[i]]
    tmp.simOpts$pLFC = tmp.simOpts$pLFC[[i]]
    tmp.simOpts$bLFC = tmp.simOpts$bLFC[[i]]
    tmp.simOpts$sim.seed = tmp.simOpts$sim.seed[[i]]

    ## generate gene read counts
    if (verbose) {message(paste0("Generating RNA seq read counts")) }
    gene.data = .simRNAseq.2grp(simOptions = tmp.simOpts,
                                n1 = max.n, n2 = max.n, verbose=verbose)

    ## generate spike-in read counts
    if(isTRUE(spikeIns)) {
    if (verbose) { message(paste0("Generating spike-in read counts")) }
      spike.data = .simSpike(SpikeOptions = tmp.simOpts$spike, n1 = max.n, n2 = max.n)
    }
    if(!isTRUE(spikeIns)) {
      spike.data = NULL
      spike.info = NULL
    }

    ## generate mean fragment lengths for samples
    if(!is.null(tmp.simOpts$MeanFragLengths)) {
      if (verbose) { message(paste0("Sampling from observed mean fragment lengths")) }
      MeanFrag.data = sample(tmp.simOpts$MeanFragLengths, max.n+max.n, replace = TRUE)
      names(MeanFrag.data) = colnames(gene.data$counts)
    }
    if(is.null(tmp.simOpts$MeanFragLengths)) {
      MeanFrag.data = NULL
    }

    ## match sampled gene names with given gene lengths
    if(!is.null(tmp.simOpts$Lengths)) {
      gene.id = sub('_([^_]*)$', '', rownames(gene.data$counts))
      Length.data = tmp.simOpts$Lengths
      Length.data = Length.data[match(gene.id,names(Length.data))]
    }
    if(is.null(tmp.simOpts$Lengths)) {
      Length.data = NULL
    }


    ##  for different sample sizes
    for (j in seq(along=n1)) {
      Nrep1 = n1[j]
      Nrep2 = n2[j]
      if (verbose) { message(paste0(Nrep1, " vs. ", Nrep2)) }

      tmp.simOpts$PreclustNumber = min(Nrep1, Nrep2)

      ## take a subsample of simulated samples
      idx = c(1:Nrep1, max.n + (1:Nrep2))
      true.design = gene.data$designs[idx]

      ## take a subsample of the simulated read counts
      sim.cnts = gene.data$counts[,idx]
      ## take a subsample of the true size factors
      gene.sf = gene.data$sf[idx]
      ## filter out zero expression genes
      ix.valid = rowSums(sim.cnts) > 0
      count.data = sim.cnts[ix.valid,, drop = FALSE]

      ## match sampled gene names with given gene lengths
      if(!is.null(Length.data)) {
        if (verbose) { message(paste0("Associating gene lengths with sampled gene expression")) }
        gene.id = sub('_([^_]*)$', '', rownames(count.data))
        length.data = Length.data
        length.data = length.data[match(gene.id,names(length.data))]
      }
      if(is.null(Length.data)) {
        length.data = NULL
      }

      ## take a subsample of simulated spike-ins
      if(!is.null(spike.data)) {
        sim.spike <- spike.data$counts
        spike.valid = rowSums(sim.spike) > 0
        count.spike = sim.spike[spike.valid, idx, drop=FALSE]
        if(!is.null(sim.settings$spike)) {
          spike.info <- tmp.simOpts$spike$Input$spikeInfo[rownames(tmp.simOpts$spike$Input$spikeInfo)
                                              %in% rownames(count.spike), , drop = FALSE]
          spike.info <- spike.info[match(rownames(count.spike),
                                         rownames(spike.info)), , drop = FALSE]
        }
      }
      if(is.null(spike.data)) {
        count.spike = NULL
      }
      ## take a subsample of mean fragment lengths
      if(!is.null(MeanFrag.data)) {
        meanfrag.data = MeanFrag.data[idx]
      }
      if(is.null(MeanFrag.data)) {
        meanfrag.data = NULL
      }

      ## perform filtering / imputation (OPTIONAL)
      start.time.preprocess <- Sys.time()
      if(!is.null(Preprocess)) {
        if (verbose) { message(paste0("Applying preprocessing")) }
        filter.data <- .preprocess.calc(Preprocess=tmp.simOpts$Preprocess,
                                        countData=count.data,
                                        NCores=tmp.simOpts$NCores)
        # ixx.valid <- rownames(sim.cnts) %in% rownames(filter.data)
        # ix.valid <- ixx.valid
        fornorm.count.data <- filter.data
        if(!is.null(Length.data)) {
          gene.id = sub('_([^_]*)$', '', rownames(fornorm.count.data))
          fornorm.length.data = Length.data
          fornorm.length.data = fornorm.length.data[match(gene.id,names(fornorm.length.data))]
        }
        if(is.null(Length.data)) {
          length.data = NULL
        }
      }
      if(is.null(Preprocess)) {
        fornorm.count.data <- count.data
      }
      end.time.preprocess <- Sys.time()

      ## perform normalisation
      if (verbose) { message(paste0("Normalizing read counts")) }
      start.time.norm <- Sys.time()
      norm.data <- .norm.calc(normalisation=tmp.simOpts$normalisation,
                             countData=fornorm.count.data,
                             spikeData=count.spike,
                             spikeInfo=spike.info,
                             batchData=NULL,
                             Lengths=length.data,
                             MeanFragLengths=meanfrag.data,
                             PreclustNumber=tmp.simOpts$PreclustNumber,
                             NCores=tmp.simOpts$NCores,
                             verbose=verbose)
      end.time.norm <- Sys.time()

      def.design <- true.design

      ## create an DE options object to pass into DE detection
      DEOpts <- list(designs=def.design, p.DE=tmp.simOpts$p.DE)

      ## Run DE detection
      if (verbose) { message(paste0("Running DE tool")) }
      start.time.DE <- Sys.time()
      res.de = .de.calc(DEmethod=tmp.simOpts$DEmethod,
                        normData=norm.data,
                        countData=count.data,
                        DEOpts=DEOpts,
                        spikeData=count.spike,
                        spikeInfo=spike.info,
                        Lengths=length.data,
                        MeanFragLengths=meanfrag.data,
                        NCores=tmp.simOpts$NCores)
      end.time.DE <- Sys.time()

      ## estimate moments of read counts simulated
      start.time.NB <- Sys.time()
      res.params <- .run.params(countData=count.data,
                                normData=norm.data,
                                group=DEOpts$designs)
      end.time.NB <- Sys.time()

      # generate empty vectors
      pval = fdr = est.lfc = raw.lfc = mu.tmp = disp.tmp = p0.tmp = rep(NA, nrow(sim.cnts))
      ## extract results of DE testing
      pval[ix.valid] = res.de$pval
      fdr[ix.valid] = res.de$fdr
      est.lfc[ix.valid] = res.de$lfc
      raw.lfc[ix.valid] = res.params$lfc
      mu.tmp[ix.valid] = res.params$means
      disp.tmp[ix.valid] = res.params$dispersion
      p0.tmp[ix.valid] = res.params$dropout
      # copy it in 3D array of results
      pvalues[,j,i] = pval
      fdrs[,j,i] = fdr
      elfcs[,j,i] = est.lfc
      rlfcs[,j,i] = raw.lfc
      mus[,j,i] = mu.tmp
      disps[,j,i] = disp.tmp
      dropouts[,j,i] = p0.tmp
      true.sf[[j]][i,] = gene.sf
      est.sf[[j]][i,] = norm.data$size.factors

      if(attr(norm.data, 'normFramework') == 'SCnorm') {
        allgenes <- rownames(sim.cnts)
        testedgenes <- rownames(norm.data$scale.factors)
        ixx.valid <- allgenes %in% testedgenes
        est.gsf[[j]][i, ixx.valid, ] = norm.data$scale.factors
      }

      true.designs[[j]][i,] = true.design

      # time taken for each step
      if(!is.null(Preprocess)) {
        time.taken.preprocess <-  difftime(end.time.preprocess,
                                           start.time.preprocess,
                                           units="mins")
      }
      if(is.null(Preprocess)) {
        time.taken.preprocess = NA
      }

      time.taken.norm <- difftime(end.time.norm,
                                  start.time.norm,
                                  units="mins")
      time.taken.DE <- difftime(end.time.DE,
                                start.time.DE,
                                units="mins")
      time.taken.NB <- difftime(end.time.NB,
                                start.time.NB,
                                units="mins")
      timing <- rbind(time.taken.preprocess,
                      time.taken.norm,
                      time.taken.DE,
                      time.taken.NB)

      # copy time taken in 2D array of time taken
      time.taken[,j,i] = timing

    }
  }

  ## return
  res.out <- list(pvalue = pvalues,
                  fdr = fdrs,
                  elfc = elfcs,
                  rlfc = rlfcs,
                  mu = mus,
                  disp = disps,
                  dropout = dropouts,
                  true.sf = true.sf,
                  est.sf = est.sf,
                  est.gsf = est.gsf,
                  true.designs=true.designs,
                  time.taken = time.taken,
                  sim.settings = sim.settings)

  attr(res.out, 'Simulation') <- "DE"
  return(res.out)
}
