$onText
model and data description

residence data:
1. desired nbed, nbath, budget, com_m, com_t
2. nbed = 0 if the resident requires a studio

details:
1. com_t is an integer between 1-5, where 1-> t<5, 2-> 5<=t<10, ... 5-> t>25;
2. com_m is an integer between 1-3, where 1-> drive, 2-> walk, 3-> bike;
3. budget generated by normal distribution, mean=1200, delta=200;
4. extracted from gdx files: small_data, medium_data, large_data;
5. headr: /'nbed', 'nbath', 'budget', 'com_m', 'com_t'/
6. data: data(small/medium/large, headr);
7. small=30, medium=60, large=100;
8. need to figure out ranking -- currently a rand number form uniform(0,1) assigned to each label;

apartments data:
1. should have the same headr;
2. about commute methods: m1 for driving, m2 for walking, m3 for biking.

$offText

********************** Read in data **********************

set headr(*);
set r /1*30/;
alias(r2, r);
set a /a1*a63/;

parameter pairs;
pairs = min(card(r), card(a));

parameter res_data(r,headr);
parameter rank(r, headr);

$gdxin small_data.gdx
$load headr
$load res_data=data
$gdxin

$gdxin rank.gdx
$load rank=data
$gdxin

display res_data, rank;

$call csv2gdx apartments_new.csv id=Data autoRow=a values=1..lastCol useHeader=y

set apt_headr(*);
parameter apt_data(a, headr);

$gdxin apartments_new.gdx
$load apt_headr=Dim2
$load apt_data=Data
$gdxin

set m "m1:drive, m2:walk, m3: drive" /m1*m3/;

parameter apt_com_t(a, m);

$gdxin apartments_new.gdx
$load apt_com_t=Data
$gdxin

********************** Format data **********************

set r_method(r,m) "include a (resident i, commute method j) pair in a set only if j is the preferred commute method of i";
r_method(r,m) = no;
r_method(r,m) $ (ord(m)=res_data(r,'com_m')) = yes;

display apt_data, apt_headr, apt_com_t;

parameter apt_com_t_nm(a,m) "binned commute time - put each commute time into 5-minute interval bins";

set slot /t1*t5/;
parameter time_slot(slot)
/t1 5,
 t2 10,
 t3 15,
 t4 20,
 t5 25/;
 
apt_com_t_nm(a,m) $ (apt_com_t(a, m)<time_slot('t1')) = 1;
apt_com_t_nm(a,m) $ (apt_com_t(a, m)>=time_slot('t1') and apt_com_t(a, m)<time_slot('t2')) = 2;
apt_com_t_nm(a,m) $ (apt_com_t(a, m)>=time_slot('t2') and apt_com_t(a, m)<time_slot('t3')) = 3;
apt_com_t_nm(a,m) $ (apt_com_t(a, m)>=time_slot('t3') and apt_com_t(a, m)<time_slot('t4')) = 4;
apt_com_t_nm(a,m) $ (apt_com_t(a, m)>=time_slot('t4') and apt_com_t(a, m)<time_slot('t5')) = 5;
apt_com_t_nm(a,m) $ (apt_com_t(a, m)>time_slot('t5')) = 6;

parameter
abs_diff(r,a,headr) "absolute difference between apartment a and and resident r",
abs_diff_cmt(r,a) "absolute difference of commute time between apartment a and resident r";

abs_diff(r,a,headr) = abs(apt_data(a, headr)-res_data(r, headr));
abs_diff_cmt(r,a) = abs(sum(m $ r_method(r,m), apt_com_t_nm(a,m)) -res_data(r,'com_t'));

********************** Model **********************

scalars
        infty "stand-in for infinity in equations" /1e5/,
        lambda "priority between minimizing average dissatisfaction and max dissatisfaction" /0.5/;

free variables 
        avgdis "total dissatisfication",
        maxdis "dissatisfaction of most dissatisfied resident",
        dis(r) "dissatisfaction of resident r",
        cdis "combined dissatisfaction from average dissatisfaction and the most dissatisfied resident";

positive variables disAON(r) "dissatisfaction all or nothing - equals dis(r) if r is most dissatisfied resident and 0 otherwise";

binary variables
        b(r,a) "b(r,a)=1 if assign resident r to apartment i"
        d(r,m) "d(r, m)=1 if resident r choose method m",
        isMax(r) "is the resident who is most dissatisfied",
        isntMax(r) "isnt the resident who is most dissatisfied",
        worse(r,r2) "only able to be 1 if r is at least as dissatisfied as r2",
        better(r, r2) "must be 1 if r is less dissatisfied (=more satisfied) than r2";

equations
        obj "combine average and max dissatisfaction losses", 
        calcavgdis "average dissatisfaction",
        calcmaxdis "dissatisfaction of most dissatisfied resident",
        calcrdis(r) "calc dissatisfaction of resident r",
        findbetter(r,r2) "determine if r is happer than r2",
        findworse(r, r2) "if r is less happy from r2",
        calcIsntmax(r) "determine if r can potentially be the most dissatisfied resident",
        calcIsmax(r) "determine if r will be selected as most dissatisfied",
        mostdissed "choose only one resident as the most dissatisfied",
        disaon_lolim1(r) "disAON is 0 if r isnt most dissatisfied",
        disaon_lolim2(r) "disAON isnt greater than dis(r)",
        disaon_hilim(r) "disAON is dis(r) if r is most dissatisfied",
* constraints
        bound_1(r) "each apartment gets at most one resident", 
        bound_2(a) "each resident gets at most one apartment", 
        bound_3 "count the number of residents assigned apartments";



calcrdis(r)..
dis(r) =e= sum(a, b(r,a) * sum(headr, rank(r, headr)*abs_diff(r,a,headr)))
        + sum(a, b(r,a) * rank(r,'com_t')*abs_diff_cmt(r,a));
* second line is dissatisfaction with commute, first line is dissatisfaction with everything else

findbetter(r, r2)..
better(r, r2) =g= (dis(r2) - dis(r)) / infty;

findworse(r, r2)..
worse(r, r2) + better(r, r2) =e= 1; 

calcIsntmax(r)..
isntMax(r) =g= 1/card(r) * (-sum(r2, worse(r,r2) ) + card(r));

calcIsmax(r)..
isMax(r) + isntMax(r) =e= 1;

mostdissed..
sum(r, isMax(r)) =e= 1;

disaon_lolim1(r)..
disAON(r) =l= infty * isMax(r);

disaon_lolim2(r)..
0 =l= dis(r) - disAON(r);

disaon_hilim(r)..
dis(r) - disAON(r) =l= infty * (1-isMax(r));
        
bound_1(r)..
sum(a, b(r,a)) =l= 1;

bound_2(a)..
sum(r, b(r,a)) =l= 1;

bound_3..
sum((r,a), b(r,a)) =e= pairs;

calcavgdis..
avgdis =e= (1/card(r)) * sum(r, dis(r));

calcmaxdis..
maxdis =e= sum(r, disAON(r));

obj..
cdis =e= lambda*avgdis + (1-lambda)*maxdis;

model primary_model /all/;
solve primary_model using mip minimizing cdis;
* 2718.487107