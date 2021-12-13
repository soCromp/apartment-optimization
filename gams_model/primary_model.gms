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

********************** Model **********************

free variable dis "dissatisfication";

Binary Variable
        b(r,a) "b(r,a)=1 if assign resident r to apartment i"
        d(r,m) "d(r, m)=1 if resident r choose method m";

equations
        obj, 
        bound_1(r) "each apartment gets at most one resident", 
        bound_2(a) "each resident gets at most one apartment", 
        bound_3 "count the number of residents assigned apartments";

obj..
dis =e= sum((r, a), b(r,a) * sum(headr, rank(r, headr)*(apt_data(a, headr)-res_data(r, headr))))
        + sum((r,a), b(r,a) * rank(r,'com_t')*(sum(m $ r_method(r,m), apt_com_t_nm(a,m)) -res_data(r,'com_t')));
* second line is dissatisfaction with commute, first line is dissatisfaction with everything else
        
bound_1(r)..
sum(a, b(r,a)) =l= 1;

bound_2(a)..
sum(r, b(r,a)) =l= 1;

bound_3..
sum((r,a), b(r,a)) =e= pairs;

model primary_model /all/;
solve primary_model using mip minimizing dis;
