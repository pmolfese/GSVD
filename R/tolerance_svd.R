#' @export
#'
#' @title \code{tolerance_svd}: An SVD to truncate potentially spurious (near machine precision) components.
#'
#' @description \code{tolerance_svd} eliminates likely spurious components: any eigenvalue (squared singular value) below a tolerance level is elminated.
#'    The (likely) spurious singular values and vectors are then eliminated from \code{$u}, \code{$d}, and \code{$v}.
#'    Additionally, all values in \code{abs($u)} or \code{abs($v)} that fall below the \code{tol} are set to 0.
#'    The use of a real positive value for \code{tol} will eliminate any small valued components.
#'    With \code{tol}, \code{tolerance_svd} will stop if any singular values are complex or negative.
#'
#' @param x A data matrix of size for input to the singular value decomposition (\code{\link{svd}})
#' @param nu The number of left singular vectors to be computed. Default is \code{min(dim(x))}
#' @param nv The number of right singular vectors to be computed. Default is \code{min(dim(x))}
#' @param tol Default is \code{.Machine$double.eps}. A tolerance level for eliminating near machine precision components.
#' Use of this parameter causes \code{tolerance_svd} to stop if negative or complex singular values are detected.
#' The use of \code{tol < 0}, \code{NA}, \code{NaN}, \code{Inf}, \code{-Inf}, or \code{NULL} passes through to \code{\link{svd}}.
#'
#' @return A list with three elements (like \code{svd}):
#'  \item{d}{ A vector containing the singular values of x > \code{tol}.}
#'  \item{u}{ A matrix whose columns contain the left singular vectors of x, present if nu > 0. Dimension \code{min(c(nrow(x), nu, length(d))}.}
#'  \item{v}{ A matrix whose columns contain the right singular vectors of x, present if nv > 0. Dimension \code{min(c(ncol(x), nv, length(d))}.}
#'
#' @seealso \code{\link{svd}}
#'
#' @examples
#'  data(wine)
#'  X <- scale(as.matrix(wine$objective))
#'  s_asis <- tolerance_svd(X)
#'  s_.Machine <- tolerance_svd(X, tol= .Machine$double.eps)
#'  s_000001 <- tolerance_svd(X, tol=.000001)
#'
#' @author Derek Beaton
#' @keywords multivariate

tolerance_svd <- function(x, nu=min(dim(x)), nv=min(dim(x)), tol = .Machine$double.eps) {

  ## the R SVD is much faster/happier when there are more rows than columns in a matrix
    ## however, even though a transpose can speed up the SVD, there is a slow down to then set the U and V back to where it was
    ## so I will remove this for now. I just need to keep it in mind.

  # x.dims <- dim(x)
  # x.is.transposed <- F
  # if( (x.dims[1]*10) < x.dims[2]){ # * 10 to make it worth the transpose.
  #   x.is.transposed <- T
  #   x <- t(x)
  # }

  ## nu and nv are pass through values.
  ### this probably needs a try-catch & I should bring back the above block for transposition
  svd_res <- svd(x, nu = nu, nv = nv)

  # if tolerance is any of these values, just do nothing; send back the SVD results as is.
  if( (is.null(tol) | is.infinite(tol) | is.na(tol) | is.nan(tol) | tol < 0) ){

    return(svd_res)

  }
  ## once you go past this point you *want* the tolerance features.


  if(any(unlist(lapply(svd_res$d,is.complex)))){
    stop("tolerance_svd: Singular values ($d) are complex.")
  }
  # if( (any(abs(svd_res$d) > tol) ) & (any(sign(svd_res$d) != 1)) ){
  if( any( (svd_res$d^2 > tol) & (sign(svd_res$d)==-1) ) ){
    stop("tolerance_svd: Singular values ($d) are negative with a magnitude above 'tol'.")
  }

  svs.to.keep <- which(!(svd_res$d^2 < tol))
  if(length(svs.to.keep)==0){
    stop("tolerance_svd: All (squared) singular values were below 'tol'")
  }

  svd_res$d <- svd_res$d[svs.to.keep]

  ## are these checks necessary? problably...
  if(nu >= length(svs.to.keep)){
    svd_res$u <- as.matrix(svd_res$u[,svs.to.keep])
  }else{
    svd_res$u <- as.matrix(svd_res$u[,1:nu])
  }

  if(nv >= length(svs.to.keep)){
    svd_res$v <- as.matrix(svd_res$v[,svs.to.keep])
  }else{
    svd_res$v <- as.matrix(svd_res$v[,1:nv])
  }

  rownames(svd_res$u) <- rownames(x)
  rownames(svd_res$v) <- colnames(x)

  ## new way inspired by FactoMineR but with some changes
  vector_signs <- ifelse(colSums(svd_res$v) < 0, -1, 1)
  svd_res$v <- t(t(svd_res$v) * vector_signs)
  svd_res$u <- t(t(svd_res$u) * vector_signs)

  # class(svd_res) <- c("svd", "GSVD", "list")
  # return(svd_res)
  return(svd_res)
}
