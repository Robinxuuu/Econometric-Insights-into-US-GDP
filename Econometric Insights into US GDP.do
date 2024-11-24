clear all
cls

import excel "/Users/xushixiong/Desktop/Determinants of GDP in US.xls", sheet("Determinants of GDP in the US") firstrow clear

// I. Decleration of time series data
gen date = (1980) + _n-1
tsset date

// II. Descriptive Statistics
summarize gdpr oil rimp

// 1. Stationary test
// (1) GDP
// ① Plot the graph
tsline gdpr // seems stationary, around a constant
// ② Check number of lags
varsoc gdpr // SBIC: 1 lags
varsoc l.gdpr // SBIC: 1 lags
// ③ Dickey-Fuller Test for stationarity
dfuller gdpr, drift lags(1) // test statistics=-3.318, p-value = 0.0012, gdpr: stationary at 1% significance level
dfuller l.gdpr, drift lags(1) // test statistics=-3.252, p-value = 0.0014, l.gdpr: stationary at 1% significance level

// (2) Oil Price
// ① Plot the graph
tsline oil // seems non-stationary, have a trend
tsline d.oil // seems stationary, around a constant
// ② Check number of lags
varsoc oil // SBIC: 1 lags
varsoc d.oil // // SBIC: 0 lags
// ③ Dickey-Fuller Test for stationarity
dfuller oil, trend lags(1) // test statistics=-2.495, p-value = 0.3303, oil: non-stationary at 10% significance level
dfuller d.oil, drift lags(0) // test statistics=-4.980, p-value = 0.0000, d.oil is stationary at 1% significance level, therefore 'oil' is I(1)

// (3)Import of Goods and Services
// ① Plot the graph
tsline rimp //seems non-stationary, with a trend
tsline d.rimp // seems stationary, around a constant
// ② Check number of lags
varsoc rimp // 1 lags
varsoc d.rimp // 0 lags
// ③ Dickey-Fuller Test for stationarity
dfuller rimp, trend lags(1) // test statistics=-3.298, p-value = 0.0666, rimp: non-stationary at 5% significance level
dfuller d.rimp, lags(0) // test statistics=-6.886, p-value = 0.0000, d.rimp: stationary at 1% significance level, therefore 'import of goods and service' is I(1)

// III. Methodology

// 1. Check for cointegration (spurious regression)
gen doil = d.oil
gen dimp = d.rimp

// This is crucial when dealing with non-stationary data that could be integrated of order one, I(1).
// (1) gdpr & l.gdpr
reg gdpr l.gdpr, noconstant
predict ehat1, residual  
dfuller ehat1, noconstant // test statistics=-7.005, CV(1%)=-3.39, reject H0: no cointegration 
// (2) gdpr & d.oil
reg gdpr doil, noconstant
predict ehat2, residual
dfuller ehat2, noconstant // test statistics=-1.937, CV(1%)=-3.39, fail to reject H0: no cointegration
// (3) gdpr & d.imp
reg gdpr dimp, noconstant
predict ehat3, residual
dfuller ehat3, noconstant // test statistics=-1.813, CV(1%)=-3.39, fail to reject H0: no cointegration
// The lag of GDP growth is cointegrated with GDP growth rate. Thus, an ARDL error correction model will be adopted

// 2. ARDL EC model
ardl gdpr doil dimp, lags(1,0,0) ec //'imp' has more significant impact to GDP on the short run, while 'oil' has more significant impact to GDP on the long run

// 3. Check for Heterosckedasticity 
// (1) plot the residuals
predict ehath, residuals
graph twoway (scatter ehath date)(lfit ehath date) // the variances seems constant 
// (2) Breusch-Pagan/Cook-Weisberg test for heteroskedasticity
estat hettest // p-value = 0.4462, cannot reject H0: no heteroskedasticity

// 4. Check for Serial Correlation: Breusch–Godfrey Lagrange Multiplier test, H0: there is no serial correlation of any order up to p
estat bgodfrey // p-value = 0.2484, cannot reject H0: no serial correlation

// 5. Check for Granger Causality of oil price
test doil // p-value=0.0095, first difference of oil price is Granger causing GDP growth rate

// 6. Forecast for GDP growth rate in 2016-2018
// (1) Add the real GDP growth rate
tsappend, add(3)
replace gdpr = 1.6675 in 37
replace gdpr = 2.2419 in 38
replace gdpr = 2.9454 in 39

// (1) Using ARDL EC model
// ① Predicted the GDP growth rate by model
predict yhat1

// ② Adding real oil price and import goods and services, then calculate d.oil and d.imp
replace oil = 49.99 in 37
replace doil = oil[37] - oil[36] in 37
replace oil = 61.94 in 38
replace doil = oil[38] - oil[37] in 38
replace oil = 75.73 in 39
replace doil = oil[39] - oil[38] in 39
replace rimp = 14.64998 in 37
replace dimp = rimp[37] - rimp[36] in 37
replace rimp = 15.0512828 in 38
replace dimp = rimp[38] - rimp[37] in 38
replace rimp = 15.2493901 in 39
replace dimp = rimp[39] - rimp[38] in 39

// ③Forecast GDP growth rate in 2016 - 2018
scalar yhat12016 = 1.732615 + (-0.7588342)*gdpr[36]+ (-0.0723975)*doil[37]+ (2.466272)*dimp[37]
scalar yhat12017 = 1.732615 + (-0.7588342)*yhat12016+ (-0.0723975)*doil[38]+ (2.466272)*dimp[38]
scalar yhat12018 = 1.732615 + (-0.7588342)*yhat12017+ (-0.0723975)*doil[39]+ (2.466272)*dimp[39]
scalar list yhat12016 yhat12017 yhat12018
replace yhat1 = yhat12016 in 37
replace yhat1 = yhat12017 in 38
replace yhat1 = yhat12018 in 39
// tsline gdpr yhat1, title(ARDL EC Model) saving(ardlec,replace)
label var yhat1 "ARDL EC Model"

// (2) Using ARDL model
ardl gdpr doil dimp, lags(1,0,0)
// ① Predicted the GDP growth rate by model
predict yhat2

// ② Adding real oil price and import goods and services, then calculate d.oil and d.imp
replace oil = 49.99 in 37
replace doil = oil[37] - oil[36] in 37
replace oil = 61.94 in 38
replace doil = oil[38] - oil[37] in 38
replace oil = 75.73 in 39
replace doil = oil[39] - oil[38] in 39
replace rimp = 14.64998 in 37
replace dimp = rimp[37] - rimp[36] in 37
replace rimp = 15.0512828 in 38
replace dimp = rimp[38] - rimp[37] in 38
replace rimp = 15.2493901 in 39
replace dimp = rimp[39] - rimp[38] in 39

// ③Forecast GDP growth rate in 2016 - 2018
scalar yhat22016 = 1.732615 + 0.2411658*gdpr[36]+ (-0.0549377)*doil[37]+ 1.871492*dimp[37]
scalar yhat22017 = 1.732615 + 0.2411658*yhat22016+ (-0.0549377)*doil[38]+ 1.871492*dimp[38]
scalar yhat22018 = 1.732615 + 0.2411658*yhat22017+ (-0.0549377)*doil[39]+ 1.871492*dimp[39]
scalar list yhat22016 yhat22017 yhat22018
replace yhat2 = yhat22016 in 37
replace yhat2 = yhat22017 in 38
replace yhat2 = yhat22018 in 39
label var yhat2 "ARDL Model"
tsline gdpr yhat1 yhat2, tline(2016)






