#Biostat 682: Applied Bayesian Inference
#Lecture 13: Bayesian Neural Networks
rm(list=ls(all=TRUE))
library(R2jags)
projpath = "/Users/jiankang/University of Michigan Dropbox/Jian Kang/Umich/Biostat682/Fall2025/Colab/"

library(splines)
library(MASS)

help(mcycle)
#Preprocessing data
Y = mcycle$accel
X = mcycle$times

Y <- (Y-mean(Y))/sd(Y)
X <- X/max(X)
n = length(Y)


#Plot the data
par(mfcol=c(1,1))
plot(X,Y,xlab="time",ylab="Acceleration",cex.lab=1.5,cex.axis=1.5)

#split data into train and test
set.seed(1000)
n_train = 100
idx_train = sample(1:n,n_train)
idx_test = setdiff(1:n, idx_train)
X_train = X[idx_train]
Y_train = Y[idx_train]

X_test = X[idx_test]
Y_test = Y[idx_test]

par(mfcol=c(1,2))
plot(X_train,Y_train,col="blue",xlab="time",
     ylab="Acceleration",cex.lab=1.5,cex.axis=1.5,
     ylim=c(-3,3),main="Training Data")

plot(X_test,Y_test,col="red",xlab="time",
     ylab="Acceleration",cex.lab=1.5,cex.axis=1.5,
     ylim=c(-3,3),main="Test Data")


#----------------------------- Bayesian neural networks -----------------------------

Bayes_1L_NN = function(Y_train,X_train,X_test,q=3L,
                       n.iter=9000,n.burnin=1000){
  JAGS.NN.model = function() {
    # Likelihood
    for (i in 1:n_train) {
      Y_train[i] ~ dnorm(f[i],tau2)
      f[i] <-  beta00 + inprod(Z_train[i,],beta01)
      for(l in 1:q){
        logit(Z_train[i,l]) <-  beta10[l] + inprod(X_train[i,],beta11[l,])
      }
      # for(k in 1:K){
      #   logit(W_train[i,k]) <- beta20[k] + inprod(X_train[i,],beta21[k,])
      # }
    }
    #prior
    tau2 ~ dgamma(0.001,0.001)
    beta00 ~ dnorm(0,0.0001)

    for(l in 1:q){
      beta01[l] ~ dnorm(0,0.0001)
    }

    for(l in 1:q){
      for(j in 1:p){
        beta11[l,j] ~ dnorm(0,0.0001)
      }
      beta10[l] ~ dnorm(0,0.0001)
    }

    #prediction
    for (i in 1:n_pred) {
      Y_pred[i] ~ dnorm(f_pred[i],tau2)
      f_pred[i] <-  beta00 + inprod(Z_train_pred[i,],beta01)
      for(l in 1:q){
        logit(Z_train_pred[i,l]) <-  beta10[l] + inprod(X_test[i,],beta11[l,])
      }
    }
  }
  JAGS.NN.data = list(Y_train=Y_train,
                      X_train=X_train,
                      X_test=X_test,
                      q = q,
                      n_train = as.integer(nrow(X_train)),
                      n_pred = as.integer(nrow(X_test)),
                      p = as.integer(ncol(X_train)))
  #set parameters to simulate
  para.JAGS = c("Y_pred")
  fit.JAGS = jags(data=JAGS.NN.data,inits=NULL,
                  parameters.to.save = para.JAGS,
                  n.chains=1,n.iter=n.iter,n.burnin=n.burnin,
                  model.file=JAGS.NN.model)
  mcmc_fit = as.mcmc(fit.JAGS)
  Y_pred_sample = mcmc_fit[[1]][,paste("Y_pred[",1:nrow(X_test),"]",sep="")]
  Y_pred=apply(Y_pred_sample,2,mean)
  Y_pred_CI = apply(Y_pred_sample,2,quantile,prob=c(0.025,0.975))
  return(list(Y_pred=Y_pred,
              Y_pred_lcl = Y_pred_CI[1,],
              Y_pred_ucl = Y_pred_CI[2,],
              DIC = fit.JAGS$BUGSoutput$DIC,
              pD = fit.JAGS$BUGSoutput$pD,
              fit.JAGS=fit.JAGS))
}

plot_res = function(res,main=""){
  plot(X_test,res$Y_pred_ucl,type="l",
       ylim=c(-3,3),xlab="time",ylab="Acceleration",
       cex.lab=1.5,cex.axis=1.5,main=main)
  lines(X_test,res$Y_pred_lcl)
  lines(X_test,res$Y_pred,col="blue")
  points(X_test, Y_test,col="red")
}


summary_res = function(res,Y_test){
  RPMSE = sqrt(mean((res$Y_pred-Y_test)^2))
  coverage = mean((Y_test>res$Y_pred_lcl)&(Y_test<res$Y_pred_ucl))
  return(c(RPMSE=RPMSE,coverage=coverage))
}

res_q5 = Bayes_1L_NN(Y_train=Y_train,
                     X_train=cbind(X_train),
                     X_test=cbind(X_test),q = 5L)

res_q10 = Bayes_1L_NN(Y_train=Y_train,
                     X_train=cbind(X_train),
                     X_test=cbind(X_test),q = 10L)

