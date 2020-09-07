# volatility_regimes
This simple R shiny app (currently undeployed, but fully functional) takes one or more ticker symbols as inputs and returns the portfolio (or stock, in case of an individual stock) cumulative log return, cumulative return square and volatility regime changes. The materials for this webapp came from blog posts by Robert J Frey (of Renaissance Tech fame).

The focus of this webapp is not to undertake a deep and thorough analysis of economic trends, but to undertake a simple and straightforward "quick and dirty" analysis leading to powerful insights on market behavior. 

## Prerequisites
* An IDE for R (RStudio)
* Shiny (R library)

## Deployment
The webapp sources stock price data from the quantmod package which in turn uses yahoo API. This is built in the package and the user does not have to set API keys for access.

## Frontend - shiny app features
This app is updated and new features added whenever possible and old features removed. As of August 2020, these are the offerings.

* Cumulative returns
* Cumulative square returns
* Volatility regimes

## Backend

The first two graphs (cumulative and cumulative square return) are relatively simple to obtain. The second graph (cumulative square return) is used mainly to explore changes in variance over a timeframe. 

To get to the third graph, the first step is to manually fit a series of lines to the cumulative square returns. There are many ways to do this in R (this [link](https://lindeloev.github.io/mcp/articles/packages.html) reviews a lot of the popular breakpoint packages in R), but I use the segmented package because of it's felixibility in choosing the number of breakpoints. 

This package fits multiple regressions with break-points/change-points relationships. What we do is simply supply a regression model (which in this case is the square returns on an integer index), and the package updates it by adding one or more segmented (piece-wise linear) relationships. One benefit of this package is that the user can look at the square return graph and identify the number of breakpoints which gives us great modelling flexibility. The graph below illustrates the regime changes of the S\&P 500 index (ticker symbol: ^GSPC) between 1985 to 2015 with 20 breakpoints. The thick light green line represents original data and the red line the regimes.

![The heavy light green line represents original data and the red line the regimes](C:/Users/Syed Fuad/Desktop/GitHub/volatility_regimes/fig1.png)

The period is represented by the $i^{th}$ segment, $\tau_{i}$ is a distinct regime. The slope of the $i^{th}$ line segment gives us an estimate of the constant variance. If we multiple each variance by 12 and then take the square root, then we have an annualized estimate of the standard deviation, $\hat{s}_{annual}(\tau_{i})=\sqrt{12*\hat{s}_{monthly}(\tau_{i})^{2}}$.

## Methods

The variance, $\sigma^{2}_{r}$, of return can be expressed by the following, where R is the random variable representing return:

![](http://latex.codecogs.com/gif.latex?%5Csigma%5E%7B2%7D_%7Br%7D%3DE[R%5E%7B2%7D]-E[R%5E%7B2%7D])

If we take the maximum likelihood estimate (MLE) for the sample variance, $\hat{s}^{2}_{r}$, and multiply both sides by the sample size, $\textit{n}$, we have:

![](http://latex.codecogs.com/gif.latex?n%5Chat%7Bs%7D%5E%7B2%7D_%7Br%7D%3D%5Csum_%7Bt%3D1%7D%5E%7Bn%7Dr(t)%5E%7B2%7D-%5Cfrac%7B(%5Csum_%7Bt%3D1%7D%5E%7Bn%7Dr(t))%5E%7B2%7D%7D%7Bn%7D)

For most return time series, the term to the left of the minus sign is much larger than the term on the right. This leads to the following approximation:

<p align="center">
![](http://latex.codecogs.com/gif.latex?n%5Chat%7Bs%7D%5E%7B2%7D_%7Br%7D%5Csimeq%5Csum_%7Bt%3D1%7D%5E%7Bn%7Dr(t)%5E%7B2%7D)
</p>

Thus, if we plot the cumulative square returns, then the slope of this line is approximately the variance of those returns. If the return switches from one stable volatility regime to another, then this shift shows as an abrupt change in slope of the cumulative square returns. This is a simple but powerful exploratory data analysis technique. With an EDA we are attempting to gain insights that give us intuition about the data.

## Acknowledgment
* Robert J Frey
* Jonathan Regenstein
* David Harper

