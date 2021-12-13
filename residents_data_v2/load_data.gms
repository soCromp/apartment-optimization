set labels(*);
set j /1*30/;

parameter data(j,labels);

$gdxin small_data.gdx
$load labels
$load data
$gdxin

display data;