res_q25 = Bayes_1L_NN(Y_train=Y_train,
                      X_train=cbind(X_train),
                      X_test=cbind(X_test),q = 25L)

res_q30 = Bayes_1L_NN(Y_train=Y_train,
                      X_train=cbind(X_train),
                      X_test=cbind(X_test),q = 30L)


par(mfcol=c(2,2))
plot_res(res_q5,main=sprintf("K = 5 DIC = %.2f",res_q5$DIC))
plot_res(res_q10,main=sprintf("K = 10 DIC = %.2f",res_q10$DIC))
plot_res(res_q25,main=sprintf("K = 25 DIC = %.2f",res_q25$DIC))
plot_res(res_q30,main=sprintf("K = 30 DIC = %.2f",res_q30$DIC))

tab = NULL
#tab = rbind(tab,summary_res(res_q3,Y_test))
tab = rbind(tab,summary_res(res_q5,Y_test))
tab = rbind(tab,summary_res(res_q10,Y_test))
tab = rbind(tab,summary_res(res_q25,Y_test))
tab = rbind(tab,summary_res(res_q30,Y_test))
rownames(tab) = paste("K = ", c(5,10,25,30), sep="")
print(tab)

save(tab,res_q5,res_q10,res_q25,res_q30,file=file.path(projpath,"NN_res.RData"))

#GP modeling

GP_fit = function(Y_train,X_train,X_test,rho = 0.5,
                  n.iter=9000,n.burnin=1000){

  #compute Sigma
  all_X = rbind(X_train,X_test)
  grids = expand.grid(all_X,all_X)
  grids_dist = abs(grids[,1] - grids[,2])^1.99
  q_dist = quantile(grids_dist[grids_dist!=0],prob=0.5)
  nu = -log(rho)/q_dist
  Sigma=matrix(exp(-nu*grids_dist),nrow=length(all_X))
  diag(Sigma) <- diag(Sigma) + 0.001

  #define the model
  JAGS_GP_model = function() {
    # Likelihood
    for (i in 1:n_train) {
      Y_train[i]    ~ dnorm(mean[i], tau2)
    }

    # Priors
    mean ~ dmnorm(zeros,Omega)
    Omega <- inverse(Sigma)
    tau2 ~ dgamma(0.001, 0.001)

    # Prediction
    for(i in 1:n_pred){
      mean_pred[i] <- mean[n_train+i]
      Y_pred[i] ~ dnorm(mean_pred[i], tau2)
    }
  }

  fit.JAGS = jags(
    data = list(Y_train = Y_train,
                n_train = length(Y_train),
                n_pred  = nrow(X_test),
                Sigma=Sigma,zeros=rep(0,length=nrow(X_train)+nrow(X_test))),
    parameters.to.save = c("Y_pred"),
    n.chains = 1,
    n.iter = n.iter,
    n.burnin = n.burnin,
    model.file = JAGS_GP_model
  )

  mcmc_fit = as.mcmc(fit.JAGS)
  Y_pred_sample = mcmc_fit[[1]][,paste("Y_pred[",1:nrow(X_test),"]",sep="")]
  Y_pred=apply(Y_pred_sample,2,mean)
  Y_pred_CI = apply(Y_pred_sample,2,quantile,prob=c(0.025,0.975))
  return(list(Y_pred=Y_pred,
              Y_pred_lcl = Y_pred_CI[1,],
              Y_pred_ucl = Y_pred_CI[2,],
              DIC = fit.JAGS$BUGSoutput$DIC,
              pD = fit.JAGS$BUGSoutput$pD,
              fit.JAGS=fit.JAGS))
}

res_GP_rho_90 = GP_fit(Y_train=Y_train,
                       X_train=cbind(X_train),
                       X_test=cbind(X_test),rho = 0.9)


res_GP_rho_50 = GP_fit(Y_train=Y_train,
                     X_train=cbind(X_train),
                     X_test=cbind(X_test),rho = 0.5)

res_GP_rho_10 = GP_fit(Y_train=Y_train,
                       X_train=cbind(X_train),
                       X_test=cbind(X_test),rho = 0.1)


par(mfcol=c(2,2))
plot_res(res_GP_rho_90,main=sprintf("rho = 0.9 DIC = %.2f",res_GP_rho_90$DIC))
plot_res(res_GP_rho_50,main=sprintf("rho = 0.5 DIC = %.2f",res_GP_rho_50$DIC))
plot_res(res_GP_rho_10,main=sprintf("rho = 0.1 DIC = %.2f",res_GP_rho_10$DIC))

GP_tab = NULL
GP_tab = rbind(GP_tab,summary_res(res_GP_rho_90,Y_test))
GP_tab = rbind(GP_tab,summary_res(res_GP_rho_50,Y_test))
GP_tab = rbind(GP_tab,summary_res(res_GP_rho_10,Y_test))
rownames(GP_tab) = paste("rho = ", c(0.9,0.5,0.1), sep="")
print(GP_tab)

save(GP_tab,res_GP_rho_90,res_GP_rho_50,res_GP_rho_10,file=file.path(projpath,"GP_res.RData"))


