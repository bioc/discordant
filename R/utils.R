#' @export
fishersTrans <- function(rho) {
    r = (1 + rho) / (1 - rho)
    z = 0.5 * log(r, base = exp(1))
    return(z)
}

subSampleData <- function(pdata, class, mu, sigma, nu, tau, pi, components) {
    n <- as.integer(dim(pdata)[1])
    g <- as.integer(nlevels(as.factor(class)))
    
    yl.outer <- function(k, zx, zy){
        return( c(zx[k,] %o% zy[k,]) )
    }
    yl.diag <- function(k, z){
        return( c(diag(z[k,])) )
    }
    
    zx <- unmap(class[,1], components = components)
    zy <- unmap(class[,2], components = components)
    zxy <- sapply(1:dim(zx)[1], yl.outer, zx, zy)
    
    results <- subsampling_cpp(as.double(pdata[,1]), as.double(pdata[,2]), 
                               as.double(t(zxy)), n, as.double(pi), 
                               as.double(mu), as.double(sigma), as.double(nu), 
                               as.double(tau), g)
    
    return(list(pi = t(array(results[[5]], dim=c(g,g))), 
                mu_sigma = rbind(results[[6]], results[[7]]), 
                nu_tau = rbind(results[[8]], results[[9]]), 
                class = apply(array(results[[3]], dim = c(n, g*g)), 1, order,
                              decreasing=TRUE)[1,], 
                z = array(results[[3]], dim=c(n,g*g))))
} 

getNames <- function(x, y = NULL) {
    if(is.null(y) == FALSE) {
        namesMatrix <- NULL
        for(i in 1:nrow(x)) {
            tempMatrix <- cbind(rep(rownames(x)[i], nrow(y)), rownames(y))
            namesMatrix <- rbind(namesMatrix, tempMatrix)
        }
    } else {
        temp <- matrix(NA,nrow = nrow(x), ncol = nrow(x))
        diag <- lower.tri(temp, diag = FALSE)
        temp[diag] <- rep(1, sum(diag == TRUE))
        
        namesMatrix <- NULL
        
        for(i in 1:dim(temp)[1]) {
            outputCol <- temp[,i]
            index <- which(is.na(outputCol) == FALSE)
            if(length(index) > 0) {
                tempMatrix <- cbind(rep(rownames(x)[i],length(index)), 
                                    rownames(x)[index])
                namesMatrix <- rbind(namesMatrix, tempMatrix)
            }
        }
    }
    
    vector_names <- apply(namesMatrix, 1, function(k) paste(k[1],"_",k[2],
                                                            sep = ""))
    return(vector_names)
}

checkInputs <- function(x, y, groups = NULL) {
    issue = FALSE
    if(is.null(groups) == FALSE  && unique(unique(groups) != c(1,2))) {
        print("groups vector must consist of 1s and 2s corresponding to first
             and second group.")
        issue = TRUE
    }
    if(mode(x) != "S4" || (is.null(y) == FALSE && mode(y) != "S4")) {
        print("data matrices x and/or y must be type ExpressionSet")
        issue = TRUE
    }
    return(issue)
}