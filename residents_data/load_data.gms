set labels(*);
set j /1*30/;

parameter data(j,labels);

$gdxin small_data_set.gdx
$load labels
$load data
$gdxin

display data;