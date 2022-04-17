# library(parallel)
# Parallelise any simple features analysis.
st_par <- function(sf_df, sf_func, n_cores, ...) {
  
  # Create a vector to split the data set up by.
  split_vector <- rep(1:n_cores, each = nrow(sf_df) / n_cores, length.out = nrow(sf_df))
  
  # Perform GIS analysis
  split_results <- split(sf_df, split_vector) %>%
    mclapply(function(x) sf_func(x, ...), mc.cores = n_cores)
  
  # Combine results back together. Method of combining might depend on the
  # output from the function. For st_join it is a list of sf objects. This
  # satisfies my needs for reverse geocoding
  result <- dplyr::bind_rows(split_results)
  
  # Return result
  return(result)
}