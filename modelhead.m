%INITIALIZE
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
    ['Original Price +2% to 5%'  ], ['Original Price +5% or more']}
   
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

%initial option value
spot_price = strike_p;
[call_0,put_0]=blsprice(spot_price,strike_p,rate,time,vol,yield) 
%                           ^This 
%assumes that all options are on-the-money which is clearly pretty silly
%The parameters for this are give in the excel simulation and we would
%definitely want to try playing with these parameters.  Maybe a normally
%distributed strike price makes more sense but I'm not sure.

%Event: This is a uniformly distributed draw, but this should be correlated to the histo_dist% 
k=randi(size(new_price,2));
bin_names(k)
u_prof=sum(wagers)-adjodds(k)*wagers(k);

%option value after event 
[call,put]=blsprice(new_price(k),strike_p,rate,time,vol,yield)

x=100*linspace(0,50,51);  % Number of options in bins of 100

%%% Call Profits %%%
c_prof=x*(call-call_0)-1.25*x/100; %Assumes $1.25 per contract (100 options)

%%% Put Profits %%%
p_prof=x*(put-put_0)-1.25*x/100;

%%% Total Profits %%%
tot_prof=u_prof+c_prof+p_prof %This is a 1x51 vector with each column coreesponting to the same number of calls and puts.
%Obviously this might not be optimal so the next level of complexity would be to go to two dimensions