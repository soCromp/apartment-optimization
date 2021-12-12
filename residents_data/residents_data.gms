set large /1*100/;
set small(large);
set medium(large);

small(large) = yes;
small(large) $ (ord(large)>30) = no;

medium(large) = yes;
medium(large) $ (ord(large)>60) = no;

set labels /'nbed', 'nbath', 'budget', 'com_m', 'com_t'/;

parameter large_set(large, labels);

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

large_set(large, 'com_m') = floor(uniform(1,4));
large_set(large, 'com_m') $ (large_set(large, 'com_m')=4) = 3;

parameters com_time_prim, com_time;
loop(large,
com_time_prim = floor(normal(15, 5));
com_time $ (com_time_prim<5) = 1;
com_time $ (com_time_prim>=5 and com_time_prim<10) = 2;
com_time $ (com_time_prim>=10 and com_time_prim<15) = 3;
com_time $ (com_time_prim>=15 and com_time_prim<20) = 4;
com_time $ (com_time_prim>=20 and com_time_prim<25) = 5;
com_time $ (com_time_prim>=25) = 6;
large_set(large, 'com_t') = com_time;
)

parameter small_set(large, labels);
small_set(large, labels) $ (small(large)) = large_set(large, labels);

parameter medium_set(large, labels);
medium_set(large, labels) $ (medium(large)) = large_set(large, labels);

display large_set, small_set, medium_set;

execute_unload 'small_data' labels=headr, small = index, small_set=data;
execute_unload 'medium_data' labels=headr, medium = index, medium_set=data;
execute_unload 'large_data' labels=headr, large = index, large_set=data;

