set large /1*100/;
set small(large);
set medium(large);

small(large) = yes;
small(large) $ (ord(large)>30) = no;

medium(large) = yes;
medium(large) $ (ord(large)>60) = no;

set labels /'nbed', 'nbath', 'budget', 'com_m', 'com_t'/;


parameter large_set(large, labels);

****************************************************
parameter rank_1(large, labels), rank(large, labels);

alias(labels, l);

parameter normalize(large);

loop(large,
rank_1(large, labels) = uniform(0,1);
normalize(large) = sum(labels, rank_1(large, labels));
);
rank(large, labels) = rank_1(large, labels)/normalize(large);

****************************************************


parameter beds;
loop(large,
    beds = normal(2,1);
    if(beds>0,
        large_set(large, 'nbed') = ceil(beds);
    else
        large_set(large, 'nbed') = 0;
    );
);

large_set(large, 'nbath') $ (large_set(large, 'nbed')>0)= floor(uniform(1, large_set(large, 'nbed')));
large_set(large, 'nbath') $ (large_set(large, 'nbed')=0) = 1;

parameter budgets;
loop(large,
    budgets = normal(1200,200);
    large_set(large, 'budget') = budgets $ (budgets>=500) + 500 $ (budgets<500);
);

*parameter com_m(large);
*com_m(large) = floor(uniform(1,4))

*$onText

large_set(large, 'com_m')  = floor(uniform(1,4));
large_set(large, 'com_m')  $ (large_set(large, 'com_m')=4) = 3

set slot /t1*t5/;
parameter time_slot(slot)
/t1 5,
 t2 10,
 t3 15,
 t4 20,
 t5 25/;

parameters com_time_prim, com_time;
loop(large,
com_time_prim = floor(normal(15, 5));
com_time $ (com_time_prim<time_slot('t1')) = 1;
com_time $ (com_time_prim>=time_slot('t1') and com_time_prim<time_slot('t2')) = 2;
com_time $ (com_time_prim>=time_slot('t2') and com_time_prim<time_slot('t3')) = 3;
com_time $ (com_time_prim>=time_slot('t3') and com_time_prim<time_slot('t4')) = 4;
com_time $ (com_time_prim>=time_slot('t5') and com_time_prim<time_slot('t5')) = 5;
com_time $ (com_time_prim>=time_slot('t5')) = 6;
large_set(large, 'com_t') = com_time;
)
*$offText


parameter small_set(large, labels);
small_set(large, labels) $ (small(large)) = large_set(large, labels);

parameter medium_set(large, labels);
medium_set(large, labels) $ (medium(large)) = large_set(large, labels);

display large_set, small_set, medium_set, rank, normalize;

execute_unload 'small_data' labels=headr, small = index, small_set=data;
execute_unload 'medium_data' labels=headr, medium = index, medium_set=data;
execute_unload 'large_data' labels=headr, large = index, large_set=data;
execute_unload 'rank' labels=headr, large=index, rank=data;

