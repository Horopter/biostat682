## ---------------------------
## Bayesian dosage model (R)
## ---------------------------

## --- Load data ---
## Expect a CSV with columns (dosage, response).
## Set your path as needed; 
path <- "/Users/jiankang/University of Michigan Dropbox/Jian Kang/Umich/Biostat682/Fall2025/data/treatment_data.csv"
df <- read.csv(path, stringsAsFactors = FALSE)


x <- as.numeric(df$dosage); 
y <- as.numeric(df$response)

n <- length(y)
if (n != length(x) || n < 3) stop("Data error: unequal lengths or too few observations.")

## --- Sufficient statistics ---
Sxx <- sum(x^2)
Sxy <- sum(x*y)
beta_hat <- Sxy / Sxx
res1 <- y - beta_hat * x
SSE1 <- sum(res1^2)
SSE0 <- sum(y^2)

## --- Marginal likelihoods (log-scale for stability) ---
## m0(y) = Gamma(n/2) / pi^{n/2} * SSE0^{-n/2}
## m1(y) = Gamma((n-1)/2) / (pi^{(n-1)/2} * sqrt(Sxx)) * SSE1^{-(n-1)/2}
## (same as in your derivation; the pi-power forms are consistent)
log_m0 <- lgamma(n/2) - (n/2)*log(pi) - (n/2)*log(SSE0)
log_m1 <- lgamma((n-1)/2) - ((n-1)/2)*log(pi) - 0.5*log(Sxx) - ((n-1)/2)*log(SSE1)

## Posterior Pr(delta=1 | y) with prior 0.5/0.5
## p1 = m1 / (m0 + m1) = 1 / (1 + exp(log_m0 - log_m1))
log_ratio <- log_m0 - log_m1
p1 <- 1 / (1 + exp(log_ratio))
p0 <- 1 - p1

## --- Predictive component scales ---
s0 <- sqrt(SSE0 / n)        # under M0: t_n(0, s0)
s1 <- sqrt(SSE1 / (n - 1))  # under M1: t_{n-1}(x* beta_hat, s1*sqrt(1+h))

pred_scale_M1 <- function(xstar) {
  h <- (xstar^2) / Sxx
  s1 * sqrt(1 + h)
}

## --- Mixture-of-t predictive draws for a given x* ---
mixture_predictive_samples <- function(xstar, R = 200000, seed = 123) {
  set.seed(seed)
  d <- runif(R) < p1  # which component: TRUE => M1, FALSE => M0
  
  ## Under M0: t_n(0, s0)
  n0 <- sum(!d)
  y0 <- if (n0 > 0) {
    0 + s0 * rt(n0, df = n)     # location 0, scale s0
  } else numeric(0)
  
  ## Under M1: t_{n-1}(x* beta_hat, s1 * sqrt(1+h))
  n1 <- sum(d)
  sc1 <- pred_scale_M1(xstar)
  y1 <- if (n1 > 0) {
    xstar * beta_hat + sc1 * rt(n1, df = n - 1)
  } else numeric(0)
  
  out <- numeric(R)
  out[d]  <- y1
  out[!d] <- y0
  out
}

mixture_predictive_summary <- function(xstar, R = 200000, seed = 123) {
  samp <- mixture_predictive_samples(xstar, R = R, seed = seed)
  mean <- mean(samp)
  q <- quantile(samp, probs = c(0.025, 0.975))
  list(mean = mean, PI95 = unname(q), samples = samp)
}

## --- Patients A and B ---
xA <- -2
xB <-  2

summA <- mixture_predictive_summary(xA)
summB <- mixture_predictive_summary(xB)

## --- Proper joint simulation for Pr(yB > yA) ---
## Share the same draw of (delta, sigma^2, beta) within each iteration.
prob_B_gt_A <- (function(R = 200000, seed = 456) {
  set.seed(seed)
  cnt <- 0L
  for (r in seq_len(R)) {
    d <- runif(1) < p1
    if (!d) {
      ## delta = 0: sigma^2 ~ IG(n/2, SSE0/2)
      alpha <- n/2
      beta  <- SSE0/2
      sigma2 <- 1 / rgamma(1, shape = alpha, rate = beta)  # rate parameterization
      yA <- rnorm(1, mean = 0, sd = sqrt(sigma2))
      yB <- rnorm(1, mean = 0, sd = sqrt(sigma2))
    } else {
      ## delta = 1: sigma^2 ~ IG((n-1)/2, SSE1/2), beta | sigma^2,y ~ N(beta_hat, sigma^2/Sxx)
      alpha <- (n - 1)/2
      beta  <- SSE1/2
      sigma2 <- 1 / rgamma(1, shape = alpha, rate = beta)
      beta_draw <- rnorm(1, mean = beta_hat, sd = sqrt(sigma2 / Sxx))
      yA <- rnorm(1, mean = beta_draw * xA, sd = sqrt(sigma2))
      yB <- rnorm(1, mean = beta_draw * xB, sd = sqrt(sigma2))
    }
    if (yB > yA) cnt <- cnt + 1L
  }
  cnt / R
})()

## --- Output ---
cat(sprintf("n = %d\n", n))
cat(sprintf("Sxx = %.6g, Sxy = %.6g, beta_hat = %.6g\n", Sxx, Sxy, beta_hat))
cat(sprintf("SSE0 = %.6g, SSE1 = %.6g\n", SSE0, SSE1))
cat(sprintf("Pr(delta = 1 | data) = %.6f\n\n", p1))

cat("Predictive summaries (mixture of t):\n")
cat(sprintf("Patient A (x* = %s): mean = %.4f, 95%% PI = [%.4f, %.4f]\n",
            xA, summA$mean, summA$PI95[1], summA$PI95[2]))
cat(sprintf("Patient B (x* = %s): mean = %.4f, 95%% PI = [%.4f, %.4f]\n",
            xB, summB$mean, summB$PI95[1], summB$PI95[2]))

cat(sprintf("\nPosterior probability Pr(y_B* > y_A* | data) = %.4f\n", prob_B_gt_A))

## --- Quick diagnostic plot (base R) ---
plot(x, y, pch = 19, col = "gray40",
     xlab = "x (dosage)", ylab = "y (response)",
     main = "Data and through-origin fit (beta_hat)")
xx <- seq(min(x), max(x), length.out = 200)
lines(xx, beta_hat * xx, lwd = 2)
abline(h = 0, v = 0, col = "gray85", lty = 3)

