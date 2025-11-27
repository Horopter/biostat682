# Methodological Choices: Why Different from Solution PDF?

This document explains the reasoning behind the methodological choices that differ from the homework solution PDF. These choices reflect modern Bayesian practice, software-specific considerations, and practical trade-offs.

---

## PROBLEM 1: SWIM TIMES - Prior Specifications

### Solution PDF Approach:
```
β₀j ~ N(23, 3⁻²) = N(23, 1/9) ≈ N(23, 0.111)
β₁j ~ N(0, 100²) = N(0, 10,000)
σ⁻² ~ Gamma(0.0001, 0.0001)
```

### Your Code Approach:
```python
alpha ~ N(23, 1²) = N(23, 1)
beta ~ N(0, 0.2²) = N(0, 0.04)
sigma ~ HalfNormal(0.5)
```

### Reasoning Behind the Choice:

1. **Tighter Intercept Prior (N(23, 1) vs N(23, 1/9)):**
   - **Rationale:** The solution's prior (SD = 1/3 ≈ 0.33) is extremely tight - it puts 95% of mass between 22.34 and 23.66 seconds
   - **Your choice:** SD = 1.0 puts 95% mass between 21 and 25 seconds, which still respects the "22-24 seconds" constraint but allows more flexibility
   - **Justification:** Competitive times "generally range from 22 to 24 seconds" suggests the range, not that 23 is the exact center with tiny variance
   - **Modern practice:** Slightly more informative priors that still allow data to dominate

2. **Much Tighter Slope Prior (N(0, 0.04) vs N(0, 10,000)):**
   - **Rationale:** The solution's prior (SD = 100) is essentially flat - it allows slopes from -200 to +200 seconds per week, which is physically impossible
   - **Your choice:** SD = 0.2 allows slopes from roughly -0.4 to +0.4 seconds per week, which is realistic for swim performance
   - **Justification:** 
     - Over 6 weeks, a slope of ±0.2 sec/week means ±1.2 seconds total change
     - A slope of ±100 sec/week would mean ±600 seconds (10 minutes!) over 6 weeks - clearly absurd
   - **Modern practice:** Use domain knowledge to set reasonable bounds, even if "weakly informative"
   - **Regularization benefit:** Prevents overfitting to noise in small datasets (n=6 per swimmer)

3. **HalfNormal on SD vs Gamma on Precision:**
   - **Rationale:** 
     - Solution uses inverse-gamma on precision (σ⁻²)
     - Your code uses half-normal on standard deviation (σ)
   - **Justification:**
     - **Interpretability:** Standard deviations are more intuitive than precisions
     - **PyMC convention:** PyMC encourages working with standard deviations directly
     - **Prior shape:** HalfNormal(0.5) puts most mass on small σ values, which is appropriate for swim times (low measurement error expected)
   - **Equivalence:** Both are "weakly informative" but parameterized differently

### Trade-offs:
- ✅ **Pros:** More realistic priors that prevent absurd parameter values, better regularization
- ❌ **Cons:** Different from solution, may produce slightly different results
- **Impact:** The recommendation (Swimmer 1) is the same, suggesting the choice is reasonable

---

## PROBLEM 2: USCRIME - Data Preprocessing and Methodology

### Key Differences:

1. **Y Standardization:**
   - **Solution:** Standardizes Y (response variable): `Y ← (Y0 - mean_Y) / sd_Y`
   - **Your code:** Does NOT standardize Y, only X (predictors)
   - **Reasoning:**
     - **Interpretability:** Keeping Y in original units (crime rate per 1000) makes results interpretable
     - **Prediction context:** When making predictions, you want them in original units
     - **Modern practice:** Standardizing predictors is common, but standardizing responses is less common unless necessary
   - **Impact:** This likely explains the massive RMSE difference (405.6 vs 72.9)
     - Solution's RMSE is in standardized units (SD units)
     - Your RMSE is in original units (crime rate units)
     - **This is actually a BUG** - should have matched solution or clearly documented the difference

