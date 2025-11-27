#
rm(list=ls(all=TRUE))
projpath="/Users/jiankang/University of Michigan Dropbox/Jian Kang/Umich/Biostat682/Fall2024/Code"
#Birth Rate Example (Hoff, 2009)
#Data
n_1 = 111
sum_y_1 = 217
n_2 = 44
sum_y_2 = 66
#Prior 
alpha = 2
beta = 1

plot_poisson_mean_density = function(n_1,sum_y_1,
                                     n_2,sum_y_2,
                                     alpha,beta,
                                     xlim=c(0,6),ylim=c(0,3)){
  
  theta = seq(xlim[1],xlim[2],by=0.001)  
  prior_density = dgamma(theta,alpha,beta)
  posterior_density_1 = dgamma(theta,alpha+sum_y_1,beta+n_1)
  posterior_density_2 = dgamma(theta,alpha+sum_y_2,beta+n_2)
  
  par(mai=c(1,1,1,1)*0.7,mgp=c(2,0.3,0),las=1)
  if(is.null(ylim)){
    ylim=c(0,max(prior_density,posterior_density_1,posterior_density_2))
  }
  plot(0,0,type="n",xlim=xlim,ylim=ylim,
       xlab=expression(theta),ylab="Density",main="Posterior Distribution")
  lines(theta,prior_density,lwd=3)
  lines(theta,posterior_density_1,col="red",lwd=3)
  lines(theta,posterior_density_2,col="blue",lwd=3)
  
  legend("topright",legend=c(expression(G(alpha,beta)),
                             expression(G(alpha + sum(y[1~j],j==1,n[1]),beta+n[1])),
                             expression(G(alpha + sum(y[2~j],j==1,n[2]),beta+n[2]))),lwd=3,lty=1,
         col=c("black","red","blue"))
}


plot_poisson_predictive_density = function(n_1,sum_y_1,n_2,sum_y_2,alpha,beta,xlim=c(0,12),ylim=c(0,3)){
  
  tilde_y = seq(xlim[1],xlim[2],by=1)  
  
  predictive_density_1 = dnbinom(tilde_y,alpha+sum_y_1,1/(1+1/(beta+n_1)))
  predictive_density_2 = dnbinom(tilde_y,alpha+sum_y_2,1/(1+1/(beta+n_2)))
  
  par(mai=c(1,1,1,1)*0.7,mgp=c(2,0.3,0),las=1)
  if(is.null(ylim)){
    ylim=c(0,max(predictive_density_1,predictive_density_2))
  }
  pmf = rbind(predictive_density_1,predictive_density_2)
  colnames(pmf) = 0:(length(tilde_y)-1)
  barplot(pmf,legend.text=c(expression(NegBin(alpha + sum(y[1~j],j==1,n[1]),beta+n[1])),
                            expression(NegBin(alpha + sum(y[2~j],j==1,n[2]),beta+n[2]))),
          col=c("red","blue"),beside=TRUE,
          xlab=expression(tilde(y)),ylab="Probability",main="Predictive Distribution")
  box()
}

pdf(file=file.path(projpath,"posterior_birth_rates.pdf"),height=4,width=10)
plot_poisson_mean_density(n_1,sum_y_1,n_2,sum_y_2,alpha,beta,xlim=c(0,6))
dev.off()

pdf(file=file.path(projpath,"predictive_birth_rates.pdf"),height=4,width=10)
plot_poisson_predictive_density(n_1,sum_y_1,n_2,sum_y_2,alpha,beta)
dev.off()


#Compute the posterior probabiltiy of theta[1] > theta[2]
integrand = function(x){
  pgamma(x,shape=alpha+sum_y_2,rate=beta+n_2)*dgamma(x,shape=alpha+sum_y_1,rate=beta+n_1)
}
post_prob_1 = integrate(integrand,0,Inf)$value

#Compute the posterior probablity of tilde(y)[1] > tilde(y)[2]
tilde_y = 1:1000
pred_prob_gt = sum(pnbinom(tilde_y-1,alpha+sum_y_2,1/(1+1/(beta+n_2)))*dnbinom(tilde_y,alpha+sum_y_1,1/(1+1/(beta+n_1))))

#Compute the posterior probablity of tilde(y)[1] = tilde(y)[2]
tilde_y = 0:1000
pred_prob_eq = sum(dnbinom(tilde_y,alpha+sum_y_2,1/(1+1/(beta+n_2)))*dnbinom(tilde_y,alpha+sum_y_1,1/(1+1/(beta+n_1))))
