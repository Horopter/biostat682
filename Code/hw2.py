import numpy as np
import pandas as pd
from scipy import stats
from scipy import special
import matplotlib.pyplot as plt

# --- Load data ---
df = pd.read_csv('/Users/jiankang/University of Michigan Dropbox/Jian Kang/Umich/Biostat682/Fall2025/data/treatment_data.csv')  # expects columns: x, y

x = df['dosage'].to_numpy(dtype=float)
y = df['response'].to_numpy(dtype=float)
n = y.size

# --- Sufficient statistics ---
Sxx = np.dot(x, x)
Sxy = np.dot(x, y)
beta_hat = Sxy / Sxx
res1 = y - beta_hat * x
SSE1 = np.dot(res1, res1)
SSE0 = np.dot(y, y)

# --- Marginal likelihoods (use log-scale for stability) ---
# m0(y) = Gamma(n/2)/pi^{n/2} * SSE0^{-n/2}
# m1(y) = Gamma((n-1)/2)/(pi^{n/2} * sqrt(Sxx)) * SSE1^{-(n-1)/2}
log_m0 = special.gammaln(n/2) - (n/2)*np.log(np.pi) - (n/2)*np.log(SSE0)
log_m1 = (special.gammaln((n-1)/2) - (n/2)*np.log(np.pi)
          - 0.5*np.log(Sxx) - ((n-1)/2)*np.log(SSE1))

# posterior Pr(delta=1 | y) = m1 / (m0 + m1)
# compute on log scale:
# p1 = 1 / (1 + exp(log_m0 - log_m1))
log_ratio = log_m0 - log_m1
p1 = 1.0 / (1.0 + np.exp(log_ratio))
p0 = 1.0 - p1

# --- Predictive components ---
s0 = np.sqrt(SSE0 / n)          # t_n scale under M0
s1 = np.sqrt(SSE1 / (n - 1))    # residual scale under M1

def pred_scale_M1(xstar):
    h = (xstar**2) / Sxx
    return s1 * np.sqrt(1.0 + h)

def mixture_predictive_samples(xstar, R=500_000, seed=2025):
    rng = np.random.default_rng(seed)
    # mixture weights p0, p1 fixed
    d = rng.random(R) < p1
    # component draws
    # Under M0: t_n(0, s0)
    y0 = stats.t.rvs(df=n, loc=0.0, scale=s0, size=(~d).sum(), random_state=rng)
    # Under M1: t_{n-1}(x* beta_hat, s1 * sqrt(1+h))
    sc1 = pred_scale_M1(xstar)
    y1 = stats.t.rvs(df=n-1, loc=xstar * beta_hat, scale=sc1, size=d.sum(), random_state=rng)
    # assemble
    out = np.empty(R)
    out[d]  = y1
    out[~d] = y0
    return out

def mixture_predictive_summary(xstar, R=500_000, seed=2025):
    samp = mixture_predictive_samples(xstar, R=R, seed=seed)
    mean = samp.mean()
    lo, hi = np.quantile(samp, [0.025, 0.975])
    return mean, (lo, hi), samp

# Patients A and B
xA, xB = -2.0, 2.0
meanA, (loA, hiA), sampA = mixture_predictive_summary(xA)
meanB, (loB, hiB), sampB = mixture_predictive_summary(xB)

# --- Proper joint simulation for Pr(yB > yA) ---
def joint_prob_B_gt_A(R=500_000, seed=2025):
    rng = np.random.default_rng(seed)
    count = 0
    for _ in range(R):
        # sample delta
        d = rng.random() < p1
        if not d:
            # sigma2 ~ IG(n/2, SSE0/2)  (shape alpha, scale beta)
            alpha = n/2
            beta = SSE0/2
            # sample sigma2 by inverse-gamma via 1/Gamma(alpha, scale=1/beta)
            sigma2 = 1.0 / rng.gamma(shape=alpha, scale=1.0/beta)
            yA = rng.normal(loc=0.0, scale=np.sqrt(sigma2))
            yB = rng.normal(loc=0.0, scale=np.sqrt(sigma2))
        else:
            alpha = (n-1)/2
            beta = SSE1/2
            sigma2 = 1.0 / rng.gamma(shape=alpha, scale=1.0/beta)
            beta_draw = rng.normal(loc=beta_hat, scale=np.sqrt(sigma2 / Sxx))
            yA = rng.normal(loc=beta_draw * xA, scale=np.sqrt(sigma2))
            yB = rng.normal(loc=beta_draw * xB, scale=np.sqrt(sigma2))
        if yB > yA:
            count += 1
    return count / R

prob_B_gt_A = joint_prob_B_gt_A()

# --- Output ---
print(f"n = {n}")
print(f"Sxx = {Sxx:.6g}, Sxy = {Sxy:.6g}, beta_hat = {beta_hat:.6g}")
print(f"SSE0 = {SSE0:.6g}, SSE1 = {SSE1:.6g}")
print(f"Pr(delta=1 | data) = {p1:.6f}")

print("\nPredictive summaries (mixture of t):")
print(f"Patient A (x*={xA}): mean = {meanA:.4f}, 95% PI = [{loA:.4f}, {hiA:.4f}]")
print(f"Patient B (x*={xB}): mean = {meanB:.4f}, 95% PI = [{loB:.4f}, {hiB:.4f}]")

print(f"\nPosterior probability Pr(y_B* > y_A* | data) = {prob_B_gt_A:.4f}")

# --- Quick diagnostic plot ---
plt.scatter(x, y, alpha=0.6)
xx = np.linspace(x.min(), x.max(), 200)
plt.plot(xx, beta_hat * xx, lw=2)
plt.title("Data and through-origin fit (beta_hat)")
plt.xlabel("x (dosage)")
plt.ylabel("y (response)")
plt.tight_layout()
plt.show()