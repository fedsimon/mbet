format longG
%% INITIALIZE
spot_price  = 23;
strike_p    = 23;
rate        = .01;
time        = .04;       %2 weeks
vol         = .35;
yield       = .025*.04;  %2 weeks * 2.5% per year

%PROPRIETARY PROBABILITIES
histo_dist  = [.017, .066, .113, .287, .299, .131, .072, .0141];
retrn       = [-.071, -.029, -.014, -.005, .004, .014, .029, .077];    
new_price   = spot_price*(1+retrn);
fairodds    = 1./histo_dist;
adjodds     = 1+(fairodds-1)*.7;
                                                        
bin_names= ...
   {['Original Price -5% or more'], ['Original Price -2% to -5%'], ...
    ['Original Price -1% to -2%' ], ['Original Price -0% to -1%'], ...
    ['Original Price +0% to 1%'  ], ['Original Price +1% to 2%' ], ...
    ['Original Price +2% to 5%'  ], ['Original Price +5% or more']};
   
fix     = 0;%change this value from zero to use a fixed total
total   = 100000;
max_bet = 10000;

% Here I use a simple uniform distribution and generate integers between $1
% and $10000 as wagers 
if fix == 0     
    wagers=randi(max_bet,1,size(histo_dist,2));
else
    wagers=randi(max_bet,1,size(histo_dist,2));
    wagers=total*wagers/sum(wagers);
end
figure();
barh(wagers); 
title('Wagers per Bin');
set(gca,'YTickLabel',bin_names);

%% SELECT THE WINNING BIN
aPermuation = randperm(length(bin_names));      %PERMUTE RANGE(1,8)
winningBin  = aPermuation(1);                   %SELECT FIRST OF PERMUTATION
bin_names(winningBin)                           %PRINT WINNING BET
newSpot     = spot_price*(1+retrn(winningBin));
betsOutflow = wagers(winningBin)*adjodds(winningBin);
betsInflow  = sum(wagers(1:end ~= winningBin));
rawnet = betsInflow - betsOutflow;

figure(); 
bar([betsOutflow betsInflow rawnet]);
title({'Bet Only Cash Flow'});
set(gca,'XTickLabel',{'BetsOutflow', 'BetsInflow', 'Net'})

%% ANALYSIS FOR OPTION STRATEGY
lossperbin = wagers.*adjodds;

figure();
barh(lossperbin);
title({'Potential Loss Per Bin (without options)'});
set(gca,'YTickLabel',bin_names);

lossIfBear = sum(lossperbin(1:end/2));
lossIfBull = sum(lossperbin(end/2:end));
maxloss    = max(lossIfBear,lossIfBull);

%% CALCULATE BUY PRICES
[call_buyprice,put_buyprice]=blsprice(spot_price,strike_p,rate,time,vol,yield);

%CALCULATE NUMBER OF OPTIONS
%FOR HEDGING, YOU NEED 1 OPTION FOR EVERY UNDERLYING. IN THIS CASE WE NEED
%1 OPTION FOR EVERY 
% MAX( (bearMoveOdds_v*bearWagers_v), (bullMoveOdds.*bullWagers_v) )
maxbearloss = max(lossperbin(1:end/2))
maxbullloss = max(lossperbin(end/2:end))
maxnumopts  = max(maxbearloss,maxbullloss)/100;
    
%% BUY OPTIONS (STRADDLE)
%BUY CALLS (CALL=BEAR)
%numCalls        = maxbearloss/100
numCalls         = maxnumopts;      %LESS DEPENDENT ON PROPRIETARY PROBABILITIES THAN ABOVE
callExpenditure = numCalls * call_buyprice; 
%BUY PUTS (PUT=BULL)
%numPuts         = maxbullloss/100
numPuts         = maxnumopts;       %LESS DEPENDENT ON PROPRIETARY PROBABILITIES THAN ABOVE
putExpenditure  = numPuts * put_buyprice;

%% SELL OPTIONS
[call_sellprice,put_sellprice]=blsprice(newSpot,strike_p,rate,time,vol,yield);
%SELL CALLS
callRevenue     = numCalls * call_sellprice;
%SELL PUTS
putRevenue      = numPuts * put_sellprice;

%OPTION PROFIT
optionExpenditure = callExpenditure + putExpenditure;
optionRevenue     = callRevenue + putRevenue;
optionProfit      = optionRevenue - optionExpenditure;

%%
totalProfit = betsInflow + optionRevenue - betsOutflow - optionExpenditure;
figure;bar([betsInflow, optionRevenue, betsOutflow, optionExpenditure, totalProfit])
title('Cash Flow Distribution');
set(gca,'XTickLabel',{'BetsInflow', 'OptionRevenue', 'BetsOutflow', 'OptionExpenditure', 'Net'})