2. **Conjugate Bayesian Regression vs MCMC:**
   - **Solution:** Uses JAGS MCMC with flat priors N(0, 10⁶)
   - **Your code:** Uses closed-form conjugate Bayesian regression with improper prior p(β, σ²) ∝ 1/σ²
   - **Reasoning:**
     - **Computational efficiency:** Conjugate analysis is exact and instant (no MCMC needed)
     - **Theoretical elegance:** Closed-form posteriors are mathematically clean
     - **Equivalence:** Both are "noninformative" - conjugate uses improper prior, solution uses very diffuse proper prior
   - **Justification:** For linear regression with noninformative priors, conjugate analysis is equivalent to MCMC with flat priors
   - **Trade-off:** 
     - ✅ Faster, exact results
     - ❌ Less flexible (can't easily add other priors or extensions)

3. **Spike-and-Slab Implementation:**
   - **Solution:** Uses JAGS with Bernoulli indicators and precision-based spike
   - **Your code:** Uses PyMC with similar structure but different parameterization
   - **Reasoning:**
     - **Software choice:** PyMC vs JAGS - both valid, different syntax
     - **Modern practice:** PyMC is more Python-native and has better diagnostics
   - **Issue:** The terrible RMSE (1056.7 vs 17.9) suggests a bug, not a methodological choice
     - Likely related to Y standardization issue
     - Or possibly prediction methodology (solution generates predictions in JAGS, you compute manually)

---

## PROBLEM 3: GAMBIA - Hierarchical Model Priors

### Key Differences:

1. **HalfCauchy on SD vs Gamma on Precision:**
   - **Solution:** `σ⁻²α ~ Gamma(0.001, 0.001)`, `σ⁻²β ~ Gamma(0.001, 0.001)`
   - **Your code:** `σα ~ HalfCauchy(5.0)`, `σβ ~ HalfCauchy(5.0)`
   - **Reasoning:**
     - **Modern Bayesian practice:** HalfCauchy is now preferred over Gamma(ε, ε) for variance components
     - **Gelman's recommendation:** HalfCauchy avoids problems with Gamma(ε, ε) priors:
       - Gamma(0.001, 0.001) can be too informative near zero
       - HalfCauchy has better behavior for hierarchical models
     - **Solution PDF actually acknowledges this:** Page 17 mentions using HalfCauchy as an alternative and shows results are robust
     - **Your choice is actually MORE modern** than the solution's default
   - **Justification:** The solution PDF itself shows a sensitivity analysis using HalfCauchy, validating this choice

2. **Tighter Hyperparameter Means:**
   - **Solution:** `μα ~ N(0, 10⁵)`, `μβ ~ N(0, 10⁵)` (variance = 100,000)
   - **Your code:** `μa ~ N(0, 10²)`, `μb ~ N(0, 10²)` (variance = 100)
   - **Reasoning:**
     - **Practical consideration:** Variance of 100,000 is so large it's essentially flat
     - **Your choice:** Variance of 100 is still very diffuse (95% CI: ±20 on log-odds scale)
     - **Impact:** Both are "noninformative" in practice - your results match solution closely (μα: -0.162 vs -0.145, μβ: -0.616 vs -0.633)
   - **Justification:** The results are nearly identical, suggesting both are effectively noninformative

3. **Non-Centered Parameterization:**
   - **Solution:** Uses centered parameterization (directly samples αⱼ, βⱼ)
   - **Your code:** Uses non-centered parameterization: `αⱼ = μₐ + σₐ * zₐⱼ`, where `zₐⱼ ~ N(0,1)`
   - **Reasoning:**
     - **Sampling efficiency:** Non-centered parameterization improves MCMC mixing for hierarchical models
     - **Funnel geometry:** Avoids the "funnel" problem where centered parameterization can have poor geometry
     - **PyMC best practice:** PyMC documentation recommends non-centered for hierarchical models
     - **Solution PDF acknowledges this:** Page 17 mentions non-centered parameterization as a solution to mixing problems
   - **Justification:** This is a technical improvement that doesn't change the model, just how it's sampled

4. **Village Identification (Largest Slope):**
   - **Solution:** Emphasizes Village 45 (most protective, β = -0.801)
   - **Your code:** Identifies Village 40 (largest numerically, β = -0.499)
   - **Reasoning:**
     - **Technical interpretation:** "Largest slope" could mean:
       - Most positive (numerically largest) → Village 40
       - Largest in magnitude (most protective) → Village 45
     - **Your code:** Uses `np.argmax(slope_means)` which finds numerically largest
     - **Solution:** Acknowledges both interpretations but emphasizes scientific meaning (most protective)
   - **Issue:** This is an **interpretation choice**, not a methodological error
     - Your code is technically correct for "largest"
     - But misses the scientific interpretation (most protective effect)

---

## SOFTWARE CHOICE: PyMC vs JAGS

### Why PyMC?

1. **Python-native:** 
   - Better integration with pandas, numpy, matplotlib
   - More modern ecosystem (ArviZ for diagnostics)
   - Better for reproducible research workflows

2. **Modern diagnostics:**
   - Built-in PSIS-LOO for model comparison
   - Better traceplot and diagnostic tools
   - Automatic convergence checking

3. **Active development:**
   - PyMC 5.x is actively maintained
   - Better documentation and community support
   - More modern sampling algorithms

4. **Non-centered parameterization:**
   - Easier to implement in PyMC
   - Better default behavior for hierarchical models

### Trade-offs:
- ✅ More modern, better diagnostics, Python-native
- ❌ Different from solution (JAGS), requires learning different syntax

---

## SUMMARY: Intentional Choices vs Mistakes

### ✅ **INTENTIONAL METHODOLOGICAL CHOICES** (Defensible):

1. **HalfCauchy vs Gamma priors** (Problem 3)
   - Modern Bayesian practice
   - Solution PDF validates this choice in sensitivity analysis

2. **Non-centered parameterization** (Problem 3)
   - Better MCMC sampling
   - Solution PDF mentions this as recommended practice

3. **Tighter slope prior** (Problem 1)
   - Uses domain knowledge to prevent absurd values
   - More realistic regularization

4. **Conjugate Bayesian regression** (Problem 2a)
   - Exact results, faster computation
   - Theoretically equivalent to MCMC with flat priors

5. **PyMC vs JAGS**
   - Modern software choice
   - Better diagnostics and ecosystem

### ❌ **MISTAKES/BUGS** (Should be fixed):

1. **Y not standardized** (Problem 2)
   - Solution standardizes Y, your code doesn't
   - This explains the massive RMSE difference
   - **This is a bug, not a choice**

2. **Village interpretation** (Problem 3c)
   - Technically correct but misses scientific meaning
   - Should identify "most protective" (village 45), not just "largest" (village 40)

3. **Prior specifications not matching** (Problem 1)
   - While your priors are reasonable, they don't match the solution
   - Should either match exactly or provide strong justification

---

## RECOMMENDATIONS

### What to Keep (Good Choices):
- ✅ HalfCauchy priors (modern practice)
- ✅ Non-centered parameterization (better sampling)
- ✅ PyMC (modern software)
- ✅ Conjugate analysis where appropriate (efficiency)

### What to Fix (Mistakes):
- ❌ **URGENT:** Standardize Y in UScrime problem (or clearly document why not)
- ❌ **IMPORTANT:** Match prior specifications exactly, or provide strong justification
- ❌ **IMPORTANT:** Fix village identification to emphasize scientific meaning
- ⚠️ **RECOMMENDED:** Add comments explaining methodological choices that differ from solution

### What to Add (Missing):
- ⚠️ Multiple starting points checks (as noted in ISSUES_REPORT.md)
- ⚠️ Traceplots for all models
- ⚠️ Clear documentation of choices that differ from solution

---

## PHILOSOPHICAL REFLECTION

The code shows **good understanding of modern Bayesian practice** but **insufficient attention to matching the solution requirements**. The methodological choices (HalfCauchy, non-centered, tighter priors) are often **better** than the solution, but the assignment likely requires **matching the solution exactly**.

**Key Lesson:** In homework assignments, even if your approach is "better," you should:
1. Match the solution exactly, OR
2. Provide clear justification for differences, AND
3. Show that results are equivalent/robust

The fact that Problem 3 results match closely despite different priors suggests the methodology is sound - the issue is **documentation and matching requirements**, not fundamental understanding.

---

*End of Methodological Choices Explanation*

